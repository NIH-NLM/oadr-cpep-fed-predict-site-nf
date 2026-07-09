/**
 * Phase 3 (site) — this site's own outcome using the federated results.
 *
 * Runs `oadr-cpep apply-coefficients` over this site's own data. The aggregator's
 * federated_* results (ridge/lasso vectors + rf union) are staged FLAT into the
 * work dir and discovered via --coefficients-dir . ; --from scopes to one feature
 * source. For each method it compares the site's SOLO model (5-fold CV) against
 * the FEDERATED model, with bootstrap 95% CIs and a combined graphic. Subject-
 * level predictions stay local; the scalar performance summary is what leaves.
 *
 * Input : val site, path data_files (flat), path federated (federated_* results, staged)
 * Output: path *_federated_metrics.csv, *_federated_predictions.csv, *_federated.{png,svg,html}
 */
process APPLY_COEFFICIENTS {
    tag "apply_coefficients_${site}"
    label 'oadr_cpep'
    publishDir "${params.outdir}/federated_predictions", mode: params.publish_mode

    input:
    val site
    path data_files
    path federated

    output:
    path "*_federated_metrics.csv",     emit: metrics
    path "*_federated_predictions.csv", emit: predictions
    path "*_federated.{png,svg,html}",  emit: figures

    script:
    def from = params.from ? "--from ${params.from}" : ""
    """
    oadr-cpep apply-coefficients \
        --site ${site} \
        --panel ${params.panel} \
        --coefficients-dir . \
        ${from} \
        --ridge-alpha ${params.ridge_alpha} \
        --lasso-alpha ${params.lasso_alpha} \
        --n-boot ${params.n_boot} \
        --seed ${params.seed} \
        --outdir .
    """
}
