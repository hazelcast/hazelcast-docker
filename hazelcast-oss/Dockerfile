# syntax=docker/dockerfile:1.7

# Used for image metadata only
# Describes the version of the Dockerfile, *not* the version of the bundled Hazelcast binary as this is/can be controlled externally
# Dockerfile needs some concept of versioning so that the release pipeline can tag/archive with an appropriate label
ARG HZ_VERSION=5.7.0-SNAPSHOT

# Build constants
ARG HZ_HOME="/opt/hazelcast"
ARG USER_NAME="hazelcast"
ARG USER_GROUP="hazelcast"
ARG JDK_VERSION="21"

FROM alpine:3 AS get-distribution

ARG HZ_HOME
ARG HAZELCAST_ZIP_FILE_NAME="hazelcast-distribution.zip"

# Expects distribution ZIP to be on the local filesystem within the build context
COPY ${HAZELCAST_ZIP_FILE_NAME} /tmp/

RUN mkdir -p /build_root${HZ_HOME} \
    && apk add --no-cache unzip \
    && unzip -qq /tmp/${HAZELCAST_ZIP_FILE_NAME} -d /tmp/hz \
    # Distribution ZIP structure is a single folder (e.g. "hazelcast-5.4.0-slim") containing the content
    # Move all the content up a level so that the path contains no version and is constant
    && mv /tmp/hz/*/* /build_root${HZ_HOME}/ \
    && apk del unzip \
    && rm -rf /tmp/* \
    && echo "Setting Pardot ID to 'docker'" \
    && echo 'hazelcastDownloadId=docker' > "/build_root${HZ_HOME}/lib/hazelcast-download.properties" \
    && echo "Granting read permission to /build_root${HZ_HOME}" \
    && chmod -R +r /build_root${HZ_HOME} \
    && echo "Grant execute permission to scripts in order to address the issue of permissions not being accurately propagated on Windows OS" \
    && chmod +x /build_root${HZ_HOME}/bin/*

COPY log4j2.properties log4j2-json.properties jmx_agent_config.yaml /build_root${HZ_HOME}/config/

# Normalize timestamps for reproducible layer
RUN find /build_root -exec touch -h -t 202307011700.00 {} +

FROM eclipse-temurin:${JDK_VERSION}-jre-alpine

ARG HZ_HOME
ARG USER_NAME
ARG USER_GROUP

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

COPY --link --from=get-distribution /build_root/ /

# Install
RUN echo "Upgrading packages" \
    && apk upgrade --no-cache \
    && echo "Installing new packages" \
    && apk add --no-cache \
        bash \
        curl \
    && echo "Removing unnecessary packages and redundant files/folders" \
    && rm -rf /var/cache/apk/* 

WORKDIR ${HZ_HOME}

RUN echo "Adding non-root user" \
    && addgroup -S ${USER_GROUP} \
    && adduser -S ${USER_NAME} -G ${USER_GROUP}
USER ${USER_NAME}

HEALTHCHECK CMD ["hz-healthcheck"]

# Start Hazelcast server
CMD ["hz", "start"]
