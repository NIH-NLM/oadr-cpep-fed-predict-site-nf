# oadr-cpep-fed-predict-site-nf

The **cpep prediction workflow** for prediction of residual
beta-cell function (C-peptide AUC) in Type 1 Diabetes. 

Pairs with the coordinator workflow **oadr-cpep-fed-predict-aggregator-nf**,
which builds the consensus feature set and/or aggregates the fitted parameters.

## Three phases (one reusable workflow)

The artifact you pass selects the phase:

**Phase 1 — feature selection** (no artifact):
```bash
nextflow run main.nf --site SDY524 --panel B --data_files 's3://bucket/data/*'
```
Runs LASSO on the site's data and emits `SDY524_selected_features.csv`. The
aggregator collects every site's selection and broadcasts back a
`consensus_features.csv`.

**Phase 2 — fit on consensus features** (`--consensus_features`):
```bash
nextflow run main.nf --site SDY524 --panel B --data_files 's3://bucket/data/*' \
    --consensus_features consensus_features.csv
```
Fits Ridge, LASSO, and Random Forest on the consensus features — LASSO
selection is not repeated — and emits `SDY524_ridge_vector.csv`,
`SDY524_lasso_vector.csv`, and `SDY524_rf.pkl`. These go to the aggregator.

**Phase 3 — incorporate the federated coefficients** (`--federated_coefficients`):
```bash
nextflow run main.nf --site SDY524 --panel B --data_files 's3://bucket/data/*' \
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

The workflow reads the **same ImmPort-derived files** the oadr-autoantibody
notebooks use (via the embedded `oadr_data` loader) — you do not pre-build a
CSV. `--data_files` is a **glob**; every match is staged **flat** into each
process work dir, so nothing depends on a directory layout on ephemeral AWS spot
nodes. Upload the files flat and point the glob at them:

```
SDY<study>_tidy.csv                  Panel A features (per study)
SDY<study>_cpeptide_auc_tidy.csv     the C-peptide AUC target (both panels)
aa_<id>.csv, demo_<id>.csv           Panel B extended features (ids 524/569/1737)
SDY<study>_arm_or_cohort.txt         treatment (subject → arm → treatment)
SDY<study>_arm_2_subject.txt
```

The loader finds each file **by name** in the work dir (it also falls back to
`Jeff/` and `arms/` subdirs if you run against the original nested repo tree
locally). `--panel A` builds the 9 legacy features; `--panel B` builds the 12
extended features. All cleanup (column normalization, height repair, median
fill, treatment-by-arm-closure) happens in `oadr_data`, within-study. The data
stays at the site — only parameters and scalar summaries leave.

## The container

Every process runs the shared **`ghcr.io/nih-nlm/oadr-cpep`** image, which
provides the `oadr-cpep` CLI (`select-features`, `fit-ridge`/`fit-lasso`/`fit-rf`,
`apply-coefficients`) and the embedded `oadr_data` loader. The image is built and
published by the [oadr-cpep](https://github.com/NIH-NLM/oadr-cpep) package repo —
this workflow only references it (`params.container` in `nextflow.config`). The
same image serves the aggregator workflow.

## Layout

```
modules/oadr_cpep/   one process per step calling the oadr-cpep CLI:
                       select_features, fit_ridge, fit_lasso, fit_rf, apply_coefficients
main.nf              phase gate (select / fit-ridge+lasso+rf / apply)
nextflow.config      params + shared-container binding
```

## Parameters

| Param | Default | Meaning |
|---|---|---|
| `--site` | — | study id, e.g. SDY524 (required) |
| `--data_files` | — | glob of the flat data files, e.g. `s3://bucket/data/*` (required) |
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
