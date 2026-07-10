#!/usr/bin/env nextflow
/*
========================================================================================
  oadr-cpep-fed-predict-site-nf  —  the per-site (institution) workflow
========================================================================================
  A single DAG: select_features_process ──▶ fit_ridge_process / fit_lasso_process / fit_rf_process, with the selected
  features fed to the fits through a channel (the sc-nsforest chaining model). Every
  step takes its inputs as EXPLICIT files — the study's data files for the panel
  (Panel A: --tidy --cpeptide ; Panel B: --aa --demo --cpeptide [--arms --arm-subjects]) —
  no directory, no glob, nothing resolved by name.

  Two alternate entries at the federation boundaries:
    --features <csv>            fit on an external feature list (e.g. the aggregator's
                                consensus) instead of chaining from this site's select.
    --federated_ridge/_lasso/_rf  apply the aggregator's federated vectors to this site
                                (solo vs federated) — runs APPLY instead of select/fit.

  Every step runs the shared ghcr.io/nih-nlm/oadr-cpep container. Only model
  parameters and scalar performance summaries ever leave the site.
*/

nextflow.enable.dsl = 2

include { select_features_process }    from './modules/oadr_cpep/select_features.nf'
include { fit_ridge_process }          from './modules/oadr_cpep/fit_ridge.nf'
include { fit_lasso_process }          from './modules/oadr_cpep/fit_lasso.nf'
include { fit_rf_process }             from './modules/oadr_cpep/fit_rf.nf'
include { apply_coefficients_process } from './modules/oadr_cpep/apply_coefficients.nf'

workflow {
    if (!params.site)     error "Please provide --site (the study id, e.g. SDY524)"
    if (!params.cpeptide) error "Please provide --cpeptide (the C-peptide AUC target, both panels)"
    // Nextflow params use underscores: --arm_subjects (not --arm-subjects). The two arm
    // files go together — guard against silently dropping the treatment feature.
    if ((params.arms && !params.arm_subjects) || (!params.arms && params.arm_subjects))
        error "Provide --arms and --arm_subjects together (both or neither) — the treatment closure needs both files."

    // Explicit data files -> a CLI-arg string (referencing the staged basenames)
    // plus the bundle of files to stage. No directory, no glob.
    def da = []
    if (params.tidy)         da << "--tidy ${file(params.tidy).name}"
    if (params.aa)           da << "--aa ${file(params.aa).name}"
    if (params.demo)         da << "--demo ${file(params.demo).name}"
    if (params.cpeptide)     da << "--cpeptide ${file(params.cpeptide).name}"
    if (params.arms)         da << "--arms ${file(params.arms).name}"
    if (params.arm_subjects) da << "--arm-subjects ${file(params.arm_subjects).name}"
    data_args  = da.join(' ')
    data_files = channel.fromPath([params.tidy, params.aa, params.demo, params.cpeptide,
                                   params.arms, params.arm_subjects].findAll { f -> f },
                                  checkIfExists: true).collect()

    if (params.federated_ridge || params.federated_lasso || params.federated_rf) {
        // Federation boundary — apply the aggregator's federated vectors
        def fa = []
        if (params.federated_ridge) fa << "--ridge-vector ${file(params.federated_ridge).name}"
        if (params.federated_lasso) fa << "--lasso-vector ${file(params.federated_lasso).name}"
        if (params.federated_rf)    fa << "--rf-union ${file(params.federated_rf).name}"
        fed_args  = fa.join(' ')
        fed_files = channel.fromPath([params.federated_ridge, params.federated_lasso,
                                      params.federated_rf].findAll { f -> f },
                                     checkIfExists: true).collect()
        apply_coefficients_process(params.site, data_args, data_files, fed_args, fed_files)
    } else {
        // Single DAG — fit on an external feature list, or chain from this site's select
        if (params.features) {
            feats = channel.value(file(params.features, checkIfExists: true))
        } else {
            select_features_process(params.site, data_args, data_files)
            feats = select_features_process.out.selected
        }
        fit_ridge_process(params.site, feats, data_args, data_files)
        fit_lasso_process(params.site, feats, data_args, data_files)
        fit_rf_process(params.site, feats, data_args, data_files)
    }
}
