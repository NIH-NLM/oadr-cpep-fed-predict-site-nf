/**
 * Phase 2 (site) — fit Ridge on the given feature set.
 *
 * Runs `oadr-cpep fit-ridge` over this site's own data on the feature list handed
 * in (chained from select_features_process, or an external feature list). Data files are
 * passed EXPLICITLY (`data_args`) and staged flat. Emits the coefficient vector (to
 * the aggregator), the 5-fold CV metrics, and a fit graphic, stamped `from-<src>`.
 *
 * Input : val site, path features, val data_args, path data_files (staged)
 * Output: vector -> *_ridge_vector.csv ; metrics ; figures
 */
process fit_ridge_process {
    tag "fit_ridge_${site}"
    label 'oadr_cpep'
    containerOptions '--entrypoint ""'
    publishDir "${params.outdir}", mode: params.publish_mode

    input:
    val site
    path features
    val data_args
    path data_files

    output:
    path "*_ridge_vector.csv",         emit: vector
    path "*_ridge_fit_metrics.csv",    emit: metrics
    path "*_ridge_fit.{png,svg,html}", emit: figures

    script:
    """
    oadr-cpep fit-ridge \
        --site ${site} \
        --panel ${params.panel} \
        --features ${features} \
        ${data_args} \
        --alpha ${params.ridge_alpha} \
        --n-boot ${params.n_boot} \
        --seed ${params.seed}
    """
}
