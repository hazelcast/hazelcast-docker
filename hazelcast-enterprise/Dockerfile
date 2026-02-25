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
# set SOURCE_DATE_EPOCH to some fixed value to have reproducible timestamps in the image layer
ARG SOURCE_DATE_EPOCH=1234567890
ARG BUILD_ROOT=/build_root

FROM alpine:3 AS get-distribution

ARG HZ_HOME
ARG SOURCE_DATE_EPOCH
ARG HAZELCAST_ZIP_FILE_NAME="hazelcast-enterprise-distribution.zip"
ARG BUILD_ROOT

# Expects distribution ZIP to be on the local filesystem within the build context
COPY ${HAZELCAST_ZIP_FILE_NAME} /tmp/

RUN mkdir -p ${BUILD_ROOT}${HZ_HOME} \
    && apk add --no-cache unzip \
    && unzip -qq /tmp/${HAZELCAST_ZIP_FILE_NAME} -d /tmp/hz \
    # Distribution ZIP structure is a single folder (e.g. "hazelcast-5.4.0-slim") containing the content
    # Move all the content up a level so that the path contains no version and is constant
    && mv /tmp/hz/*/* ${BUILD_ROOT}${HZ_HOME}/ \
    && apk del unzip \
    && rm -rf /tmp/* \
    && echo "Setting Pardot ID to 'docker'" \
    && echo 'hazelcastDownloadId=docker' > "${BUILD_ROOT}${HZ_HOME}/lib/hazelcast-download.properties" \
    && echo "Granting read permission to ${BUILD_ROOT}${HZ_HOME}" \
    && chmod -R +r ${BUILD_ROOT}${HZ_HOME} \
    && echo "Grant execute permission to scripts in order to address the issue of permissions not being accurately propagated on Windows OS" \
    && chmod +x ${BUILD_ROOT}${HZ_HOME}/bin/*

COPY log4j2.properties log4j2-json.properties jmx_agent_config.yaml ${BUILD_ROOT}${HZ_HOME}/config/

# Normalize timestamps for reproducible layer
RUN find ${BUILD_ROOT} -exec touch -h -d "@$SOURCE_DATE_EPOCH" {} +

FROM eclipse-temurin:${JDK_VERSION}-jre-ubi9-minimal

ARG HZ_HOME
ARG HZ_VERSION
ARG USER_NAME
ARG USER_GROUP
ARG SOURCE_DATE_EPOCH
ARG BUILD_ROOT

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
    PATH=${HZ_HOME}/bin:$PATH \
    SOURCE_DATE_EPOCH=${SOURCE_DATE_EPOCH}

LABEL name="Hazelcast Enterprise" \
      maintainer="info@hazelcast.com" \
      vendor="Hazelcast, Inc." \
      version="${HZ_VERSION}" \
      release="1" \
      summary="Hazelcast Enterprise Image" \
      description="Hazelcast Enterprise Image"

# Expose port
EXPOSE 5701

COPY licenses /licenses

COPY --link --from=get-distribution ${BUILD_ROOT}/ /

RUN touch /tmp/.timestamp-marker && sleep 1 \
    && echo "Adding non-root user" \
    && groupadd --system ${USER_GROUP} \
    && useradd --no-log-init --system --gid ${USER_GROUP} --create-home ${USER_NAME} \
    && chage --lastday 0 ${USER_NAME} \
    && echo "Upgrading packages" \
    && microdnf -y update --nodocs \
    && echo "Removing unnecessary packages and redundant files/folders" \
    && microdnf -y clean all \
    && truncate --size 0 /var/cache/ldconfig/aux-cache \
    && truncate --size 0 /var/lib/dnf/history.sqlite* \
    && echo "Fixing non-deterministic files for reproducibility" \
    && find / -newer /tmp/.timestamp-marker -xdev \
            -exec touch -h -d "@$SOURCE_DATE_EPOCH" {} + 2>/dev/null \
    && rm -f /tmp/.timestamp-marker \
    && touch -d "@${SOURCE_DATE_EPOCH}" /tmp


WORKDIR ${HZ_HOME}

USER ${USER_NAME}

HEALTHCHECK CMD ["hz-healthcheck"]

# Start Hazelcast server
CMD ["hz", "start"]
