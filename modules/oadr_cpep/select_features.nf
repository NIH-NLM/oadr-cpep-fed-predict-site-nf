/**
 * Phase 1 (site) — LASSO feature selection.
 *
 * Runs `oadr-cpep select-features` on this institution's own data. The data files
 * are passed EXPLICITLY (`data_args` = the `--aa/--demo/--cpeptide/…` flags built in
 * main.nf) and staged flat (`data_files`). Emits the selected-features list (which
 * feeds the fits via a channel, and the aggregator) and the full LASSO result;
 * no subject-level data leaves the site.
 *
 * Input : val site, val data_args (the --<file> flags), path data_files (staged)
 * Output: selected -> *_selected_features.csv ; full -> *_lasso_selection.csv
 */
process SELECT_FEATURES {
    tag "select_features_${site}"
    label 'oadr_cpep'
    containerOptions '--entrypoint ""'
    publishDir "${params.outdir}/selected", mode: params.publish_mode

    input:
    val site
    val data_args
    path data_files

    output:
    path "*_selected_features.csv", emit: selected
    path "*_lasso_selection.csv",   emit: full

    script:
    """
    oadr-cpep select-features \
        --site ${site} \
        --panel ${params.panel} \
        ${data_args} \
        --seed ${params.seed}
    """
}
