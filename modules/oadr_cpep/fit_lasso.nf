/**
 * Phase 2 (site) — fit LASSO on the given feature set.
 *
 * Runs `oadr-cpep fit-lasso` over this site's own data on the feature list handed
 * in. Data files are passed EXPLICITLY (`data_args`) and staged flat. Emits the
 * coefficient vector (to the aggregator), the 5-fold CV metrics, and a fit graphic,
 * stamped `from-<src>`.
 *
 * Input : val site, path features, val data_args, path data_files (staged)
 * Output: vector -> *_lasso_vector.csv ; metrics ; figures
 */
process FIT_LASSO {
    tag "fit_lasso_${site}"
    label 'oadr_cpep'
    containerOptions '--entrypoint ""'
    publishDir "${params.outdir}/vectors", mode: params.publish_mode

    input:
    val site
    path features
    val data_args
    path data_files

    output:
    path "*_lasso_vector.csv",         emit: vector
    path "*_lasso_fit_metrics.csv",    emit: metrics
    path "*_lasso_fit.{png,svg,html}", emit: figures

    script:
    """
    oadr-cpep fit-lasso \
        --site ${site} \
        --panel ${params.panel} \
        --features ${features} \
        ${data_args} \
        --alpha ${params.lasso_alpha} \
        --n-boot ${params.n_boot} \
        --seed ${params.seed}
    """
}
