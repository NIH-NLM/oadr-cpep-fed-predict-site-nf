/**
 * Phase 2 (site) — fit a Random Forest on the given feature set.
 *
 * Runs `oadr-cpep fit-rf` over this site's own data on the feature list handed
 * in. Emits the trained forest (to the aggregator), the 5-fold CV metrics, and a
 * fit graphic, stamped `from-<src>` with the feature source.
 *
 * Input : val site, path data_files (flat, staged), path features
 * Output: path *_rf.pkl, *_rf_fit_metrics.csv, *_rf_fit.{png,svg,html}
 */
process FIT_RF {
    tag "fit_rf_${site}"
    label 'oadr_cpep'
    containerOptions '--entrypoint ""'
    publishDir "${params.outdir}/vectors", mode: params.publish_mode

    input:
    val site
    path data_files
    path features

    output:
    path "*_rf.pkl",                emit: forest
    path "*_rf_fit_metrics.csv",    emit: metrics
    path "*_rf_fit.{png,svg,html}", emit: figures

    script:
    """
    oadr-cpep fit-rf \
        --site ${site} \
        --panel ${params.panel} \
        --features ${features} \
        --n-trees ${params.n_trees} \
        --n-boot ${params.n_boot} \
        --seed ${params.seed} \
        --outdir .
    """
}
