# oadr-cpep-fed-predict-site-nf

The **per-institution workflow** for federated prediction of residual beta-cell
function (C-peptide AUC) in Type 1 Diabetes. A site selects features on its **own**
data and fits Ridge / LASSO / Random-Forest models — one DAG, `select_features_process`
→ the three `fit_*_process` — then applies the coordinator's federated coefficients to score
itself. Only model parameters leave the site; subject-level data never moves. Pairs
with the coordinator **oadr-cpep-fed-predict-aggregator-nf**.

Docs: <https://nih-nlm.github.io/oadr-cpep-fed-predict-site-nf>

## Run

Every step calls the `oadr-cpep` CLI from the shared `ghcr.io/nih-nlm/oadr-cpep`
image, given explicit data files — no directory, no glob. Nextflow params use
**underscores** (`--arm_subjects`, not `--arm-subjects`).

```bash
nextflow run main.nf --site SDY524 --panel B \
  --aa data/aa_524.csv --demo data/demo_524.csv --cpeptide data/SDY524_cpeptide_auc_tidy.csv \
  --arms data/SDY524_arm_or_cohort.txt --arm_subjects data/SDY524_arm_2_subject.txt
```

- **Panel A** needs only `--tidy` + `--cpeptide`; **Panel B** adds `--aa --demo`
  (+ `--arms --arm_subjects`, together or omit both).
- `--features <csv>` — fit on an external feature list (e.g. the consensus) instead
  of chaining from this site's own selection.
- `--federated_ridge` / `--federated_lasso` / `--federated_rf <file>` — apply the
  aggregator's federated vectors (solo vs federated) instead of select → fit.

## Test locally on a Mac (no Docker)

```bash
conda env create -f environment.yml && conda activate oadr-cpep-nf
pip install -e ../oadr-cpep
nextflow run main.nf -profile local --site SDY524 --panel B --aa … --demo … …
```

`-profile local` disables Docker and runs `oadr-cpep` from the env; drop it for the
containerized run (Lifebit / the published image).

## Parameters

| Param | Default | Meaning |
|---|---|---|
| `--site` · `--panel` | — · `B` | study id · feature panel (`A`/`B`) |
| `--cpeptide` | — | C-peptide AUC target (required) |
| `--tidy` | — | Panel A features |
| `--aa` · `--demo` | — | Panel B features |
| `--arms` · `--arm_subjects` | — | Panel B treatment files (together, or neither) |
| `--features` | null | fit on this external feature list (skips select) |
| `--federated_ridge`/`_lasso`/`_rf` | null | apply these federated vectors (runs apply) |
| `--ridge_alpha` · `--lasso_alpha` · `--n_trees` | 1.0 · 0.008 · 200 | model params |
| `--n_boot` · `--seed` · `--outdir` | 2000 · 42 · `results` | CI resamples · seed · publishDir |

## Layout

```
main.nf              single DAG (select → fit) + --features / --federated_* entries
modules/oadr_cpep/   select_features, fit_ridge, fit_lasso, fit_rf, apply_coefficients
nextflow.config      params + container + the `local` profile
environment.yml      conda env for local (no-Docker) testing
docs/                Sphinx (auto-generated from the .nf docblocks) → GitHub Pages
```
