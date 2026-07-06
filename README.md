# oadr-cpep-fed-predict-site-nf

The **per-site (institution) workflow** for federated prediction of residual
beta-cell function (C-peptide AUC) in Type 1 Diabetes. Each institution runs
this on its own data; only model parameters and scalar performance summaries
ever leave the site.

Pairs with the coordinator workflow **oadr-cpep-fed-predict-aggregator-nf**,
which builds the consensus feature set and aggregates the fitted parameters.

## Three phases (one reusable workflow)

The artifact you pass selects the phase:

**Phase 1 — feature selection** (no artifact):
```bash
nextflow run main.nf --site SDY524 --panel B --data_root /path/to/data
```
Runs LASSO on the site's data and emits `SDY524_selected_features.csv`. The
aggregator collects every site's selection and broadcasts back a
`consensus_features.csv`.

**Phase 2 — fit on consensus features** (`--consensus_features`):
```bash
nextflow run main.nf --site SDY524 --panel B --data_root /path/to/data \
    --consensus_features consensus_features.csv
```
Fits Ridge, LASSO, and Random Forest on the consensus features — LASSO
selection is not repeated — and emits `SDY524_ridge_vector.csv`,
`SDY524_lasso_vector.csv`, and `SDY524_rf.pkl`. These go to the aggregator.

**Phase 3 — incorporate the federated coefficients** (`--federated_coefficients`):
```bash
nextflow run main.nf --site SDY524 --panel B --data_root /path/to/data \
    --federated_coefficients federated_ridge_fedavg_vector.csv
```
Takes the aggregator's central FedAvg vector and evaluates it from this site's
own view — a 5-fold CV comparing the site's **solo** model against the
**federated** model, with bootstrap 95% CIs on R² and an observed-vs-predicted
scatter. The central vector is applied **as-is**: it already includes this
site's contribution, so it is not re-blended with the site's own coefficients
(that would double-count this site). Emits
`SDY524_ridge_federated_performance.csv` (solo/federated R² + CIs, meant to
leave the site), `SDY524_ridge_federated_predictions.csv` (subject-level, kept
local), and `SDY524_ridge_federated.{png,pdf}`.

The method (`ridge`/`lasso`) is read from the vector; Random Forest is deferred
(its federated form — union of forests — is an aggregator method).

## Input data

The workflow reads the **same ImmPort-derived `data/` tree** the
oadr-autoantibody notebooks use, through the embedded `oadr_data` loader — you
do not pre-build a CSV. Point `--data_root` at that tree:

```
data/
  <study>_tidy.csv                 Panel A features (per study)
  <study>_cpeptide_auc_tidy.csv    the C-peptide AUC target
  Jeff/aa_<id>.csv, demo_<id>.csv  Panel B extended features (524/569/1737)
  arms/<study>_arm_or_cohort.txt   treatment (subject → arm → treatment)
  arms/<study>_arm_2_subject.txt
```

`--panel A` builds the 9 legacy features; `--panel B` builds the 12 extended
features. All cleanup (column normalization, height repair, median fill,
treatment-by-arm-closure) happens in `oadr_data`, within-study. The data stays
at the site — only parameters and scalar summaries leave.

## The container

A self-contained image, `container/oadr-cpep/`, provides the per-site
`oadr-cpep-cli` (subcommands `select-features`, `fit-models`,
`apply-coefficients`) plus the embedded `oadr_data` loader. Build once and
publish; the site workflow references it. The aggregator step has its own image
in **oadr-cpep-fed-predict-aggregator-nf**.

```bash
docker build -t ghcr.io/nih-nlm/oadr-cpep:0.1.0 container/oadr-cpep/
```

## Layout

```
container/oadr-cpep/          site CLI image (Dockerfile + context/src/oadr_cpep_cli, incl. oadr_data.py)
modules/oadr_cpep/            Nextflow processes calling the CLI
main.nf                       phase gate (select / fit / apply)
nextflow.config              params + container binding
```

## Parameters

| Param | Default | Meaning |
|---|---|---|
| `--site` | — | study id, e.g. SDY524 (required) |
| `--data_root` | — | the oadr-autoantibody `data/` tree (required) |
| `--panel` | `B` | feature panel: `A` (legacy 9) or `B` (extended 12) |
| `--consensus_features` | null | pass to run Phase 2 (fit on consensus features) |
| `--federated_coefficients` | null | pass to run Phase 3 (incorporate federated coefficients) |
| `--federated_method` | null | Phase 3 method `ridge`/`lasso` (default: read from the vector) |
| `--n_boot` | 2000 | Phase 3 bootstrap resamples for the R² 95% CI |
| `--ridge_alpha` / `--lasso_alpha` | 1.0 / 0.008 | penalties for Phases 2 & 3 |
| `--n_trees` | 200 | random forest size (Phase 2) |
| `--seed` | 42 | reproducibility |

With none of `--consensus_features` / `--federated_coefficients`, the workflow
runs Phase 1 (feature selection).
