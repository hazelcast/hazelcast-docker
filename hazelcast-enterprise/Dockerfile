# Used for image metadata only
# Describes the version of the Dockerfile, *not* the version of the bundled Hazelcast binary as this is/can be controlled externally
# Dockerfile needs some concept of versioning so that the release pipeline can tag/archive with an appropriate label
ARG HZ_VERSION=5.7.0-SNAPSHOT

# Build constants
ARG HZ_HOME="/opt/hazelcast"

FROM scratch AS get-distribution

ARG HZ_HOME
ARG HAZELCAST_DISTRIBUTION_FILE_NAME="hazelcast-enterprise-distribution.tar.gz"

# Expects distribution file to be on the local filesystem within the build context
ADD ${HAZELCAST_DISTRIBUTION_FILE_NAME} /tmp/hz


FROM redhat/ubi9-minimal:9.7

ARG HZ_VERSION
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

LABEL name="Hazelcast Enterprise" \
      maintainer="info@hazelcast.com" \
      vendor="Hazelcast, Inc." \
      version="${HZ_VERSION}" \
      release="1" \
      summary="Hazelcast Enterprise Image" \
      description="Hazelcast Enterprise Image"

COPY licenses /licenses
COPY --from=get-distribution /tmp/hz/ /tmp/hz/

# Install
RUN echo "Upgrading packages" \
    && echo "Removing unnecessary packages and redundant files/folders" \
    && microdnf -y clean all \
    && mkdir -p ${HZ_HOME} \
    # Distribution archive structure is a single folder (e.g. "hazelcast-5.4.0-slim") containing the content
    # Move all the content up a level so that the path contains no version and is constant
    && mv /tmp/hz/*/* ${HZ_HOME}/ \
    && rm -rf /tmp/* \
    && echo "Setting Pardot ID to 'docker'" \
    && echo 'hazelcastDownloadId=docker' > "${HZ_HOME}/lib/hazelcast-download.properties" \
    && echo "Granting read permission to ${HZ_HOME}" \
    && chmod -R +r ${HZ_HOME} \
    && echo "Grant execute permission to scripts in order to address the issue of permissions not being accurately propagated on Windows OS" \
    && chmod +x ${HZ_HOME}/bin/*
