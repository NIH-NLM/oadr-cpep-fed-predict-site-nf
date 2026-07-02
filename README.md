# oadr-cpep-fed-predict-site-nf

The **per-site (institution) workflow** for federated prediction of residual
beta-cell function (C-peptide AUC) in Type 1 Diabetes. Each institution runs
this on its own data; only model parameters ever leave the site.

Pairs with the coordinator workflow **oadr-cpep-fed-predict-aggregator-nf**.

## Two phases (one reusable workflow)

Gated by `--consensus_features`:

**Phase 1 — feature selection** (no `--consensus_features`):
```bash
nextflow run main.nf --data SDY524_data.csv --site SDY524
```
Runs LASSO on the site's data and emits `SDY524_selected_features.csv`. The
coordinator collects every site's selection and broadcasts back a
`consensus_features.csv`.

**Phase 2 — fit on consensus features** (`--consensus_features` provided):
```bash
nextflow run main.nf --data SDY524_data.csv --site SDY524 \
    --consensus_features consensus_features.csv
```
Fits Ridge, LASSO, and Random Forest on the consensus features — LASSO
selection is not repeated — and emits `SDY524_ridge_vector.csv`,
`SDY524_lasso_vector.csv`, and `SDY524_rf.pkl`.

## Input data

A CSV with one column per feature plus the target column (`log_auc` by default).
One row per subject. The site prepares this locally; the workflow never sees any
other site's data.

## The container

One self-contained image, `container/oadr-cpep/`, provides `oadr-cpep-cli`
(subcommands `select-features`, `fit-models`, and — used by the aggregator —
`consensus-features`, `aggregate-vectors`). Build once and publish; both
workflows reference the same image.

```bash
docker build -t ghcr.io/nih-nlm/oadr-cpep:0.1.0 container/oadr-cpep/
```

## Layout

```
container/oadr-cpep/          shared CLI image (Dockerfile + context/src/oadr_cpep_cli)
modules/oadr_cpep/            Nextflow processes calling the CLI
main.nf                       phase gate (select vs fit)
nextflow.config              params + container binding
```

## Parameters

| Param | Default | Meaning |
|---|---|---|
| `--data` | — | this site's data CSV (required) |
| `--site` | — | institution id, e.g. SDY524 (required) |
| `--consensus_features` | null | Phase 1 if absent; Phase 2 if a consensus CSV is given |
| `--target` | `log_auc` | outcome column |
| `--ridge_alpha` / `--lasso_alpha` | 1.0 / 0.008 | penalties for Phase 2 |
| `--n_trees` | 200 | random forest size |
| `--seed` | 42 | reproducibility |
