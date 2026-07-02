# File: container/oadr-cpep/Dockerfile
# Self-contained image for the oadr-cpep-cli used by BOTH the site and the
# aggregator workflows. Build once, publish to a registry, reference from each
# workflow's nextflow.config.

FROM mambaorg/micromamba:1.5.6

LABEL maintainer="nih-nlm"
LABEL org.opencontainers.image.title="oadr-cpep-cli"
LABEL org.opencontainers.image.description="Federated prediction of residual beta-cell function"

USER root:root
RUN apt-get update && \
    apt-get install -y procps && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY context/oadr-cpep.yml /app/env.yml
RUN chown -R mambauser:mambauser /app

USER mambauser:mambauser
ENV MAMBA_ROOT_PREFIX=/opt/conda \
    PATH=/opt/conda/bin:$PATH \
    DEBIAN_FRONTEND=noninteractive

RUN micromamba install -y -n base -f /app/env.yml && \
    micromamba clean --all --yes

COPY context/setup.py /app/setup.py
COPY context/src /app/src
RUN python -m pip install --no-cache-dir /app

CMD ["oadr-cpep-cli", "--help"]
