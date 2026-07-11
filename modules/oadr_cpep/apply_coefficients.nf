/**
 * Phase 3 (site) — this site's own outcome using the federated results.
 *
 * Runs `oadr-cpep apply-coefficients` over this site's own data. The aggregator's
 * federated vectors are passed EXPLICITLY (`fed_args` = `--ridge-vector/--lasso-vector/
 * --rf-union`) and staged flat, as are the data files (`data_args`). For each method
 * it compares the site's SOLO model (5-fold CV) against the FEDERATED model, with
 * bootstrap 95% CIs and a combined graphic. Subject-level predictions stay local;
 * the scalar performance summary is what leaves.
 *
 * Input : val site, val data_args, path data_files, val fed_args, path fed_files (staged)
 * Output: metrics -> *_federated_metrics.csv ; predictions ; figures
 */
process apply_coefficients_process {
    tag "apply_coefficients_${site}"
    label 'oadr_cpep'
    containerOptions '--entrypoint ""'
    publishDir "${params.outdir}", mode: params.publish_mode

    input:
    val site
    val data_args
    path data_files
    val fed_args
    path fed_files

    output:
    path "*_federated_metrics.csv",     emit: metrics
    path "*_federated_predictions.csv", emit: predictions
    path "*_federated.{png,svg,html}",  emit: figures

    script:
    """
    oadr-cpep apply-coefficients \
        --site ${site} \
        --panel ${params.panel} \
        ${data_args} \
        ${fed_args} \
        --ridge-alpha ${params.ridge_alpha} \
        --lasso-alpha ${params.lasso_alpha} \
        --n-boot ${params.n_boot} \
        --seed ${params.seed}
    """
}
