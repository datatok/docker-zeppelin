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
        spark md sh \
        zeppelin-interpreter-shaded-${zeppelin_version}.jar \
        ${ZEPPELIN_HOME}/interpreter/

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

# add zeppelin user
RUN useradd --home-dir ${ZEPPELIN_HOME} --no-create-home --uid ${ZEPPELIN_USER_UID} ${ZEPPELIN_USER_NAME} # && \
    # Allow process to edit /etc/passwd, to create a user entry for zeppelin
    chgrp root /etc/passwd && chmod ug+rw /etc/passwd

# copy zeppelin files
COPY    --from=my-distribution \
        --chown=${ZEPPELIN_USER_UID}:${ZEPPELIN_USER_UID} \
        ${ZEPPELIN_HOME} \
        ${ZEPPELIN_HOME}

USER ${ZEPPELIN_USER_UID}

ENTRYPOINT [ "/usr/bin/tini", "--" ]

WORKDIR ${ZEPPELIN_HOME}