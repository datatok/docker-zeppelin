ARG zeppelin_version

FROM apache/zeppelin:${zeppelin_version} AS zeppelin-distribution

##
# Download python & R dependencies
# See https://jcristharif.com/conda-docker-tips.html
# See https://pythonspeed.com/articles/conda-docker-image-size/
##
FROM continuumio/miniconda3:4.12.0 AS conda-packages
#FROM condaforge/mambaforge:4.12.0-2

ENV PYTHONDONTWRITEBYTECODE=true

COPY conda_packages.txt /conda_packages.txt
COPY env_zep.yaml /env_zep.yaml

# Setup manba
RUN set -ex && \
    conda config --set always_yes yes --set changeps1 no && \
    conda info -a && \
    conda config --add channels conda-forge && \
    conda install -c conda-forge mamba && \
    conda install -c main conda-pack

# Install python and R packages via conda
RUN set -ex && \
    mamba env create -f /env_zep.yaml

# Package all dependencies to get rid of conda
RUN conda pack \
        --exclude *.js.map \
        --exclude *.pyc \
        --exclude *.a \
        --name python_3_with_R \
        --ignore-missing-files \
        --dest-prefix /opt/conda/envs/python_3_with_R \
        --output /python_3_with_R.tar.gz \
        --quiet

##
# The final image
##
FROM ubuntu:20.04

ARG zeppelin_version

ENV JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64 \
    VERSION="${zeppelin_version}" \
    HOME="/opt/zeppelin" \
    ZEPPELIN_HOME="/opt/zeppelin" \
    IPYTHONDIR="/opt/zeppelin/ipython" \
    ZEPPELIN_ADDR="0.0.0.0" \
    ZEPPELIN_WAR_TEMPDIR="/tmp/webapps" \
    ZEPPELIN_USER_NAME=zeppelin \
    ZEPPELIN_USER_UID=1000 \
    PATH=/opt/conda/envs/python_3_with_R/bin:$PATH

RUN set -ex && \
    mkdir -p /etc/ssl/certs/java && \
    apt-get -y -qq update && \
    DEBIAN_FRONTEND=noninteractive apt-get -qq install -y \
        openjdk-8-jre-headless \
        wget \
        tini \
        curl \
        git \
    && \
    # Cleanup
    rm -rf /var/lib/apt/lists/* && \
    apt-get -qq autoclean && \
    apt-get -qq clean

COPY --from=zeppelin-distribution /opt/zeppelin/bin ${ZEPPELIN_HOME}/bin
COPY --from=zeppelin-distribution /opt/zeppelin/conf ${ZEPPELIN_HOME}/conf
COPY --from=zeppelin-distribution /opt/zeppelin/interpreter/zeppelin-interpreter-shaded-${zeppelin_version}.jar ${ZEPPELIN_HOME}/interpreter/zeppelin-interpreter-shaded-${zeppelin_version}.jar

# copy k8s files
COPY --from=zeppelin-distribution /opt/zeppelin/k8s ${ZEPPELIN_HOME}/k8s

# copy some interpreters
COPY --from=zeppelin-distribution /opt/zeppelin/interpreter/spark ${ZEPPELIN_HOME}/interpreter/spark
COPY --from=zeppelin-distribution /opt/zeppelin/interpreter/md ${ZEPPELIN_HOME}/interpreter/md
COPY --from=zeppelin-distribution /opt/zeppelin/interpreter/sh ${ZEPPELIN_HOME}/interpreter/sh
COPY --from=zeppelin-distribution /opt/zeppelin/interpreter/r ${ZEPPELIN_HOME}/interpreter/r
COPY --from=zeppelin-distribution /opt/zeppelin/interpreter/jdbc ${ZEPPELIN_HOME}/interpreter/jdbc
COPY --from=zeppelin-distribution /opt/zeppelin/interpreter/python ${ZEPPELIN_HOME}/interpreter/python

# copy from conda
COPY --from=conda-packages /python_3_with_R.tar.gz /tmp/python_3_with_R.tar.gz

# Some python packages are not available via conda, so we are using pip
COPY pip_packages.txt /pip_packages.txt

# Install python & dependencies
RUN mkdir -p /opt/conda/envs/python_3_with_R && \
    tar -xzf /tmp/python_3_with_R.tar.gz -C /opt/conda/envs/python_3_with_R/ && \
    rm -rf /tmp/* && \
    pip3 install -q -r /pip_packages.txt

RUN mkdir -p "${ZEPPELIN_HOME}/logs" "${ZEPPELIN_HOME}/run" "${ZEPPELIN_HOME}/local-repo" && \
     # Allow process to edit /etc/passwd, to create a user entry for zeppelin
    chgrp root /etc/passwd && chmod ug+rw /etc/passwd && \
    # Give access to some specific folders
    chmod -R 775 "${ZEPPELIN_HOME}/logs" "${ZEPPELIN_HOME}/run" "${ZEPPELIN_HOME}/local-repo"

# add zeppelin user
RUN useradd --home-dir ${ZEPPELIN_HOME} --no-create-home --uid ${ZEPPELIN_USER_UID} ${ZEPPELIN_USER_NAME} && \
    chown -R ${ZEPPELIN_USER_UID} ${ZEPPELIN_HOME}

USER ${ZEPPELIN_USER_UID}

ENTRYPOINT [ "/usr/bin/tini", "--" ]

WORKDIR ${ZEPPELIN_HOME}