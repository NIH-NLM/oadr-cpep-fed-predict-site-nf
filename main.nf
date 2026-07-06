#!/usr/bin/env nextflow
/*
========================================================================================
  oadr-cpep-fed-predict-site-nf  —  the per-site (institution) workflow
========================================================================================
  Three phases, one reusable workflow, gated by which artifact you pass. Data is
  read through the embedded oadr_data loader (the same one the oadr-autoantibody
  notebooks use): --site is the study (e.g. SDY524), --panel is A or B, and
  --data_root points at the ImmPort-derived data/ tree.

    Phase 1  (no artifact):  LASSO selects features on this site's data
             -> <site>_selected_features.csv.

    Phase 2  (--consensus_features):  Ridge / LASSO / Random Forest are fit on
             the consensus features -> coefficient vectors + forest.

    Phase 3  (--federated_coefficients):  the central federated vector is applied
             to this site's own data -> per-site performance (solo vs federated).

  Only model parameters and scalar performance summaries ever leave the site.
*/

nextflow.enable.dsl = 2

include { SELECT_FEATURES }    from './modules/oadr_cpep/select_features.nf'
include { FIT_MODELS }         from './modules/oadr_cpep/fit_models.nf'
include { APPLY_COEFFICIENTS } from './modules/oadr_cpep/apply_coefficients.nf'

workflow {
    if (!params.site)      error "Please provide --site (the study id, e.g. SDY524)"
    if (!params.data_root) error "Please provide --data_root (the oadr-autoantibody data/ tree)"

    data_root_ch = channel.fromPath(params.data_root, type: 'dir', checkIfExists: true)

    if (params.federated_coefficients) {
        // Phase 3 — apply the federated coefficients to this site's data
        coeff_ch = channel.fromPath(params.federated_coefficients, checkIfExists: true)
        APPLY_COEFFICIENTS(params.site, data_root_ch, coeff_ch)
    } else if (params.consensus_features) {
        // Phase 2 — fit on the consensus features
        features_ch = channel.fromPath(params.consensus_features, checkIfExists: true)
        FIT_MODELS(params.site, data_root_ch, features_ch)
    } else {
        // Phase 1 — feature selection
        SELECT_FEATURES(params.site, data_root_ch)
    }
}
