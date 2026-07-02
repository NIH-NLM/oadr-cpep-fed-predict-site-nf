"""oadr-cpep-cli — federated prediction of residual beta-cell function.

Four subcommands drive the two Nextflow workflows:

  site       : select-features   (Phase 1 — LASSO feature selection)
               fit-models        (Phase 2 — Ridge/LASSO/RF on consensus features)
  aggregator : consensus-features (Phase 1 — tally site selections)
               aggregate-vectors  (Phase 2 — FedAvg / median / union-of-forests)

Only model parameters (coefficient vectors, feature lists, trained forests)
cross the site boundary — never subject-level data.
"""
__version__ = "0.1.0"
