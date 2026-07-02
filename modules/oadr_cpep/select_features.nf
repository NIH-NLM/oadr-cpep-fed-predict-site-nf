/**
 * Phase 1 (site) — LASSO feature selection.
 *
 * Runs oadr-cpep-cli select-features on this institution's own data. Emits the
 * list of selected features and their coefficients; no subject-level data
 * leaves the site.
 *
 * Input : val site, path data (site data CSV: features + target column)
 * Output: path <site>_selected_features.csv
 */
process SELECT_FEATURES {
    tag "select_features_${site}"
    label 'oadr_cpep'
    publishDir "${params.outdir}/selected", mode: params.publish_mode

    input:
    val site
    path data

    output:
    path "*_selected_features.csv", emit: selected

    script:
    """
    oadr-cpep-cli select-features \\
        --data ${data} \\
        --site ${site} \\
        --target ${params.target} \\
        --seed ${params.seed}
    """
}
