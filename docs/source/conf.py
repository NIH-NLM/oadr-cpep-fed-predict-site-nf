project   = 'oadr-cpep-fed-predict-site-nf'
copyright = '2026, NIH-NLM'
author    = 'NIH-NLM'
release   = '0.1.0'

extensions = [
    'myst_parser',
    'sphinx.ext.viewcode',
]

# .rst (generated Nextflow module pages) + .md (the README, via myst_parser)
source_suffix = {
    '.rst': 'restructuredtext',
    '.md':  'markdown',
}

templates_path   = ['_templates']
exclude_patterns = ['_build', 'Thumbs.db', '.DS_Store']

html_theme       = 'sphinx_rtd_theme'
html_static_path = ['_static']
