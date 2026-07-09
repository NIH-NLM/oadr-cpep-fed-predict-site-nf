/**
 * Phase 1 (site) — LASSO feature selection.
 *
 * Runs `oadr-cpep select-features` on this institution's own data (loaded via the
 * embedded oadr_data loader; --site = study, --panel A|B). Data files are staged
 * FLAT into the work dir. Emits the selected-features list (feeds the aggregator)
 * and the full LASSO result; no subject-level data leaves the site.
 *
 * Input : val site (study id), path data_files (flat, staged)
 * Output: path <site>_panel<X>_selected_features.csv, <site>_panel<X>_lasso_selection.csv
 */
process SELECT_FEATURES {
    tag "select_features_${site}"
    label 'oadr_cpep'
    containerOptions '--entrypoint ""'
    publishDir "${params.outdir}/selected", mode: params.publish_mode

    input:
    val site
    path data_files

    output:
    path "*_selected_features.csv", emit: selected
    path "*_lasso_selection.csv",   emit: full

    script:
    """
    oadr-cpep select-features \
        --site ${site} \
        --panel ${params.panel} \
        --seed ${params.seed}
    """
}
