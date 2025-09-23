FROM alpine:3

# Describes the version of the Dockerfile, *not* the version of the bundled Hazelcast binary as this is/can be controlled externally
# Dockerfile needs some concept of versioning so that the release pipeline can tag/archive with an appropriate label
ARG HZ_VERSION=5.7.0-SNAPSHOT

# Build constants
ARG HZ_HOME="/opt/hazelcast"
ARG USER_NAME="hazelcast"
ARG USER_GROUP="hazelcast"
ARG JDK_VERSION="21"
# Optional, defaults to latest released version
ARG HAZELCAST_ZIP_URL=""
ARG HAZELCAST_ZIP_FILE_NAME="hazelcast-distribution.zip"

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
RUN echo "Upgrading packages" \
    && apk upgrade --no-cache \
    && echo "Installing new packages" \
    && apk add --no-cache openjdk${JDK_VERSION}-jre-headless bash curl libxml2-utils zip unzip \
    && if [[ ! -f ${HZ_HOME}/${HAZELCAST_ZIP_FILE_NAME} ]]; then \
       if [ -z ${HAZELCAST_ZIP_URL} ]; then \
            source ${HZ_HOME}/maven.functions.sh; \
            HAZELCAST_ZIP_URL="$(get_latest_url_without_extension com.hazelcast hazelcast-distribution https://repo.maven.apache.org/maven2)".zip; \
       fi; \
       echo "Downloading Hazelcast distribution zip from ${HAZELCAST_ZIP_URL}..."; \
       mkdir --parents ${HZ_HOME}; \
       curl --fail --silent --show-error --location ${HAZELCAST_ZIP_URL} --output ${HZ_HOME}/${HAZELCAST_ZIP_FILE_NAME}; \
    else \
           echo "Using local ${HAZELCAST_ZIP_FILE_NAME}"; \
    fi \
    && unzip -qq ${HZ_HOME}/${HAZELCAST_ZIP_FILE_NAME} 'hazelcast-*/**' -d ${HZ_HOME}/tmp/ \
    && mv ${HZ_HOME}/tmp/*/* ${HZ_HOME}/ \
    && echo "Setting Pardot ID to 'docker'" \
    && echo 'hazelcastDownloadId=docker' > "${HZ_HOME}/lib/hazelcast-download.properties" \
    && echo "Granting read permission to ${HZ_HOME}" \
    && chmod -R +r ${HZ_HOME} \
    && echo "Removing unnecessary packages and redundant files/folders" \
    && apk del libxml2-utils zip unzip \
    && rm -rf /var/cache/apk/* ${HZ_HOME}/maven.functions.sh ${HZ_HOME}/${HAZELCAST_ZIP_FILE_NAME} ${HZ_HOME}/tmp \
    # Grant execute permission to scripts in order to address the issue of permissions not being accurately propagated on Windows OS
    && chmod +x ${HZ_HOME}/bin/*

COPY log4j2.properties log4j2-json.properties jmx_agent_config.yaml ${HZ_HOME}/config/

WORKDIR ${HZ_HOME}

RUN echo "Adding non-root user" \
    && addgroup -S ${USER_GROUP} \
    && adduser -S ${USER_NAME} -G ${USER_GROUP}
USER ${USER_NAME}

HEALTHCHECK CMD ["hz-healthcheck"]

# Start Hazelcast server
CMD ["hz", "start"]
