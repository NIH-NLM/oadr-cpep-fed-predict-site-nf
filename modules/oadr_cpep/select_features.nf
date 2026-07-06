/**
 * Phase 1 (site) — LASSO feature selection.
 *
 * Runs oadr-cpep-cli select-features on this institution's own data, loaded via
 * the embedded oadr_data loader (--site = study, --panel A|B) from the staged
 * data/ tree. Emits the selected features + coefficients; no subject-level data
 * leaves the site.
 *
 * Input : val site (study id), path data_root (the data/ tree)
 * Output: path <site>_selected_features.csv
 */
process SELECT_FEATURES {
    tag "select_features_${site}"
    label 'oadr_cpep'
    publishDir "${params.outdir}/selected", mode: params.publish_mode

    input:
    val site
    path data_root

    output:
    path "*_selected_features.csv", emit: selected

    script:
    """
    oadr-cpep-cli select-features \
        --site ${site} \
        --panel ${params.panel} \
        --data-root ${data_root} \
        --seed ${params.seed}
    """
}
