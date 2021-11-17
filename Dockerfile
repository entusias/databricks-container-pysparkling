FROM ubuntu:20.04.3 as builder

RUN apt update && apt install wget -y

RUN wget https://repo.anaconda.com/miniconda/Miniconda3-py39_4.10.3-Linux-x86_64.sh \
    && echo '1ea2f885b4dbc3098662845560bc64271eb17085387a70c2ba3f29fff6f8d52f  Miniconda3-py39_4.10.3-Linux-x86_64.sh' \
       | sha256sum -c
    && /bin/bash Miniconda3-py39_4.10.3-Linux-x86_64.sh -b -p /databricks/conda \
    && /databricks/conda/bin/conda install --name base conda=4.10.3

FROM databricksruntime/minimal:9.x

COPY --from:builder /databricks/conda /databricks/conda
COPY config/env.yml /databricks/.conda-env-def/env.yml

RUN /databricks/conda/bin/conda env create --file /databricks/.conda-env-def/env.yml \
    # Source conda.sh for all login shells.
    && ln -s /databricks/conda/etc/profile.d/conda.sh /etc/profile.d/conda.sh

# Conda recommends using strict channel priority speed up conda operations and reduce package incompatibility problems.
# Set always_yes to avoid needing -y flags, and improve conda experience in Databricks notebooks.
RUN /databricks/conda/bin/conda config --system --set channel_priority strict \
    && /databricks/conda/bin/conda config --system --set always_yes True

# This environment variable must be set to indicate the conda environment to activate.
# Note that currently, we have to set both of these environment variables. The first one is necessary to indicate that this runtime supports conda.
# The second one is necessary so that the python notebook/repl can be started (won't work without it)
ENV DEFAULT_DATABRICKS_ROOT_CONDA_ENV=dcs-pysparkling
ENV DATABRICKS_ROOT_CONDA_ENV=dcs-pysparkling
ENV PYSPARK_PYTHON=/databricks/conda/envs/dcs-pysparkling/bin/python




