/**
 * Phase 2 (site) — fit the analytical methods on the consensus features.
 *
 * Runs oadr-cpep-cli fit-models: Ridge, LASSO, and Random Forest on the
 * coordinator's consensus feature list. LASSO selection is NOT repeated. Emits
 * coefficient vectors (Ridge, LASSO) and the trained forest (RF); no
 * subject-level data leaves the site.
 *
 * Input : val site, path data, path consensus_features.csv
 * Output: path *_vector.csv (coefficient vectors), path *_rf.pkl (forest)
 */
process FIT_MODELS {
    tag "fit_models_${site}"
    label 'oadr_cpep'
    publishDir "${params.outdir}/vectors", mode: params.publish_mode

    input:
    val site
    path data
    path features

    output:
    path "*_vector.csv", emit: vectors
    path "*_rf.pkl",     emit: forest

    script:
    """
    oadr-cpep-cli fit-models \\
        --data ${data} \\
        --features ${features} \\
        --site ${site} \\
        --target ${params.target} \\
        --ridge-alpha ${params.ridge_alpha} \\
        --lasso-alpha ${params.lasso_alpha} \\
        --n-trees ${params.n_trees} \\
        --seed ${params.seed} \\
        --outdir .
    """
}
