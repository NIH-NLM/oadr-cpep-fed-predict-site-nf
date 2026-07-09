/**
 * Phase 2 (site) — fit LASSO on the given feature set.
 *
 * Runs `oadr-cpep fit-lasso` over this site's own data on the feature list handed
 * in. Emits the coefficient vector (to the aggregator), the 5-fold CV metrics,
 * and a fit graphic, stamped `from-<src>` with the feature source.
 *
 * Input : val site, path data_files (flat, staged), path features
 * Output: path *_lasso_vector.csv, *_lasso_fit_metrics.csv, *_lasso_fit.{png,svg,html}
 */
process FIT_LASSO {
    tag "fit_lasso_${site}"
    label 'oadr_cpep'
    publishDir "${params.outdir}/vectors", mode: params.publish_mode

    input:
    val site
    path data_files
    path features

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
        --alpha ${params.lasso_alpha} \
        --n-boot ${params.n_boot} \
        --seed ${params.seed} \
        --outdir .
    """
}
