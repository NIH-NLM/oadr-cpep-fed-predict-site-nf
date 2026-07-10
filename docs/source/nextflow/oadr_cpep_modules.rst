Oadr Cpep Modules
=================

Apply Coefficients Process
^^^^^^^^^^^^^^^^^^^^^^^^^^

.. rubric:: ``apply_coefficients_process``

*Source:* ``modules/oadr_cpep/apply_coefficients.nf``

::

   Phase 3 (site) — this site's own outcome using the federated results.
   
   Runs `oadr-cpep apply-coefficients` over this site's own data. The aggregator's
   federated vectors are passed EXPLICITLY (`fed_args` = `--ridge-vector/--lasso-vector/
   --rf-union`) and staged flat, as are the data files (`data_args`). For each method
   it compares the site's SOLO model (5-fold CV) against the FEDERATED model, with
   bootstrap 95% CIs and a combined graphic. Subject-level predictions stay local;
   the scalar performance summary is what leaves.
   
   Input : val site, val data_args, path data_files, val fed_args, path fed_files (staged)
   Output: metrics -> *_federated_metrics.csv ; predictions ; figures

**Params referenced:**

- ``params.lasso_alpha``
- ``params.n_boot``
- ``params.outdir``
- ``params.panel``
- ``params.publish_mode``
- ``params.ridge_alpha``
- ``params.seed``


Fit Lasso Process
^^^^^^^^^^^^^^^^^

.. rubric:: ``fit_lasso_process``

*Source:* ``modules/oadr_cpep/fit_lasso.nf``

::

   Phase 2 (site) — fit LASSO on the given feature set.
   
   Runs `oadr-cpep fit-lasso` over this site's own data on the feature list handed
   in. Data files are passed EXPLICITLY (`data_args`) and staged flat. Emits the
   coefficient vector (to the aggregator), the 5-fold CV metrics, and a fit graphic,
   stamped `from-<src>`.
   
   Input : val site, path features, val data_args, path data_files (staged)
   Output: vector -> *_lasso_vector.csv ; metrics ; figures

**Params referenced:**

- ``params.lasso_alpha``
- ``params.n_boot``
- ``params.outdir``
- ``params.panel``
- ``params.publish_mode``
- ``params.seed``


Fit Rf Process
^^^^^^^^^^^^^^

.. rubric:: ``fit_rf_process``

*Source:* ``modules/oadr_cpep/fit_rf.nf``

::

   Phase 2 (site) — fit a Random Forest on the given feature set.
   
   Runs `oadr-cpep fit-rf` over this site's own data on the feature list handed in.
   Data files are passed EXPLICITLY (`data_args`) and staged flat. Emits the trained
   forest (to the aggregator), the 5-fold CV metrics, and a fit graphic, stamped
   `from-<src>`.
   
   Input : val site, path features, val data_args, path data_files (staged)
   Output: forest -> *_rf.pkl ; metrics ; figures

**Params referenced:**

- ``params.n_boot``
- ``params.n_trees``
- ``params.outdir``
- ``params.panel``
- ``params.publish_mode``
- ``params.seed``


Fit Ridge Process
^^^^^^^^^^^^^^^^^

.. rubric:: ``fit_ridge_process``

*Source:* ``modules/oadr_cpep/fit_ridge.nf``

::

   Phase 2 (site) — fit Ridge on the given feature set.
   
   Runs `oadr-cpep fit-ridge` over this site's own data on the feature list handed
   in (chained from select_features_process, or an external feature list). Data files are
   passed EXPLICITLY (`data_args`) and staged flat. Emits the coefficient vector (to
   the aggregator), the 5-fold CV metrics, and a fit graphic, stamped `from-<src>`.
   
   Input : val site, path features, val data_args, path data_files (staged)
   Output: vector -> *_ridge_vector.csv ; metrics ; figures

**Params referenced:**

- ``params.n_boot``
- ``params.outdir``
- ``params.panel``
- ``params.publish_mode``
- ``params.ridge_alpha``
- ``params.seed``


Select Features Process
^^^^^^^^^^^^^^^^^^^^^^^

.. rubric:: ``select_features_process``

*Source:* ``modules/oadr_cpep/select_features.nf``

::

   Phase 1 (site) — LASSO feature selection.
   
   Runs `oadr-cpep select-features` on this institution's own data. The data files
   are passed EXPLICITLY (`data_args` = the `--aa/--demo/--cpeptide/…` flags built in
   main.nf) and staged flat (`data_files`). Emits the selected-features list (which
   feeds the fits via a channel, and the aggregator) and the full LASSO result;
   no subject-level data leaves the site.
   
   Input : val site, val data_args (the --<file> flags), path data_files (staged)
   Output: selected -> *_selected_features.csv ; full -> *_lasso_selection.csv

**Params referenced:**

- ``params.outdir``
- ``params.panel``
- ``params.publish_mode``
- ``params.seed``

