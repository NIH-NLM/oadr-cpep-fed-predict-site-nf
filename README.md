# oadr-cpep-fed-predict-site-nf

The **per-site (institution) workflow** for federated prediction of residual
beta-cell function (C-peptide AUC) in Type 1 Diabetes. Pairs with the coordinator
workflow **oadr-cpep-fed-predict-aggregator-nf**, which builds the consensus
feature set and aggregates the fitted parameters.

Every step takes its inputs as **explicit files** — no directory, no glob — and
runs the `oadr-cpep` CLI from the shared `ghcr.io/nih-nlm/oadr-cpep` image. Only
model parameters and scalar performance summaries ever leave the site.

## A single DAG (select → fit)

The default run is one DAG: `SELECT_FEATURES` selects on the site's own data and
its output feeds the three fits through a channel.

```
SELECT_FEATURES ──selected──▶ FIT_RIDGE
                          └──▶ FIT_LASSO
                          └──▶ FIT_RF
```

```bash
nextflow run main.nf -profile local \
  --site SDY524 --panel B \
  --aa data/aa_524.csv --demo data/demo_524.csv --cpeptide data/SDY524_cpeptide_auc_tidy.csv \
  --arms data/SDY524_arm_or_cohort.txt --arm_subjects data/SDY524_arm_2_subject.txt
```

→ `SDY524_panelB_selected_features.csv`, and per method
`SDY524_from-SDY524_panelB_{ridge,lasso}_vector.csv` / `_rf.pkl` (+ CV metrics + graphics).

### Two federation-boundary entries

The coordinator round-trips break the DAG, so these are separate invocations:

- **Fit on an external feature list** (`--features`) — e.g. the aggregator's
  consensus. Skips `SELECT_FEATURES` and fits the three methods on the given list:
  ```bash
  nextflow run main.nf -profile local --site SDY524 --panel B \
    --aa … --demo … --cpeptide … --arms … --arm_subjects … \
    --features consensus_panelB_features.csv
  ```
- **Apply the federated vectors** (`--federated_ridge` / `--federated_lasso` /
  `--federated_rf`) — runs `APPLY_COEFFICIENTS` (solo vs federated, bootstrap 95%
  CIs, combined graphic) instead of select/fit:
  ```bash
  nextflow run main.nf -profile local --site SDY524 --panel B \
    --aa … --demo … --cpeptide … --arms … --arm_subjects … \
    --federated_ridge federated_from-SDY524_panelB_ridge_fedavg_vector.csv \
    --federated_lasso federated_from-SDY524_panelB_lasso_fedavg_vector.csv \
    --federated_rf    federated_from-SDY524_panelB_rf_union.pkl
  ```

## Input data — explicit files

Pass the exact ImmPort-derived files the panel needs (read via the embedded
`oadr_data` loader; nothing is pre-built or found by name):

| Param | Panel | File |
|---|---|---|
| `--tidy` | A | `SDY<n>_tidy.csv` |
| `--cpeptide` | A & B | `SDY<n>_cpeptide_auc_tidy.csv` (required) |
| `--aa` | B | `aa_<n>.csv` |
| `--demo` | B | `demo_<n>.csv` |
| `--arms` | B | `SDY<n>_arm_or_cohort.txt` (with `--arm_subjects`) |
| `--arm_subjects` | B | `SDY<n>_arm_2_subject.txt` |

> **Nextflow params use underscores** — it is `--arm_subjects` and
> `--federated_ridge`, **not** `--arm-subjects`. A hyphen silently sets a
> different param. `--arms` and `--arm_subjects` must be given **together** (the
> treatment closure needs both, or `received_active_treatment` is dropped); the
> workflow errors if only one is supplied. Omit both for studies with no
> treatment arms (e.g. SDY1737).

## Test locally on a Mac (no Docker)

```bash
conda env create -f environment.yml
conda activate oadr-cpep-nf
pip install -e ../oadr-cpep          # the sibling package (editable)
nextflow run main.nf -profile local --site SDY524 --panel B --aa … --demo … …
```

`-profile local` disables Docker and runs the `oadr-cpep` CLI straight from the
env. Drop `-profile local` for the containerized run (Lifebit / the published
image), which needs the environment set up here at all.

## The container

Every process runs the shared **`ghcr.io/nih-nlm/oadr-cpep`** image, which
provides the `oadr-cpep` CLI (`select-features`, `fit-ridge`/`fit-lasso`/`fit-rf`,
`apply-coefficients`) and the embedded `oadr_data` loader. The image is built and
published by the [oadr-cpep](https://github.com/NIH-NLM/oadr-cpep) package repo —
this workflow only references it (`params.container`). Outputs are written to the
process work dir and published by `publishDir` (`--outdir`, default `results`).

## Parameters

| Param | Default | Meaning |
|---|---|---|
| `--site` | — | study id, e.g. SDY524 (required) |
| `--panel` | `B` | feature panel: `A` (legacy 9) or `B` (extended 12) |
| `--cpeptide` | — | C-peptide AUC target file (required) |
| `--tidy` | — | Panel A features file |
| `--aa` / `--demo` | — | Panel B feature files |
| `--arms` / `--arm_subjects` | — | Panel B treatment files (together, or neither) |
| `--features` | null | fit on this external feature list (skips select) |
| `--federated_ridge` / `_lasso` / `_rf` | null | apply these federated vectors (runs APPLY) |
| `--ridge_alpha` / `--lasso_alpha` | 1.0 / 0.008 | penalties |
| `--n_trees` | 200 | random forest size |
| `--n_boot` | 2000 | bootstrap resamples for the R² 95% CI |
| `--seed` | 42 | reproducibility |
| `--outdir` | `results` | publishDir destination |

With none of `--features` / `--federated_*`, the workflow runs the select → fit DAG.

## Layout

```
modules/oadr_cpep/   one process per step calling the oadr-cpep CLI:
                       select_features, fit_ridge, fit_lasso, fit_rf, apply_coefficients
main.nf              single DAG (select → fit) + the --features / --federated_* entries
nextflow.config      params + shared-container binding + the `local` profile
environment.yml      conda env for local (no-Docker) testing
```
