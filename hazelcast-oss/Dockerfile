# Used for image metadata only
# Describes the version of the Dockerfile, *not* the version of the bundled Hazelcast binary as this is/can be controlled externally
# Dockerfile needs some concept of versioning so that the release pipeline can tag/archive with an appropriate label
ARG HZ_VERSION=5.7.0-SNAPSHOT

# Build constants
ARG HZ_HOME="/opt/hazelcast"
ARG USER_NAME="hazelcast"
ARG USER_GROUP="hazelcast"
ARG JDK_VERSION="21"
ARG BUILD_ROOT=/build_root

FROM alpine:3 AS get-distribution

ARG HZ_HOME
ARG HAZELCAST_ZIP_FILE_NAME="hazelcast-distribution.zip"
ARG BUILD_ROOT
ARG BUILD_HZ_HOME="${BUILD_ROOT}${HZ_HOME}"

# Expects distribution ZIP to be on the local filesystem within the build context
COPY ${HAZELCAST_ZIP_FILE_NAME} /tmp/

RUN mkdir -p ${BUILD_HZ_HOME} \
    && apk add --no-cache unzip \
    && unzip -qq /tmp/${HAZELCAST_ZIP_FILE_NAME} -d /tmp/hz \
    # Distribution ZIP structure is a single folder (e.g. "hazelcast-5.4.0-slim") containing the content
    # Move all the content up a level so that the path contains no version and is constant
    && mv /tmp/hz/*/* ${BUILD_HZ_HOME}/ \
    && apk del unzip \
    && rm -rf /tmp/* \
    && echo "Setting Pardot ID to 'docker'" \
    && echo 'hazelcastDownloadId=docker' > "${BUILD_HZ_HOME}/lib/hazelcast-download.properties" \
    && echo "Granting read permission to ${BUILD_HZ_HOME}" \
    && chmod -R +r ${BUILD_HZ_HOME} \
    && echo "Grant execute permission to scripts in order to address the issue of permissions not being accurately propagated on Windows OS" \
    && chmod +x ${BUILD_HZ_HOME}/bin/*

COPY log4j2.properties log4j2-json.properties jmx_agent_config.yaml ${BUILD_HZ_HOME}/config/

FROM alpine:3

ARG JDK_VERSION
ARG HZ_HOME
ARG USER_NAME
ARG USER_GROUP
ARG BUILD_ROOT
# apk/trust extract respect SOURCE_DATE_EPOCH for deterministic package database and cacerts content
ARG SOURCE_DATE_EPOCH

# Runtime variables
ENV HZ_HOME="${HZ_HOME}" \
    CLASSPATH_DEFAULT="${HZ_HOME}/*" \
    JAVA_OPTS_DEFAULT="-Djava.net.preferIPv4Stack=true -XX:MaxRAMPercentage=80.0" \
    PROMETHEUS_PORT="" \
    PROMETHEUS_CONFIG="${HZ_HOME}/config/jmx_agent_config.yaml" \
    CLASSPATH="" \
    JAVA_OPTS="" \
    HAZELCAST_CONFIG=config/hazelcast-docker.xml \
    LANG=C.UTF-8 \
    PATH=${HZ_HOME}/bin:$PATH

# Expose port
EXPOSE 5701

COPY --link --from=get-distribution ${BUILD_ROOT} /

RUN echo "Adding non-root user" \
    && addgroup -S ${USER_GROUP} \
    && adduser -S ${USER_NAME} -G ${USER_GROUP} \
    && echo "Installing new packages" \
    && apk add --no-cache --no-logfile \
        openjdk${JDK_VERSION}-jre-headless \
        bash \
        curl \
    && echo "Regenerating Java cacerts with SOURCE_DATE_EPOCH for reproducibility" \
    && trust extract --overwrite --format=java-cacerts --filter=ca-anchors \
        --purpose server-auth /etc/ssl/certs/java/cacerts

RUN echo "Upgrading packages" \
    && apk upgrade --no-cache --no-logfile

WORKDIR ${HZ_HOME}

USER ${USER_NAME}

HEALTHCHECK CMD ["hz-healthcheck"]

# Start Hazelcast server
CMD ["hz", "start"]
