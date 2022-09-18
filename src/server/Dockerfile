ARG zeppelin_version

FROM apache/zeppelin:${zeppelin_version} AS zeppelin-distribution

##
# Copy interpreter settings.json
##
FROM alpine:3.16.0 AS interpreters

ENV ZEPPELIN_HOME="/opt/zeppelin"

# copy some interpreters
COPY --from=zeppelin-distribution /opt/zeppelin/interpreter/spark ${ZEPPELIN_HOME}/interpreter/spark
COPY --from=zeppelin-distribution /opt/zeppelin/interpreter/md ${ZEPPELIN_HOME}/interpreter/md
COPY --from=zeppelin-distribution /opt/zeppelin/interpreter/sh ${ZEPPELIN_HOME}/interpreter/sh
COPY --from=zeppelin-distribution /opt/zeppelin/interpreter/r ${ZEPPELIN_HOME}/interpreter/r
COPY --from=zeppelin-distribution /opt/zeppelin/interpreter/jdbc ${ZEPPELIN_HOME}/interpreter/jdbc
COPY --from=zeppelin-distribution /opt/zeppelin/interpreter/python ${ZEPPELIN_HOME}/interpreter/python

RUN find . -type f ! -iname "*.json" -delete

FROM alpine:3.16.0

ARG zeppelin_version

RUN apk add --no-cache --update \
        tini \
        openjdk8-jre \
        bash \
    && \
        rm -rf /var/cache

ENV LANG=en_US.UTF-8 \
    LC_ALL=en_US.UTF-8 \
    JAVA_HOME=/usr/lib/jvm/java-1.8-openjdk \
    VERSION="${zeppelin_version}" \
    HOME="/opt/zeppelin" \
    ZEPPELIN_HOME="/opt/zeppelin" \
    ZEPPELIN_ADDR="0.0.0.0" \
    ZEPPELIN_WAR_TEMPDIR="/tmp/webapps" \
    ZEPPELIN_USER_NAME=zeppelin \
    ZEPPELIN_USER_UID=1000

# add zeppelin user
RUN adduser --home ${ZEPPELIN_HOME} --no-create-home --disabled-password --uid ${ZEPPELIN_USER_UID} ${ZEPPELIN_USER_NAME} && \
    mkdir -p "${ZEPPELIN_HOME}/logs" "${ZEPPELIN_HOME}/run" "${ZEPPELIN_HOME}/notebook" "${ZEPPELIN_HOME}/local-repo" && \
     # Allow process to edit /etc/passwd, to create a user entry for zeppelin
    chgrp root /etc/passwd && chmod ug+rw /etc/passwd && \
    # Give access to some specific folders
    chmod -R 775 "${ZEPPELIN_HOME}/logs" "${ZEPPELIN_HOME}/run" "${ZEPPELIN_HOME}/notebook" "${ZEPPELIN_HOME}/local-repo" && \
    chown -R ${ZEPPELIN_USER_UID} ${ZEPPELIN_HOME} && \
    # user "zeppelin" cant write to /etc, delete this unused file to prevent download from remote interpreter
    rm -f /etc/krb5.conf

# Copy Zeppelin related files
COPY --from=zeppelin-distribution --chown=${ZEPPELIN_USER_UID} /opt/zeppelin/zeppelin-web-${zeppelin_version}.war ${ZEPPELIN_HOME}/
COPY --from=zeppelin-distribution --chown=${ZEPPELIN_USER_UID} /opt/zeppelin/zeppelin-web-angular-${zeppelin_version}.war ${ZEPPELIN_HOME}/
COPY --from=zeppelin-distribution --chown=${ZEPPELIN_USER_UID} /opt/zeppelin/conf ${ZEPPELIN_HOME}/conf
COPY --from=zeppelin-distribution --chown=${ZEPPELIN_USER_UID} /opt/zeppelin/bin ${ZEPPELIN_HOME}/bin
COPY --from=zeppelin-distribution --chown=${ZEPPELIN_USER_UID} /opt/zeppelin/lib ${ZEPPELIN_HOME}/lib
COPY --from=zeppelin-distribution --chown=${ZEPPELIN_USER_UID} /opt/zeppelin/k8s ${ZEPPELIN_HOME}/k8s

# Copy some plugins
COPY --from=zeppelin-distribution --chown=${ZEPPELIN_USER_UID} \
        /opt/zeppelin/plugins/Launcher/K8sStandardInterpreterLauncher \
        ${ZEPPELIN_HOME}/plugins/Launcher/K8sStandardInterpreterLauncher

COPY --from=zeppelin-distribution --chown=${ZEPPELIN_USER_UID} \
        /opt/zeppelin/plugins/NotebookRepo/FileSystemNotebookRepo \
        ${ZEPPELIN_HOME}/plugins/NotebookRepo/FileSystemNotebookRepo

# Copy interpreters settings.json
COPY --from=interpreters --chown=${ZEPPELIN_USER_UID} /opt/zeppelin/interpreter /opt/zeppelin/interpreter

ADD zeppelin.sh ${ZEPPELIN_HOME}/bin/

USER ${ZEPPELIN_USER_UID}

EXPOSE 8080

ENTRYPOINT ["/sbin/tini", "--"]

WORKDIR ${ZEPPELIN_HOME}

CMD ["bin/zeppelin.sh"]