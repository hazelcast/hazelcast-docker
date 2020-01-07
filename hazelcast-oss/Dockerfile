FROM alpine:3.11

# Versions of Hazelcast and Hazelcast plugins
ARG HZ_VERSION=3.12.5
ARG CACHE_API_VERSION=1.1.0
ARG HZ_EUREKA_VERSION=1.1.1
ARG JMX_PROMETHEUS_AGENT_VERSION=0.11.0

# Build constants
ARG HZ_HOME="/opt/hazelcast"
ARG HZ_JAR="hazelcast-all-${HZ_VERSION}.jar"
ARG CACHE_API_JAR="cache-api-${CACHE_API_VERSION}.jar"

# Runtime constants / variables
ENV HZ_HOME="${HZ_HOME}" \
    CLASSPATH_DEFAULT="${HZ_HOME}/*:${HZ_HOME}/lib/*" \
    JAVA_OPTS_DEFAULT="-Djava.net.preferIPv4Stack=true -Djava.util.logging.config.file=${HZ_HOME}/logging.properties -XX:MaxRAMPercentage=80.0 -XX:+UseParallelGC --add-modules java.se --add-exports java.base/jdk.internal.ref=ALL-UNNAMED --add-opens java.base/java.lang=ALL-UNNAMED --add-opens java.base/java.nio=ALL-UNNAMED --add-opens java.base/sun.nio.ch=ALL-UNNAMED --add-opens java.management/sun.management=ALL-UNNAMED --add-opens jdk.management/com.sun.management.internal=ALL-UNNAMED" \
    MIN_HEAP_SIZE="" \
    MAX_HEAP_SIZE="" \
    MANCENTER_URL="" \
    PROMETHEUS_PORT="" \
    PROMETHEUS_CONFIG="${HZ_HOME}/jmx_agent_config.yaml" \
    LOGGING_LEVEL="" \
    CLASSPATH="" \
    JAVA_OPTS=""

# Expose port
EXPOSE 5701

COPY *.xml *.sh *.yaml *.jar *.properties ${HZ_HOME}/

# Install
RUN echo "Updating Alpine system" \
    && apk upgrade --update-cache --available \
    && echo "Installing new APK packages" \
    && apk add openjdk11-jre maven bash curl procps nss \
    && echo "Installing Hazelcast" \
    && cd "${HZ_HOME}" \
    && mkdir lib \
    && curl -sf -o ${HZ_HOME}/lib/${HZ_JAR} \
         -L https://repo1.maven.org/maven2/com/hazelcast/hazelcast-all/${HZ_VERSION}/${HZ_JAR} \
    && echo "Installing JCache" \
    && curl -sf -o "${HZ_HOME}/lib/${CACHE_API_JAR}" \
         -L "https://repo1.maven.org/maven2/javax/cache/cache-api/${CACHE_API_VERSION}/${CACHE_API_JAR}" \
    && echo "Installing Hazelcast plugins" \
    && mvn -f dependency-copy.xml \
           -Dhazelcast-eureka-version=${HZ_EUREKA_VERSION} \
           dependency:copy-dependencies \
    && echo "Maven clean-up" \
    && apk del maven \
    && rm -rf ~/.m2 \
    && rm -f dependency-copy.xml \
    && echo "Installing JMX Prometheus Agent" \
    && curl -sf -o "${HZ_HOME}/lib/jmx_prometheus_javaagent.jar" \
         -L "https://repo1.maven.org/maven2/io/prometheus/jmx/jmx_prometheus_javaagent/${JMX_PROMETHEUS_AGENT_VERSION}/jmx_prometheus_javaagent-${JMX_PROMETHEUS_AGENT_VERSION}.jar" \
    && echo "Granting read permission to ${HZ_HOME}" \
    && chmod -R +r $HZ_HOME \
    && echo "Setting Pardot ID to 'docker'" \
    && echo 'hazelcastDownloadId=docker' > hazelcast-download.properties \
    && echo "Cleaning APK packages" \
    && rm -rf /var/cache/apk/*

WORKDIR ${HZ_HOME}

# Start Hazelcast server
CMD ["/opt/hazelcast/start-hazelcast.sh"]

