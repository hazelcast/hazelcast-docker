FROM redhat/ubi9-minimal:9.3

# Used for image metadata only
# Describes the version of the Dockerfile, *not* the version of the bundled Hazelcast binary as this is/can be controlled externally
# Dockerfile needs some concept of versioning so that the release pipeline can tag/archive with an appropriate label
ARG HZ_VERSION=5.5.0-SNAPSHOT
ARG JDK_VERSION="21"

# Build constants
ARG HZ_HOME="/opt/hazelcast"
ARG USER_NAME="hazelcast"
# Optional, defaults to latest released version
ARG HAZELCAST_ZIP_URL=""

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

# Expose port
EXPOSE 5701

COPY licenses /licenses
COPY *.jar hazelcast-*.zip maven.functions.sh ${HZ_HOME}/

# Install
RUN echo "Installing new packages" \
    && microdnf -y update --nodocs \
    && microdnf -y --nodocs --disablerepo=* --enablerepo=ubi-9-appstream-rpms --enablerepo=ubi-9-baseos-rpms \
        --disableplugin=subscription-manager install shadow-utils java-${JDK_VERSION}-openjdk-headless zip tar tzdata-java util-linux \
    && if [[ ! -f ${HZ_HOME}/hazelcast-enterprise-distribution.zip ]]; then \
        if [ -z ${HAZELCAST_ZIP_URL} ]; then \
            source ${HZ_HOME}/maven.functions.sh; \
            HAZELCAST_ZIP_URL="$(get_latest_url_without_extension com.hazelcast hazelcast-enterprise-distribution https://repository.hazelcast.com/release)".zip; \
        fi; \
        echo "Downloading Hazelcast distribution zip from ${HAZELCAST_ZIP_URL}..."; \
        mkdir --parents ${HZ_HOME}; \
        curl --fail --silent --show-error --location ${HAZELCAST_ZIP_URL} --output ${HZ_HOME}/hazelcast-enterprise-distribution.zip; \
    else \
           echo "Using local hazelcast-enterprise-distribution.zip"; \
    fi \
    && unzip -qq ${HZ_HOME}/hazelcast-enterprise-distribution.zip 'hazelcast-*/**' -d ${HZ_HOME}/tmp/ \
    && mv ${HZ_HOME}/tmp/*/* ${HZ_HOME}/ \
    && echo "Setting Pardot ID to 'docker'" \
    && echo 'hazelcastDownloadId=docker' > "${HZ_HOME}/lib/hazelcast-download.properties" \
    && echo "Granting read permission to ${HZ_HOME}" \
    && chmod -R +r ${HZ_HOME} \
    && echo "Removing cached package data and unnecessary tools" \
    && microdnf -y remove zip unzip \
    && microdnf -y clean all \
    && rm -rf ${HZ_HOME}/maven.functions.sh ${HZ_HOME}/hazelcast-enterprise-distribution.zip maven.functions.sh${HZ_HOME}/tmp \
    # Grant execute permission to scripts in order to address the issue of permissions not being accurately propagated on Windows OS
    && chmod +x ${HZ_HOME}/bin/*

COPY log4j2.properties log4j2-json.properties jmx_agent_config.yaml ${HZ_HOME}/config/

RUN echo "Adding non-root user" \
    && groupadd --system hazelcast \
    && useradd --no-log-init --system --gid hazelcast --create-home ${USER_NAME}

WORKDIR ${HZ_HOME}

### Switch to hazelcast user
USER ${USER_NAME}

# Start Hazelcast server
CMD ["hz", "start"]
