FROM alpine:3.16.2

# Versions of Hazelcast
ARG HZ_VERSION=5.1.4
# Variant - empty for full, "slim" for slim
ARG HZ_VARIANT=""

# Build constants
ARG HZ_HOME="/opt/hazelcast"

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

# Expose port
EXPOSE 5701

COPY *.jar get-hz-dist-zip.sh ${HZ_HOME}/

# Install
RUN echo "Installing new APK packages" \
    && apk add --no-cache openjdk11-jre-headless bash curl libxml2-utils zip unzip \
    && echo "Downloading Hazelcast${HZ_VARIANT} distribution zip..." \
    && HAZELCAST_ZIP_URL=$(${HZ_HOME}/get-hz-dist-zip.sh) \
    && curl -sf -L ${HAZELCAST_ZIP_URL} --output ${HZ_HOME}/hazelcast-distribution.zip \
    && unzip -qq ${HZ_HOME}/hazelcast-distribution.zip 'hazelcast-*/**' -d ${HZ_HOME}/tmp/ \
    && mv ${HZ_HOME}/tmp/*/* ${HZ_HOME}/ \
    && echo "Setting Pardot ID to 'docker'" \
    && echo 'hazelcastDownloadId=docker' > "${HZ_HOME}/lib/hazelcast-download.properties" \
    && echo "Granting read permission to ${HZ_HOME}" \
    && chmod -R +r ${HZ_HOME} \
    && echo "Cleaning APK packages and redundant files/folders" \
    && apk del libxml2-utils zip unzip \
    && rm -rf /var/cache/apk/* ${HZ_HOME}/get-hz-dist-zip.sh ${HZ_HOME}/hazelcast-distribution.zip ${HZ_HOME}/tmp

COPY log4j2.properties log4j2-json.properties jmx_agent_config.yaml ${HZ_HOME}/config/

WORKDIR ${HZ_HOME}

RUN addgroup -S hazelcast && adduser -S hazelcast -G hazelcast
USER hazelcast

# Start Hazelcast server
CMD ["hz", "start"]
