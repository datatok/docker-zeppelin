ARG zeppelin_version

FROM apache/zeppelin:${zeppelin_version} AS zeppelin-distribution

##
# Create own distribution:
# - copy all server stuff
# - copy some interpreters, keep only settings.json files
##
FROM alpine:3.16.0 AS my-distribution

ARG zeppelin_version

ENV ZEPPELIN_HOME=/opt/zeppelin

COPY --from=zeppelin-distribution /opt/zeppelin /tmp 
COPY zeppelin.sh /tmp/bin/

RUN \
    mkdir -p ${ZEPPELIN_HOME} && cd ${ZEPPELIN_HOME} && \
    mkdir -p \
        logs run notebook local-repo interpreter plugins/Launcher plugins/NotebookRepo && \
    chmod -R 775 \
        logs run notebook && \
    \
    cd /tmp && \
    cp  -r \
        zeppelin-web-${zeppelin_version}.war \
        zeppelin-web-angular-${zeppelin_version}.war \
        conf lib bin k8s \
        ${ZEPPELIN_HOME}/ && \
    cp -r \
        interpreter/spark \
        interpreter/python \
        interpreter/r \
        interpreter/jdbc \
        interpreter/md \
        interpreter/sh \
        ${ZEPPELIN_HOME}/interpreter/ && \
    cp -r   plugins/Launcher/K8sStandardInterpreterLauncher \
            ${ZEPPELIN_HOME}/plugins/Launcher/K8sStandardInterpreterLauncher && \
    cp -r   plugins/NotebookRepo/FileSystemNotebookRepo \
            ${ZEPPELIN_HOME}/plugins/NotebookRepo/FileSystemNotebookRepo && \
    find ${ZEPPELIN_HOME}/interpreter -type f ! -iname "*.json" -delete

##
# The final image
##
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
     # Allow process to edit /etc/passwd, to create a user entry for zeppelin
    chgrp root /etc/passwd && chmod ug+rw /etc/passwd && \
    # Remove horrible file (downloaded to interpreter)
    rm -f /etc/krb5.conf

# Copy own distribution
COPY    --from=my-distribution \
        --chown=${ZEPPELIN_USER_UID}:${ZEPPELIN_USER_UID} \
        /opt/zeppelin /opt/zeppelin

USER ${ZEPPELIN_USER_UID}

EXPOSE 8080

ENTRYPOINT ["/sbin/tini", "--"]

WORKDIR ${ZEPPELIN_HOME}

CMD ["bin/zeppelin.sh"]