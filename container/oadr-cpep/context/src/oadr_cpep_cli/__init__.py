"""oadr-cpep-cli — per-site steps of federated C-peptide prediction.

  select-features   : Phase 1 — LASSO feature selection on this site's data.
  fit-models        : Phase 2 — Ridge/LASSO/RF on the consensus features.
  apply-coefficients: Phase 3 — incorporate the aggregator's central federated
                      vector: solo-vs-federated 5-fold CV, bootstrap 95% CI, and
                      an observed-vs-predicted scatter, from this site's view.

Only model parameters (coefficient vectors, feature lists, trained forests) and
scalar performance summaries cross the site boundary — never subject-level data.
The aggregator-side steps live in the oadr-cpep-fed-predict-aggregator-nf repo.
"""
__version__ = "0.1.0"
