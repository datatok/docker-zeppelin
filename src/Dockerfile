ARG zeppelin_version

FROM apache/zeppelin:${zeppelin_version} AS zeppelin-distribution

FROM alpine:3.16.0

ARG zeppelin_version
ARG http_proxy_ip
ARG http_proxy_port
ARG http_proxy
ARG https_proxy

LABEL org.opencontainers.image.authors="Thomas Decaux"
LABEL org.opencontainers.image.vendor="datatok"
LABEL org.opencontainers.image.source="https://github.com/datatok/docker-zeppelin"
LABEL org.opencontainers.image.version=${zeppelin_version}

RUN apk add --no-cache tini curl wget git openjdk8-jre bash

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

# Copy Zeppelin related files
COPY --from=zeppelin-distribution /opt/zeppelin/zeppelin-web-${zeppelin_version}.war ${ZEPPELIN_HOME}/
COPY --from=zeppelin-distribution /opt/zeppelin/zeppelin-web-angular-${zeppelin_version}.war ${ZEPPELIN_HOME}/
COPY --from=zeppelin-distribution /opt/zeppelin/conf ${ZEPPELIN_HOME}/conf
COPY --from=zeppelin-distribution /opt/zeppelin/bin ${ZEPPELIN_HOME}/bin
COPY --from=zeppelin-distribution /opt/zeppelin/lib ${ZEPPELIN_HOME}/lib
COPY --from=zeppelin-distribution /opt/zeppelin/plugins ${ZEPPELIN_HOME}/plugins
COPY --from=zeppelin-distribution /opt/zeppelin/interpreter/zeppelin-interpreter-shaded-${zeppelin_version}.jar ${ZEPPELIN_HOME}/interpreter/zeppelin-interpreter-shaded-${zeppelin_version}.jar

# copy k8s files
COPY --from=zeppelin-distribution /opt/zeppelin/k8s ${ZEPPELIN_HOME}/k8s

# copy some interpreters
COPY --from=zeppelin-distribution /opt/zeppelin/interpreter/spark ${ZEPPELIN_HOME}/interpreter/spark
COPY --from=zeppelin-distribution /opt/zeppelin/interpreter/md ${ZEPPELIN_HOME}/interpreter/md
COPY --from=zeppelin-distribution /opt/zeppelin/interpreter/sh ${ZEPPELIN_HOME}/interpreter/sh

RUN mkdir -p "${ZEPPELIN_HOME}/logs" "${ZEPPELIN_HOME}/run" "${ZEPPELIN_HOME}/notebook" "${ZEPPELIN_HOME}/local-repo" && \
     # Allow process to edit /etc/passwd, to create a user entry for zeppelin
    chgrp root /etc/passwd && chmod ug+rw /etc/passwd && \
    # Give access to some specific folders
    chmod -R 775 "${ZEPPELIN_HOME}/logs" "${ZEPPELIN_HOME}/run" "${ZEPPELIN_HOME}/conf" "${ZEPPELIN_HOME}/notebook" "${ZEPPELIN_HOME}/local-repo"

# add zeppelin user
RUN adduser --home ${ZEPPELIN_HOME} --no-create-home --disabled-password --uid ${ZEPPELIN_USER_UID} ${ZEPPELIN_USER_NAME} && \
    chown -R ${ZEPPELIN_USER_UID} ${ZEPPELIN_HOME}

ADD zeppelin.sh ${ZEPPELIN_HOME}/bin/

USER ${ZEPPELIN_USER_UID}

EXPOSE 8080

ENTRYPOINT ["/sbin/tini", "--"]

WORKDIR ${ZEPPELIN_HOME}

CMD ["bin/zeppelin.sh"]