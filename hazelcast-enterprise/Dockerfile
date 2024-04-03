FROM redhat/ubi8-minimal:8.7

# Versions of Hazelcast
ARG HZ_VERSION=5.3.7
# Variant - empty for full, "slim" for slim
ARG HZ_VARIANT=""

# Build constants
ARG HZ_HOME="/opt/hazelcast"
ARG USER_NAME="hazelcast"
ARG HAZELCAST_ZIP_URL=""

# Runtime variables
ENV HZ_HOME="${HZ_HOME}" \
    CLASSPATH_DEFAULT="${HZ_HOME}/*" \
    JAVA_OPTS_DEFAULT="-Djava.net.preferIPv4Stack=true -XX:MaxRAMPercentage=80.0 -XX:MaxGCPauseMillis=5" \
    PROMETHEUS_PORT="" \
    PROMETHEUS_CONFIG="${HZ_HOME}/config/jmx_agent_config.yaml" \
    CLASSPATH="" \
    JAVA_OPTS="" \
    HAZELCAST_CONFIG=config/hazelcast-docker.xml \
    LANG=C.UTF-8 \
    PATH=${HZ_HOME}/bin:$PATH

LABEL name="Hazelcast IMDG Enterprise" \
      maintainer="info@hazelcast.com" \
      vendor="Hazelcast, Inc." \
      version="${HZ_VERSION}" \
      release="1" \
      summary="Hazelcast IMDG Enterprise Image" \
      description="Hazelcast IMDG Enterprise Image"

# Expose port
EXPOSE 5701

COPY licenses /licenses
COPY *.jar get-hz-ee-dist-zip.sh hazelcast-*.zip ${HZ_HOME}/

# Install
RUN echo "Installing new packages" \
    && microdnf update --nodocs \
    && microdnf -y --nodocs --disablerepo=* --enablerepo=ubi-8-appstream-rpms --enablerepo=ubi-8-baseos-rpms \
        --disableplugin=subscription-manager install shadow-utils java-11-openjdk-headless zip tar tzdata-java \
    && if [[ ! -f ${HZ_HOME}/hazelcast-enterprise-distribution.zip ]]; then \
        HAZELCAST_ZIP_URL=$(${HZ_HOME}/get-hz-ee-dist-zip.sh); \
        echo "Downloading Hazelcast${HZ_VARIANT} distribution zip from $(echo $HAZELCAST_ZIP_URL | sed "s/?.*//g")..."; \
        curl -sf -L ${HAZELCAST_ZIP_URL} --output ${HZ_HOME}/hazelcast-enterprise-distribution.zip; \
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
    && microdnf remove zip unzip \
    && microdnf -y clean all \
    && rm -rf ${HZ_HOME}/get-hz-ee-dist-zip.sh ${HZ_HOME}/hazelcast-enterprise-distribution.zip ${HZ_HOME}/tmp \
    # Grant execute permission to scripts in order to address the issue of permissions not being accurately propagated on Windows OS
    && chmod +x ${HZ_HOME}/bin/*

COPY log4j2.properties log4j2-json.properties jmx_agent_config.yaml ${HZ_HOME}/config/

RUN echo "Adding non-root user" \
    && groupadd --system hazelcast \
    && useradd -l --system -g hazelcast -d ${HZ_HOME} ${USER_NAME}

WORKDIR ${HZ_HOME}

### Switch to hazelcast user
USER ${USER_NAME}

# Start Hazelcast server
CMD ["hz", "start"]
