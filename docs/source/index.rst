oadr-cpep-fed-predict-site-nf
=============================

The **per-institution workflow** for federated prediction of residual beta-cell
function (C-peptide AUC) in Type 1 Diabetes. Each site selects features on its
**own** data and fits Ridge / LASSO / Random-Forest models (a single DAG:
``select_features_process`` → the three ``fit_*_process`` steps), then applies the coordinator's
federated coefficients to score itself. Only model parameters — feature lists,
coefficient vectors, trained forests — and scalar performance summaries ever leave
the site; subject-level data never moves.

Every step runs the ``oadr-cpep`` CLI from the shared
`ghcr.io/nih-nlm/oadr-cpep <https://github.com/NIH-NLM/oadr-cpep>`_ image and takes
its inputs as explicit files (no directory, no glob). Pairs with the coordinator
workflow
`oadr-cpep-fed-predict-aggregator-nf <https://github.com/NIH-NLM/oadr-cpep-fed-predict-aggregator-nf>`_.

.. toctree::
   :maxdepth: 2
   :caption: Overview

   README

.. toctree::
   :maxdepth: 2
   :caption: Nextflow Workflow

   nextflow/index

Related projects
----------------

- `oadr-cpep <https://github.com/NIH-NLM/oadr-cpep>`_ — the Python package (CLI + methods) these processes call
- `oadr-cpep-fed-predict-aggregator-nf <https://github.com/NIH-NLM/oadr-cpep-fed-predict-aggregator-nf>`_ — the coordinator workflow

Indices and tables
==================

* :ref:`genindex`
* :ref:`search`
