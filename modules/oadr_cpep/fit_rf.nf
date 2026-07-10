/**
 * Phase 2 (site) — fit a Random Forest on the given feature set.
 *
 * Runs `oadr-cpep fit-rf` over this site's own data on the feature list handed in.
 * Data files are passed EXPLICITLY (`data_args`) and staged flat. Emits the trained
 * forest (to the aggregator), the 5-fold CV metrics, and a fit graphic, stamped
 * `from-<src>`.
 *
 * Input : val site, path features, val data_args, path data_files (staged)
 * Output: forest -> *_rf.pkl ; metrics ; figures
 */
process FIT_RF {
    tag "fit_rf_${site}"
    label 'oadr_cpep'
    containerOptions '--entrypoint ""'
    publishDir "${params.outdir}/vectors", mode: params.publish_mode

    input:
    val site
    path features
    val data_args
    path data_files

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
        ${data_args} \
        --n-trees ${params.n_trees} \
        --n-boot ${params.n_boot} \
        --seed ${params.seed}
    """
}
