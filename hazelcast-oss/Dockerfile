FROM alpine:3.13.2

# Versions of Hazelcast and Hazelcast plugins
ARG HZ_VERSION=5.0-SNAPSHOT
# Variant - "" (empty) for full, "slim" for slim
ARG HZ_VARIANT=""

# Build constants
ARG HZ_HOME="/opt/hazelcast"

# Runtime variables
ENV HZ_HOME="${HZ_HOME}" \
    CLASSPATH_DEFAULT="" \
    JAVA_OPTS_DEFAULT="-Djava.net.preferIPv4Stack=true -XX:MaxRAMPercentage=80.0" \
    PROMETHEUS_PORT="" \
    PROMETHEUS_CONFIG="${HZ_HOME}/config/jmx_agent_config.yaml" \
    LOGGING_LEVEL="INFO" \
    CLASSPATH="" \
    JAVA_OPTS=""

# Expose port
EXPOSE 5701

COPY *.sh /

# Install
RUN echo "Installing new APK packages" \
    && apk add --no-cache openjdk11-jre-headless bash curl perl-xml-xpath zip unzip \
    && echo "Downloading Hazelcast and related JARs" \
    && cd  /opt \
    && HAZELCAST_ALL_URL=$(/get-hz-all-url.sh) \
    && for JAR_URL in ${HAZELCAST_ALL_URL} ; do curl -sf -O -L ${JAR_URL} || exit $?; done \
    && unzip hazelcast-distribution-*.zip \
    && mv hazelcast-${HZ_VERSION}* hazelcast \
    && cd /opt/hazelcast \
    && echo "Setting Pardot ID to 'docker'" \
    && echo 'hazelcastDownloadId=docker' > "hazelcast-download.properties" \
    && zip -u lib/hazelcast-${HZ_VERSION}.jar hazelcast-download.properties \
    && echo "Granting read permission to ${HZ_HOME}" \
    && chmod -R +r ${HZ_HOME} \
    && echo "Cleaning APK packages" \
    && apk del perl-xml-xpath curl zip unzip \
    && rm -rf /var/cache/apk/* /get-hz-all-url.sh /opt/hazelcast-distribution-*.zip

COPY *.properties ${HZ_HOME}/config

WORKDIR ${HZ_HOME}

RUN addgroup -S hazelcast && adduser -S hazelcast -G hazelcast
USER hazelcast

# Start Hazelcast server
CMD ["/opt/hazelcast/bin/hazelcast-start"]