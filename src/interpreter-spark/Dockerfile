ARG zeppelin_version

FROM apache/zeppelin:${zeppelin_version} AS zeppelin-distribution

FROM ubuntu:20.04

ARG zeppelin_version

ENV JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64 \
    VERSION="${zeppelin_version}" \
    HOME="/opt/zeppelin" \
    ZEPPELIN_HOME="/opt/zeppelin" \
    ZEPPELIN_ADDR="0.0.0.0" \
    ZEPPELIN_WAR_TEMPDIR="/tmp/webapps" \
    ZEPPELIN_USER_NAME=zeppelin \
    ZEPPELIN_USER_UID=1000

RUN set -ex && \
    apt-get -y update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y openjdk-8-jre-headless wget tini curl git && \
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