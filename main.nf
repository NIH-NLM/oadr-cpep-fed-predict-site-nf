#!/usr/bin/env nextflow
/*
========================================================================================
  oadr-cpep-fed-predict-site-nf  —  the per-site (institution) workflow
========================================================================================
  Three phases, one reusable workflow, gated by which artifact you pass:

    Phase 1  (no artifact):  LASSO selects features on this site's data
             -> <site>_selected_features.csv. The coordinator then builds the
             consensus set and broadcasts it back.

    Phase 2  (--consensus_features):  Ridge / LASSO / Random Forest are fit on
             the consensus features -> coefficient vectors + forest. These go to
             the aggregator.

    Phase 3  (--federated_coefficients):  the federated coefficient vector the
             aggregator returns is applied to this site's own data
             -> per-site performance (and local predictions).

  Only model parameters and scalar performance summaries ever leave the site.
*/

nextflow.enable.dsl = 2

include { SELECT_FEATURES }    from './modules/oadr_cpep/select_features.nf'
include { FIT_MODELS }         from './modules/oadr_cpep/fit_models.nf'
include { APPLY_COEFFICIENTS } from './modules/oadr_cpep/apply_coefficients.nf'

workflow {
    if (!params.data) error "Please provide --data (this site's data CSV)"
    if (!params.site) error "Please provide --site (this institution's identifier)"

    data_ch = channel.fromPath(params.data, checkIfExists: true)

    if (params.federated_coefficients) {
        // Phase 3 — apply the federated coefficients to this site's data
        coeff_ch = channel.fromPath(params.federated_coefficients, checkIfExists: true)
        APPLY_COEFFICIENTS(params.site, data_ch, coeff_ch)
    } else if (params.consensus_features) {
        // Phase 2 — fit on the consensus features
        features_ch = channel.fromPath(params.consensus_features, checkIfExists: true)
        FIT_MODELS(params.site, data_ch, features_ch)
    } else {
        // Phase 1 — feature selection
        SELECT_FEATURES(params.site, data_ch)
    }
}
