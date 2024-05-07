FROM alpine:3

# Build constants
ARG HZ_HOME="/opt/hazelcast"
ARG JDK_VERSION="21"
ARG HAZELCAST_ZIP_URL=

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

COPY *.jar hazelcast-*.zip maven.functions.sh ${HZ_HOME}/

# Install
RUN echo "Upgrading APK packages" \
    && apk upgrade --no-cache \
    && echo "Installing new APK packages" \
    && apk add --no-cache openjdk${JDK_VERSION}-jre-headless bash curl zip unzip \
    && if [[ ! -f ${HZ_HOME}/hazelcast-distribution.zip ]]; then \
       if [ -z ${HAZELCAST_ZIP_URL} ]; then \
            source ${HZ_HOME}/maven.functions.sh \
            HAZELCAST_ZIP_URL="$(get_latest_url_without_extension com.hazelcast hazelcast-distribution)".jar; \
       fi \
       echo "Downloading Hazelcast distribution zip from ${HAZELCAST_ZIP_URL}..."; \
       mkdir --parents ${HZ_HOME}; \
       curl -sfL ${HAZELCAST_ZIP_URL} --output ${HZ_HOME}/hazelcast-distribution.zip; \
    else \
           echo "Using local hazelcast-distribution.zip"; \
    fi \
    && unzip -qq ${HZ_HOME}/hazelcast-distribution.zip 'hazelcast-*/**' -d ${HZ_HOME}/tmp/ \
    && mv ${HZ_HOME}/tmp/*/* ${HZ_HOME}/ \
    && echo "Setting Pardot ID to 'docker'" \
    && echo 'hazelcastDownloadId=docker' > "${HZ_HOME}/lib/hazelcast-download.properties" \
    && echo "Granting read permission to ${HZ_HOME}" \
    && chmod -R +r ${HZ_HOME} \
    && echo "Cleaning APK packages and redundant files/folders" \
    && apk del zip unzip \
    && rm -rf /var/cache/apk/* ${HZ_HOME}/hazelcast-distribution.zip ${HZ_HOME}/tmp \
    # Grant execute permission to scripts in order to address the issue of permissions not being accurately propagated on Windows OS
    && chmod +x ${HZ_HOME}/bin/*

COPY log4j2.properties log4j2-json.properties jmx_agent_config.yaml ${HZ_HOME}/config/

WORKDIR ${HZ_HOME}

RUN addgroup -S hazelcast && adduser -S hazelcast -G hazelcast
USER hazelcast

# Start Hazelcast server
CMD ["hz", "start"]
