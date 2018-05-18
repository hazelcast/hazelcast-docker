FROM openjdk:8u151-jre-alpine

ENV HZ_VERSION 3.10
ENV HZ_HOME /opt/hazelcast

ENV HZ_INSTALL_NAME "hazelcast-enterprise-${HZ_VERSION}"
ENV HZ_INSTALL_ZIP "hazelcast-enterprise-${HZ_VERSION}.zip"
ENV HZ_INSTALL_DIR "${HZ_HOME}/${HZ_INSTALL_NAME}"
ENV HZ_INSTALL_JAR "hazelcast-enterprise-all-${HZ_VERSION}.jar"

ENV CACHE_API_VERSION 1.0.0
ENV CACHE_API_JAR "cache-api-${CACHE_API_VERSION}.jar"

# Update alpine, and, install bash & curl
RUN apk update \
 && apk upgrade \
 && apk add --update \
      bash \
      curl \
 && rm -rf /var/cache/apk/*

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

# Runtime environment variables
ENV CLASSPATH_DEFAULT "${HZ_INSTALL_DIR}/lib/${HZ_INSTALL_JAR}:${HZ_HOME}/${CACHE_API_JAR}"
ENV JAVA_OPTS_DEFAULT "-Djava.net.preferIPv4Stack=true"

ENV MIN_HEAP_SIZE ""
ENV MAX_HEAP_SIZE ""
ENV HZ_LICENSE_KEY ""

ENV CLASSPATH ""
ENV JAVA_OPTS ""

# Start Hazelcast server
CMD ["bash", "-c", "set -euo pipefail \
      && if [[ \"x${CLASSPATH}\" != \"x\" ]]; then export CLASSPATH=\"${CLASSPATH_DEFAULT}:${CLASSPATH}\"; else export CLASSPATH=\"${CLASSPATH_DEFAULT}\"; fi \
      && if [[ \"x${JAVA_OPTS}\" != \"x\" ]]; then export JAVA_OPTS=\"${JAVA_OPTS_DEFAULT} ${JAVA_OPTS}\"; else export JAVA_OPTS=\"${JAVA_OPTS_DEFAULT}\"; fi \
      && if [[ \"x${MIN_HEAP_SIZE}\" != \"x\" ]]; then export JAVA_OPTS=\"${JAVA_OPTS} -Xms${MIN_HEAP_SIZE}\"; fi \
      && if [[ \"x${MAX_HEAP_SIZE}\" != \"x\" ]]; then export JAVA_OPTS=\"${JAVA_OPTS} -Xms${MAX_HEAP_SIZE}\"; fi \
      && if [[ \"x${HZ_LICENSE_KEY}\" != \"x\" ]]; then export JAVA_OPTS=\"${JAVA_OPTS} -Dhazelcast.enterprise.license.key=${HZ_LICENSE_KEY}\"; fi \
      && echo \"########################################\" \
      && echo \"# JAVA_OPTS=${JAVA_OPTS}\" \
      && echo \"# CLASSPATH=${CLASSPATH}\" \
      && echo \"# starting now....\" \
      && echo \"########################################\" \
      && set -x \
      && exec java -server ${JAVA_OPTS} com.hazelcast.core.server.StartServer \
     "]
