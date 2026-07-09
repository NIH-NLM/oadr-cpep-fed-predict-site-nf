/**
 * Phase 2 (site) — fit Ridge on the given feature set.
 *
 * Runs `oadr-cpep fit-ridge` over this site's own data (--site = study, --panel
 * A|B) on the feature list handed in (consensus, a site's selection, or any
 * list). Emits the coefficient vector (to the aggregator), the 5-fold CV metrics,
 * and a fit graphic. Outputs are stamped `from-<src>` with the feature source.
 *
 * Input : val site, path data_files (flat, staged), path features
 * Output: path *_ridge_vector.csv, *_ridge_fit_metrics.csv, *_ridge_fit.{png,svg,html}
 */
process FIT_RIDGE {
    tag "fit_ridge_${site}"
    label 'oadr_cpep'
    containerOptions '--entrypoint ""'
    publishDir "${params.outdir}/vectors", mode: params.publish_mode

    input:
    val site
    path data_files
    path features

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
        --alpha ${params.ridge_alpha} \
        --n-boot ${params.n_boot} \
        --seed ${params.seed} \
        --outdir .
    """
}
