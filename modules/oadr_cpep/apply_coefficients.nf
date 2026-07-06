/**
 * Phase 3 (site) — incorporate the central federated coefficients.
 *
 * Runs oadr-cpep-cli apply-coefficients over this site's own data (loaded via
 * oadr_data, --site = study, --panel A|B): reproduces the Stage-2 evaluation —
 * 5-fold CV comparing the site's SOLO model against the FEDERATED model,
 * bootstrap 95% CIs on R², and an observed-vs-predicted scatter. The federated
 * arm applies the aggregator's central FedAvg vector as-is (it already includes
 * this site, so it is not re-blended). Subject-level predictions stay local; the
 * scalar performance summary is what is meant to leave the site.
 *
 * Input : val site (study id), path data_root, path federated_coefficients.csv
 * Output: path *_federated_performance.csv, *_federated_predictions.csv, *_federated.{png,pdf}
 */
process APPLY_COEFFICIENTS {
    tag "apply_coefficients_${site}"
    label 'oadr_cpep'
    publishDir "${params.outdir}/federated_predictions", mode: params.publish_mode

    input:
    val site
    path data_root
    path coefficients

    output:
    path "*_federated_performance.csv", emit: performance
    path "*_federated_predictions.csv", emit: predictions
    path "*_federated.{png,pdf}",       emit: figures

    script:
    def method = params.federated_method ? "--method ${params.federated_method}" : ""
    """
    oadr-cpep-cli apply-coefficients \
        --site ${site} \
        --panel ${params.panel} \
        --data-root ${data_root} \
        --coefficients ${coefficients} \
        ${method} \
        --ridge-alpha ${params.ridge_alpha} \
        --lasso-alpha ${params.lasso_alpha} \
        --n-boot ${params.n_boot} \
        --seed ${params.seed} \
        --outdir .
    """
}
