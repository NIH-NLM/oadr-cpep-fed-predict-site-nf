#!/usr/bin/env nextflow
/*
========================================================================================
  oadr-cpep-fed-predict-site-nf  —  the per-site (institution) workflow
========================================================================================
  Two phases, one reusable workflow, gated by --consensus_features:

    Phase 1  (no --consensus_features):  LASSO selects features on this site's
             data -> <site>_selected_features.csv. The coordinator then builds
             the consensus set and broadcasts it back.

    Phase 2  (--consensus_features given):  Ridge / LASSO / Random Forest are
             fit on the consensus features -> coefficient vectors + forest.

  Only model parameters ever leave the site.
*/

nextflow.enable.dsl = 2

include { SELECT_FEATURES } from './modules/oadr_cpep/select_features.nf'
include { FIT_MODELS }      from './modules/oadr_cpep/fit_models.nf'

workflow {
    if (!params.data) error "Please provide --data (this site's data CSV)"
    if (!params.site) error "Please provide --site (this institution's identifier)"

    data_ch = channel.fromPath(params.data, checkIfExists: true)

    if (!params.consensus_features) {
        // Phase 1 — feature selection
        SELECT_FEATURES(params.site, data_ch)
    } else {
        // Phase 2 — fit on the consensus features
        features_ch = channel.fromPath(params.consensus_features, checkIfExists: true)
        FIT_MODELS(params.site, data_ch, features_ch)
    }
}
