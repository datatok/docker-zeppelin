ARG zeppelin_version

FROM apache/zeppelin:${zeppelin_version} AS zeppelin-distribution

##
# Create own distribution:
# - copy all interpreter stuff
##
FROM alpine:3.16.0 AS my-distribution

ARG zeppelin_version

ENV ZEPPELIN_HOME=/opt/zeppelin

COPY --from=zeppelin-distribution /opt/zeppelin /tmp 

RUN \
    mkdir -p ${ZEPPELIN_HOME} && cd ${ZEPPELIN_HOME} && \
    mkdir -p \
        logs run notebook local-repo interpreter && \
    chmod -R 775 \
        logs run notebook && \
    \
    cd /tmp && \
    cp  -r \
        conf lib bin k8s \
        ${ZEPPELIN_HOME}/ && \
    cd interpreter && cp -r \
        spark python r jdbc md sh \
        zeppelin-interpreter-shaded-${zeppelin_version}.jar \
        ${ZEPPELIN_HOME}/interpreter/


##
# Download python & R dependencies
# See https://jcristharif.com/conda-docker-tips.html
# See https://pythonspeed.com/articles/conda-docker-image-size/
##
FROM condaforge/mambaforge:4.13.0-1 AS conda-packages

ENV PYTHONDONTWRITEBYTECODE=true

COPY env_zep.yaml /env_zep.yaml

# Setup conda
RUN set -ex && \
    conda config --set always_yes yes --set changeps1 no && \
    conda info -a && \
    conda config --add channels conda-forge

# Install python and R packages
RUN --mount=type=cache,target=/opt/conda/pkgs \
    mamba env create \
        -p /opt/conda/envs/python_3_with_R \
        --quiet \
        --file /env_zep.yaml

# Some python packages are not available via conda, so we are using pip
COPY pip_packages.txt /pip_packages.txt

RUN conda run -p /opt/conda/envs/python_3_with_R python -m pip install -q -r /pip_packages.txt

# Clean in a separate layer as calling conda still generates some __pycache__ files
RUN cd /opt/conda/envs/python_3_with_R && \
        find -name '*.a' -delete && \
        find -name '__pycache__' -type d -exec rm -rf '{}' '+' && \
        rm -rf \
            conda-meta \
            include \
            lib/libasan.so.5.0.0 \
            lib/libtsan.so.0.0.0 \
            lib/liblsan.so.0.0.0 \
            lib/libubsan.so.1.0.0 \
            bin/x86_64-conda-linux-gnu-ld \
            bin/sqlite3 \
            bin/openssl \
            share/terminfo && \
        cd lib/python3.8 && \
            [ -d site-packages/scipy ] && find site-packages/scipy -name 'tests' -type d -exec rm -rf '{}' '+' && \
            [ -d site-packages/numpy ] && find site-packages/numpy -name 'tests' -type d -exec rm -rf '{}' '+' && \
            [ -d site-packages/pandas ] && find site-packages/pandas -name 'tests' -type d -exec rm -rf '{}' '+' && \
            find site-packages -name '*.pyx' -delete && \
            rm -rf /site-packages/pip idlelib ensurepip

##
# The final image
##
FROM ubuntu:20.04

RUN set -ex && \
    mkdir -p /etc/ssl/certs/java && \
    apt-get -y -qq update && \
    DEBIAN_FRONTEND=noninteractive apt-get -qq install -y \
        openjdk-8-jre-headless \
        tini \
        curl \
    && \
    # Cleanup
    apt-get -qq autoclean && \
    apt-get -qq clean && \
    rm -rf /var/cache/* /tmp/* /var/lib/apt

ARG zeppelin_version

ENV JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64 \
    VERSION="${zeppelin_version}" \
    HOME="/opt/zeppelin" \
    ZEPPELIN_HOME="/opt/zeppelin" \
    CONDA_HOME="/opt/conda" \
    IPYTHONDIR="/opt/zeppelin/ipython" \
    ZEPPELIN_ADDR="0.0.0.0" \
    ZEPPELIN_USER_NAME=zeppelin \
    ZEPPELIN_USER_UID=1000 \
    PATH=/opt/conda/envs/python_3_with_R/bin:/opt/conda/bin:$PATH

# add zeppelin user
RUN useradd --home-dir ${ZEPPELIN_HOME} --no-create-home --uid ${ZEPPELIN_USER_UID} ${ZEPPELIN_USER_NAME} && \
    # Allow process to edit /etc/passwd, to create a user entry for zeppelin
    chgrp root /etc/passwd && chmod ug+rw /etc/passwd

# copy zeppelin files
COPY    --from=my-distribution \
        --chown=${ZEPPELIN_USER_UID}:${ZEPPELIN_USER_UID} \
        ${ZEPPELIN_HOME} \
        ${ZEPPELIN_HOME}

# copy pack from conda
COPY    --from=conda-packages \
        --chown=${ZEPPELIN_USER_UID}:${ZEPPELIN_USER_UID} \
        /opt/conda/envs/python_3_with_R \
        /opt/conda/envs/python_3_with_R

USER ${ZEPPELIN_USER_UID}

ENTRYPOINT [ "/usr/bin/tini", "--" ]

WORKDIR ${ZEPPELIN_HOME}