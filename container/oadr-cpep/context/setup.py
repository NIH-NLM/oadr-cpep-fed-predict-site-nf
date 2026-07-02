from setuptools import setup, find_packages

setup(
    name="oadr-cpep-cli",
    version="0.1.0",
    description="Federated prediction of residual beta-cell function (C-peptide AUC)",
    author="NIH-NLM / Anne Deslattes Mays",
    package_dir={"": "src"},
    packages=find_packages(where="src"),
    python_requires=">=3.10",
    install_requires=["numpy", "pandas", "scikit-learn", "scipy"],
    entry_points={"console_scripts": ["oadr-cpep-cli=oadr_cpep_cli.cli:main"]},
)
