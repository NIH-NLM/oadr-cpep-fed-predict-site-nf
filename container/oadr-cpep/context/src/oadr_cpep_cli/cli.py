#!/usr/bin/env python3
"""oadr-cpep-cli entry point — subcommand dispatch for the federated workflows."""
from __future__ import annotations

import argparse
import glob
import os
import pickle

import numpy as np
import pandas as pd
from sklearn.linear_model import LassoCV, Ridge, Lasso
from sklearn.ensemble import RandomForestRegressor
from sklearn.preprocessing import MinMaxScaler

NON_FEATURES = {"subject_id", "Subject_ID", "study", "Study"}


# ------------------------------------------------------------------ site: select
def select_features(args):
    """Phase 1 (site): LASSO selects features on this site's own data."""
    df = pd.read_csv(args.data)
    if args.target not in df.columns:
        raise SystemExit(f"target column {args.target!r} not in {args.data}")
    feats = [c for c in df.columns if c not in NON_FEATURES and c != args.target]
    X = df[feats].astype(float).values
    y = df[args.target].astype(float).values

    sc = MinMaxScaler().fit(X)                     # scale within this site only
    cv = max(2, min(5, len(y) // 4))
    m = LassoCV(cv=cv, random_state=args.seed, max_iter=50000).fit(sc.transform(X), y)

    out = pd.DataFrame({"feature": feats, "coefficient": m.coef_,
                        "selected": (np.abs(m.coef_) > 1e-8).astype(int)})
    out["site"] = args.site
    out["n_subjects"] = len(y)
    out["alpha"] = float(m.alpha_)
    path = args.out or f"{args.site}_selected_features.csv"
    out.to_csv(path, index=False)
    kept = [f for f, c in zip(feats, m.coef_) if abs(c) > 1e-8]
    print(f"{args.site}: N={len(y)}, selected {len(kept)}/{len(feats)} at alpha={m.alpha_:.4f}: {kept}")


# ------------------------------------------------------------------ site: fit
def fit_models(args):
    """Phase 2 (site): fit Ridge/LASSO/RF on the consensus features."""
    feats = list(pd.read_csv(args.features)["feature"])
    df = pd.read_csv(args.data)
    y = df[args.target].astype(float).values
    X = df.reindex(columns=feats).fillna(0.0).astype(float).values
    sc = MinMaxScaler().fit(X)
    Xs = sc.transform(X)
    os.makedirs(args.outdir, exist_ok=True)

    for name, model in [("ridge", Ridge(alpha=args.ridge_alpha)),
                        ("lasso", Lasso(alpha=args.lasso_alpha, max_iter=50000))]:
        m = model.fit(Xs, y)
        rows = [{"feature": "__intercept__", "coefficient": float(m.intercept_)}]
        rows += [{"feature": f, "coefficient": float(c)} for f, c in zip(feats, m.coef_)]
        vec = pd.DataFrame(rows)
        vec["site"] = args.site
        vec["n_subjects"] = len(y)
        vec["method"] = name
        vec.to_csv(os.path.join(args.outdir, f"{args.site}_{name}_vector.csv"), index=False)
        print(f"Wrote {args.site}_{name}_vector.csv")

    rf = RandomForestRegressor(n_estimators=args.n_trees, min_samples_leaf=2,
                               n_jobs=1, random_state=args.seed).fit(Xs, y)
    with open(os.path.join(args.outdir, f"{args.site}_rf.pkl"), "wb") as fh:
        pickle.dump({"forest": rf, "scaler": sc, "features": feats,
                     "site": args.site, "n_subjects": len(y)}, fh)
    print(f"Wrote {args.site}_rf.pkl  ({args.n_trees} trees on {len(feats)} features)")


# ------------------------------------------------------ aggregator: consensus
def consensus_features(args):
    """Phase 1 (aggregator): keep features selected by >= threshold sites."""
    files = sorted(glob.glob(os.path.join(args.input_dir, "**", "*_selected_features.csv"),
                             recursive=True))
    if not files:
        raise SystemExit(f"No *_selected_features.csv under {args.input_dir}")
    counts, sites = {}, []
    for f in files:
        d = pd.read_csv(f)
        sites.append(d["site"].iloc[0] if "site" in d.columns else os.path.basename(f))
        for feat in d.loc[d["selected"] == 1, "feature"]:
            counts[feat] = counts.get(feat, 0) + 1
    n = len(files)
    thr = args.min_sites if args.min_sites is not None else (n // 2 + 1)
    consensus = sorted(f for f, c in counts.items() if c >= thr)
    os.makedirs(args.outdir, exist_ok=True)
    pd.DataFrame({"feature": consensus}).to_csv(
        os.path.join(args.outdir, "consensus_features.csv"), index=False)
    tally = pd.DataFrame(sorted(counts.items(), key=lambda kv: -kv[1]),
                         columns=["feature", "n_sites_selected"])
    tally["kept"] = (tally["n_sites_selected"] >= thr).astype(int)
    tally.to_csv(os.path.join(args.outdir, "feature_selection_tally.csv"), index=False)
    print(f"{n} sites {sites}, threshold {thr}")
    print(f"consensus features ({len(consensus)}): {consensus}")


# ---------------------------------------------------- aggregator: aggregate
def aggregate_vectors(args):
    """Phase 2 (aggregator): combine site coefficient vectors / forests."""
    os.makedirs(args.outdir, exist_ok=True)
    for meth in ("ridge", "lasso"):
        files = sorted(glob.glob(os.path.join(args.input_dir, "**", f"*_{meth}_vector.csv"),
                                 recursive=True))
        if not files:
            continue
        series, sizes = [], []
        for f in files:
            d = pd.read_csv(f).set_index("feature")
            series.append(d["coefficient"])
            sizes.append(int(d["n_subjects"].iloc[0]) if "n_subjects" in d.columns else 1)
        allfeats = sorted(set().union(*[set(s.index) for s in series]))
        M = np.array([[s.get(f, 0.0) for f in allfeats] for s in series])
        sizes = np.array(sizes)
        if args.method == "fedavg":
            agg = np.average(M, axis=0, weights=sizes)
        elif args.method == "median":
            agg = np.median(M, axis=0)
        else:
            agg = M.mean(axis=0)
        out = pd.DataFrame({"feature": allfeats, "coefficient": agg})
        out["method"] = meth
        out["aggregation"] = args.method
        out["n_sites"] = len(files)
        out.to_csv(os.path.join(args.outdir, f"federated_{meth}_{args.method}_vector.csv"), index=False)
        print(f"Aggregated {len(files)} {meth} vectors by {args.method}")

    rf_files = sorted(glob.glob(os.path.join(args.input_dir, "**", "*_rf.pkl"), recursive=True))
    if rf_files:
        forests = []
        for f in rf_files:
            with open(f, "rb") as fh:
                forests.append(pickle.load(fh))
        with open(os.path.join(args.outdir, "federated_rf_union.pkl"), "wb") as fh:
            pickle.dump({"forests": forests, "aggregation": "union"}, fh)
        print(f"Union of {len(rf_files)} forests -> federated_rf_union.pkl")


def main(argv=None):
    p = argparse.ArgumentParser(prog="oadr-cpep-cli",
                                description="Federated prediction of residual beta-cell function")
    sub = p.add_subparsers(dest="cmd", required=True)

    a = sub.add_parser("select-features", help="Phase 1 (site) LASSO feature selection")
    a.add_argument("--data", required=True); a.add_argument("--site", required=True)
    a.add_argument("--target", default="log_auc"); a.add_argument("--out", default=None)
    a.add_argument("--seed", type=int, default=42); a.set_defaults(func=select_features)

    a = sub.add_parser("fit-models", help="Phase 2 (site) fit Ridge/LASSO/RF on consensus features")
    a.add_argument("--data", required=True); a.add_argument("--features", required=True)
    a.add_argument("--site", required=True); a.add_argument("--target", default="log_auc")
    a.add_argument("--outdir", default="."); a.add_argument("--ridge-alpha", type=float, default=1.0)
    a.add_argument("--lasso-alpha", type=float, default=0.008); a.add_argument("--n-trees", type=int, default=200)
    a.add_argument("--seed", type=int, default=42); a.set_defaults(func=fit_models)

    a = sub.add_parser("consensus-features", help="Phase 1 (aggregator) tally site selections")
    a.add_argument("--input_dir", required=True); a.add_argument("--min-sites", type=int, default=None)
    a.add_argument("--outdir", default="."); a.set_defaults(func=consensus_features)

    a = sub.add_parser("aggregate-vectors", help="Phase 2 (aggregator) combine site parameters")
    a.add_argument("--input_dir", required=True)
    a.add_argument("--method", default="fedavg", choices=["fedavg", "median", "mean"])
    a.add_argument("--outdir", default="."); a.set_defaults(func=aggregate_vectors)

    args = p.parse_args(argv)
    args.func(args)


if __name__ == "__main__":
    main()
