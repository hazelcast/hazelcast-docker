FROM registry.access.redhat.com/ubi8/ubi-minimal:8.3

# Versions of Hazelcast
ARG HZ_VERSION=5.0-SNAPSHOT
# Variant - empty for full, "slim" for slim
ARG HZ_VARIANT=""

# Build constants
ARG HZ_HOME="/opt/hazelcast"
ARG USER_NAME="hazelcast"

# Runtime variables
ENV HZ_HOME="${HZ_HOME}" \
    CLASSPATH_DEFAULT="${HZ_HOME}/*:${HZ_HOME}/lib/*" \
    JAVA_OPTS_DEFAULT="-Djava.net.preferIPv4Stack=true -Dhazelcast.logging.type=log4j2 -Dlog4j.configurationFile=${HZ_HOME}/config/log4j2.properties -XX:MaxRAMPercentage=80.0 -XX:MaxGCPauseMillis=5 --add-modules java.se --add-exports java.base/jdk.internal.ref=ALL-UNNAMED --add-opens java.base/java.lang=ALL-UNNAMED --add-opens java.base/java.nio=ALL-UNNAMED --add-opens java.base/sun.nio.ch=ALL-UNNAMED --add-opens java.management/sun.management=ALL-UNNAMED --add-opens jdk.management/com.sun.management.internal=ALL-UNNAMED" \
    PROMETHEUS_PORT="" \
    PROMETHEUS_CONFIG="${HZ_HOME}/config/jmx_agent_config.yaml" \
    LOGGING_LEVEL="" \
    CLASSPATH="" \
    JAVA_OPTS=""

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
COPY get-hz-ee-dist-zip.sh ${HZ_HOME}/

# Install
RUN echo "Installing new packages" \
    && microdnf -y --nodocs --disablerepo=* --enablerepo=ubi-8-appstream --enablerepo=ubi-8-baseos \
        --disableplugin=subscription-manager install shadow-utils java-11-openjdk-headless zip tar \
    && echo "Downloading Hazelcast${HZ_VARIANT} distribution zip..." \
    && HAZELCAST_ZIP_URL=$(${HZ_HOME}/get-hz-ee-dist-zip.sh) \
    && curl -sf -L ${HAZELCAST_ZIP_URL} --output ${HZ_HOME}/hazelcast-enterprise-distribution.zip \
    && unzip -qq ${HZ_HOME}/hazelcast-enterprise-distribution.zip 'hazelcast-*/**' -d ${HZ_HOME}/tmp/ \
    && mv ${HZ_HOME}/tmp/*/* ${HZ_HOME}/ \
    && echo "Setting Pardot ID to 'docker'" \
    && echo 'hazelcastDownloadId=docker' > "${HZ_HOME}/hazelcast-download.properties" \
    && zip -u ${HZ_HOME}/lib/hazelcast-enterprise-all-${HZ_VERSION}.jar ${HZ_HOME}/hazelcast-download.properties \
    && echo "Granting read permission to ${HZ_HOME}" \
    && chmod -R +r ${HZ_HOME} \
    && echo "Removing cached package data and unnecessary tools" \
    && microdnf remove zip unzip \
    && microdnf -y clean all \
    && rm -rf ${HZ_HOME}/get-hz-ee-dist-zip.sh ${HZ_HOME}/hazelcast-distribution.zip ${HZ_HOME}/tmp

COPY log4j2.properties jmx_agent_config.yaml ${HZ_HOME}/config/

RUN echo "Adding non-root user" \
    && groupadd --system hazelcast \
    && useradd -l --system -g hazelcast -d ${HZ_HOME} ${USER_NAME}

WORKDIR ${HZ_HOME}

### Switch to hazelcast user
USER ${USER_NAME}

# Start Hazelcast server
CMD ["./bin/hazelcast-start"]
