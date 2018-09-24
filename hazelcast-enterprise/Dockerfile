FROM openjdk:8u171-jre-alpine

# Versions of Hazelcast and Hazelcast plugins
ARG HZ_VERSION=3.10.5
ARG CACHE_API_VERSION=1.0.0
ARG HZ_KUBE_VERSION=1.2.1
ARG HZ_EUREKA_VERSION=1.0.2

# Build constants
ARG HZ_HOME="/opt/hazelcast"
ARG HZ_JAR="hazelcast-enterprise-all-${HZ_VERSION}.jar"
ARG CACHE_API_JAR="cache-api-${CACHE_API_VERSION}.jar"
ARG HZ_INSTALL_NAME="hazelcast-enterprise-${HZ_VERSION}"
ARG HZ_INSTALL_ZIP="hazelcast-enterprise-${HZ_VERSION}.zip"
ARG HZ_INSTALL_DIR="${HZ_HOME}/${HZ_INSTALL_NAME}"

# Install bash & curl
RUN apk add --no-cache bash curl \
 && rm -rf /var/cache/apk/*

# Set up build directory
RUN mkdir -p ${HZ_HOME}
WORKDIR ${HZ_HOME}

# Download & install Hazelcast
RUN curl -svf -o ${HZ_HOME}/${HZ_INSTALL_ZIP} \
         -L https://download.hazelcast.com/enterprise/${HZ_INSTALL_ZIP} \
 && unzip ${HZ_INSTALL_ZIP} \
         -x ${HZ_INSTALL_NAME}/code-samples/* \
         -x ${HZ_INSTALL_NAME}/demo/* \
         -x ${HZ_INSTALL_NAME}/docs/* \
 && rm -rf ${HZ_INSTALL_ZIP}

# Download & install JCache
RUN curl -svf -o ${HZ_HOME}/${CACHE_API_JAR} \
         -L https://repo1.maven.org/maven2/javax/cache/cache-api/${CACHE_API_VERSION}/${CACHE_API_JAR}

# Download and install Hazelcast plugins (hazelcast-kubernetes and hazelcast-eureka) with dependencies
# Use Maven Wrapper to fetch dependencies specified in mvnw/dependency-copy.xml
RUN curl -svf -o ${HZ_HOME}/maven-wrapper.tar.gz \
         -L https://github.com/takari/maven-wrapper/archive/maven-wrapper-0.3.0.tar.gz \
 && tar zxf maven-wrapper.tar.gz \
 && rm -fr maven-wrapper.tar.gz \
 && mv maven-wrapper* mvnw
COPY mvnw ${HZ_HOME}/mvnw
RUN cd mvnw \
 && chmod +x mvnw \
 && sync \
 && ./mvnw -f dependency-copy.xml \
           -Dhazelcast-kubernetes-version=${HZ_KUBE_VERSION} \
           -Dhazelcast-eureka-version=${HZ_EUREKA_VERSION} \
           dependency:copy-dependencies \
 && cd .. \
 && rm -rf $HZ_HOME/mvnw \
 && rm -rf ~/.m2 \
 && chmod -R +r $HZ_HOME

ADD hazelcast.xml $HZ_HOME/hazelcast.xml

# Set Pardot ID to 'docker'
RUN echo 'hazelcastDownloadId=docker' > hazelcast-download.properties

# Runtime constants
ENV CLASSPATH_DEFAULT "${HZ_HOME}:${HZ_INSTALL_DIR}/lib/${HZ_JAR}:${HZ_HOME}/*"
ENV JAVA_OPTS_DEFAULT "-Djava.net.preferIPv4Stack=true -Dhazelcast.mancenter.enabled=false"

# Runtime environment variables
ENV MIN_HEAP_SIZE ""
ENV MAX_HEAP_SIZE ""
ENV HZ_LICENSE_KEY ""
ENV MANCENTER_URL ""

ENV CLASSPATH ""
ENV JAVA_OPTS ""

### Expose port
EXPOSE 5701

# Start Hazelcast server
CMD ["bash", "-c", "set -euo pipefail \
      && if [[ \"x${CLASSPATH}\" != \"x\" ]]; then export CLASSPATH=\"${CLASSPATH_DEFAULT}:${CLASSPATH}\"; else export CLASSPATH=\"${CLASSPATH_DEFAULT}\"; fi \
      && if [[ \"x${JAVA_OPTS}\" != \"x\" ]]; then export JAVA_OPTS=\"${JAVA_OPTS_DEFAULT} ${JAVA_OPTS}\"; else export JAVA_OPTS=\"${JAVA_OPTS_DEFAULT}\"; fi \
      && if [[ \"x${MIN_HEAP_SIZE}\" != \"x\" ]]; then export JAVA_OPTS=\"${JAVA_OPTS} -Xms${MIN_HEAP_SIZE}\"; fi \
      && if [[ \"x${MAX_HEAP_SIZE}\" != \"x\" ]]; then export JAVA_OPTS=\"${JAVA_OPTS} -Xmx${MAX_HEAP_SIZE}\"; fi \
      && if [[ \"x${HZ_LICENSE_KEY}\" != \"x\" ]]; then export JAVA_OPTS=\"${JAVA_OPTS} -Dhazelcast.enterprise.license.key=${HZ_LICENSE_KEY}\"; fi \
      && if [[ \"x${MANCENTER_URL}\" != \"x\" ]]; then export JAVA_OPTS=\"${JAVA_OPTS} -Dhazelcast.mancenter.enabled=true -Dhazelcast.mancenter.url=${MANCENTER_URL}\"; fi \
      && echo \"########################################\" \
      && echo \"# JAVA_OPTS=${JAVA_OPTS}\" \
      && echo \"# CLASSPATH=${CLASSPATH}\" \
      && echo \"# starting now....\" \
      && echo \"########################################\" \
      && set -x \
      && exec java -server ${JAVA_OPTS} com.hazelcast.core.server.StartServer \
     "]
