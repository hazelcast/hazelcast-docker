FROM registry.access.redhat.com/ubi8/ubi-minimal:8.3

# Versions of Hazelcast and Hazelcast plugins
ARG HZ_VERSION=4.0.3
ARG CACHE_API_VERSION=1.1.1
ARG JMX_PROMETHEUS_AGENT_VERSION=0.14.0
ARG LOG4J2_VERSION=2.13.3

# Build constants
ARG HZ_HOME="/opt/hazelcast"
ARG USER_NAME="hazelcast"

# JARs to download
ARG HAZELCAST_ALL_URL="https://repository.hazelcast.com/release/com/hazelcast/hazelcast-enterprise-all/${HZ_VERSION}/hazelcast-enterprise-all-${HZ_VERSION}.jar"
ARG CACHE_API_URL="https://repo1.maven.org/maven2/javax/cache/cache-api/${CACHE_API_VERSION}/cache-api-${CACHE_API_VERSION}.jar"
ARG PROMETHEUS_AGENT_URL="https://repo1.maven.org/maven2/io/prometheus/jmx/jmx_prometheus_javaagent/${JMX_PROMETHEUS_AGENT_VERSION}/jmx_prometheus_javaagent-${JMX_PROMETHEUS_AGENT_VERSION}.jar"
ARG LOG4J2_URLS="https://repo1.maven.org/maven2/org/apache/logging/log4j/log4j-core/${LOG4J2_VERSION}/log4j-core-${LOG4J2_VERSION}.jar https://repo1.maven.org/maven2/org/apache/logging/log4j/log4j-api/${LOG4J2_VERSION}/log4j-api-${LOG4J2_VERSION}.jar"

# Runtime variables
ENV HZ_HOME="${HZ_HOME}" \
    CLASSPATH_DEFAULT="${HZ_HOME}/*:${HZ_HOME}/lib/*" \
    JAVA_OPTS_DEFAULT="-Djava.net.preferIPv4Stack=true -Dhazelcast.logging.type=log4j2 -Dlog4j.configurationFile=${HZ_HOME}/log4j2.properties -XX:MaxRAMPercentage=80.0 -XX:MaxGCPauseMillis=5 --add-modules java.se --add-exports java.base/jdk.internal.ref=ALL-UNNAMED --add-opens java.base/java.lang=ALL-UNNAMED --add-opens java.base/java.nio=ALL-UNNAMED --add-opens java.base/sun.nio.ch=ALL-UNNAMED --add-opens java.management/sun.management=ALL-UNNAMED --add-opens jdk.management/com.sun.management.internal=ALL-UNNAMED" \
    HZ_LICENSE_KEY="" \
    PROMETHEUS_PORT="" \
    PROMETHEUS_CONFIG="${HZ_HOME}/jmx_agent_config.yaml" \
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

COPY *.sh *.yaml *.jar *.properties ${HZ_HOME}/
COPY licenses /licenses

# Install
RUN echo "Installing new packages" \
    && microdnf -y --nodocs --disablerepo=* --enablerepo=ubi-8-appstream --enablerepo=ubi-8-baseos \
        --disableplugin=subscription-manager install shadow-utils java-11-openjdk-headless curl \
    && echo "Downloading Hazelcast and related JARs" \
    && mkdir -p "${HZ_HOME}/lib" \
    && cd "${HZ_HOME}/lib" \
    && for JAR_URL in ${HAZELCAST_ALL_URL} ${CACHE_API_URL} ${PROMETHEUS_AGENT_URL} ${LOG4J2_URLS}; do curl -sf -O -L ${JAR_URL} || exit $?; done \
    && mv jmx_prometheus_javaagent-*.jar jmx_prometheus_javaagent.jar \
    && echo "Granting read permission to ${HZ_HOME}" \
    && chmod -R +r ${HZ_HOME} \
    && echo "Setting Pardot ID to 'docker'" \
    && echo 'hazelcastDownloadId=docker' > "${HZ_HOME}/hazelcast-download.properties" \
    && echo "Removed cached package data" \
    && microdnf -y clean all

RUN echo "Adding non-root user" \
    && groupadd --system hazelcast \
    && useradd -l --system -g hazelcast -d ${HZ_HOME} ${USER_NAME}

WORKDIR ${HZ_HOME}

### Switch to hazelcast user
USER ${USER_NAME}

# Start Hazelcast server
CMD ["/opt/hazelcast/start-hazelcast.sh"]
