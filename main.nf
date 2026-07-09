#!/usr/bin/env nextflow
/*
========================================================================================
  oadr-cpep-fed-predict-site-nf  —  the per-site (institution) workflow
========================================================================================
  Three phases, one reusable workflow, gated by which artifact you pass. Data is
  read through the embedded oadr_data loader (--site = study, --panel A|B); the
  data files are given as a glob (--data_files) and staged FLAT into each process
  work dir, so nothing depends on a directory layout on AWS spot nodes.

    Phase 1  (no artifact):        LASSO selects features on this site's data.
    Phase 2  (--consensus_features): fit-ridge / fit-lasso / fit-rf on that feature
             set -> coefficient vectors + forest (each its own process).
    Phase 3  (--federated_coefficients): apply the aggregator's federated results
             to this site -> per-site outcome (solo vs federated). --from scopes
             to one feature source.

  Every step runs the shared ghcr.io/nih-nlm/oadr-cpep container. Only model
  parameters and scalar performance summaries ever leave the site.
*/

nextflow.enable.dsl = 2

include { SELECT_FEATURES }    from './modules/oadr_cpep/select_features.nf'
include { FIT_RIDGE }          from './modules/oadr_cpep/fit_ridge.nf'
include { FIT_LASSO }          from './modules/oadr_cpep/fit_lasso.nf'
include { FIT_RF }             from './modules/oadr_cpep/fit_rf.nf'
include { APPLY_COEFFICIENTS } from './modules/oadr_cpep/apply_coefficients.nf'

workflow {
    if (!params.site)       error "Please provide --site (the study id, e.g. SDY524)"
    if (!params.data_files) error "Please provide --data_files (glob of the flat data files, e.g. 's3://bucket/data/*')"

    // Collect every matching data file into one bundle (a value channel, reused
    // by every process) so Nextflow stages them all FLAT into each work dir.
    data_files_ch = channel.fromPath(params.data_files, checkIfExists: true).collect()

    if (params.federated_coefficients) {
        // Phase 3 — apply the aggregator's federated_* results to this site
        fed_ch = channel.fromPath(params.federated_coefficients, checkIfExists: true).collect()
        APPLY_COEFFICIENTS(params.site, data_files_ch, fed_ch)
    } else if (params.consensus_features) {
        // Phase 2 — fit each method on the feature set (.first() -> reusable value channel)
        features_ch = channel.fromPath(params.consensus_features, checkIfExists: true).first()
        FIT_RIDGE(params.site, data_files_ch, features_ch)
        FIT_LASSO(params.site, data_files_ch, features_ch)
        FIT_RF(params.site, data_files_ch, features_ch)
    } else {
        // Phase 1 — feature selection
        SELECT_FEATURES(params.site, data_files_ch)
    }
}
