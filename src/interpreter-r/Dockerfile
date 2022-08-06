ARG zeppelin_version

FROM apache/zeppelin:${zeppelin_version} AS zeppelin-distribution

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
    PATH=/opt/conda/bin:$PATH

RUN set -ex && \
    mkdir -p /etc/ssl/certs/java && \
    apt-get -y update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y \
        openjdk-8-jre-headless \
        wget \
        tini \
        curl \
        git \
    && \
    # Cleanup
    rm -rf /var/lib/apt/lists/* && \
    apt-get autoclean && \
    apt-get clean

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


# Decide: Install conda to manage python and R packages. Maybe adjust the packages in pip_packages.txt or conda_packages.txt
ARG miniconda_version="py38_4.8.3"
ARG miniconda_sha256="879457af6a0bf5b34b48c12de31d4df0ee2f06a8e68768e5758c3293b2daf688"
# Install python and R packages via conda
COPY conda_packages.txt /conda_packages.txt
# Some python packages are not available via conda, so we are using pip
COPY pip_packages.txt /pip_packages.txt
RUN set -ex && \
    wget -nv https://repo.anaconda.com/miniconda/Miniconda3-${miniconda_version}-Linux-x86_64.sh -O miniconda.sh && \
    echo "${miniconda_sha256} miniconda.sh" > anaconda.sha256 && \
    sha256sum --strict -c anaconda.sha256 && \
    bash miniconda.sh -b -p /opt/conda && \
    conda config --set always_yes yes --set changeps1 no && \
    conda info -a && \
    conda config --add channels conda-forge && \
    conda install -y --quiet --file /conda_packages.txt && \
    pip install -q -r /pip_packages.txt  && \
    # Cleanup
    rm -v miniconda.sh anaconda.sha256  && \
    # Cleanup based on https://github.com/ContinuumIO/docker-images/commit/cac3352bf21a26fa0b97925b578fb24a0fe8c383
    find /opt/conda/ -follow -type f -name '*.a' -delete && \
    find /opt/conda/ -follow -type f -name '*.js.map' -delete && \
    conda clean -ay
    # Allow to modify conda packages. This allows malicious code to be injected into other interpreter sessions, therefore it is disabled by default
    # chmod -R ug+rwX /opt/conda

RUN mkdir -p "${ZEPPELIN_HOME}/logs" "${ZEPPELIN_HOME}/run" "${ZEPPELIN_HOME}/local-repo" && \
     # Allow process to edit /etc/passwd, to create a user entry for zeppelin
    chgrp root /etc/passwd && chmod ug+rw /etc/passwd && \
    # Give access to some specific folders
    chmod -R 775 "${ZEPPELIN_HOME}/logs" "${ZEPPELIN_HOME}/run" "${ZEPPELIN_HOME}/local-repo"

# add zeppelin user
RUN adduser --home ${ZEPPELIN_HOME} --no-create-home --disabled-password --uid ${ZEPPELIN_USER_UID} ${ZEPPELIN_USER_NAME} && \
    chown -R ${ZEPPELIN_USER_UID} ${ZEPPELIN_HOME}

USER ${ZEPPELIN_USER_UID}

ENTRYPOINT [ "/usr/bin/tini", "--" ]

WORKDIR ${ZEPPELIN_HOME}