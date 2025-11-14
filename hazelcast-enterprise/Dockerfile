# Used for image metadata only
# Describes the version of the Dockerfile, *not* the version of the bundled Hazelcast binary as this is/can be controlled externally
# Dockerfile needs some concept of versioning so that the release pipeline can tag/archive with an appropriate label
ARG HZ_VERSION=5.7.0-SNAPSHOT

# Build constants
ARG HZ_HOME="/opt/hazelcast"
ARG USER_NAME="hazelcast"
ARG USER_GROUP="hazelcast"
ARG JDK_VERSION="21"

FROM alpine:3 AS get-distribution

ARG HZ_HOME
# Optional, defaults to latest released version
ARG HAZELCAST_ZIP_URL=""
ARG HAZELCAST_ZIP_FILE_NAME="hazelcast-enterprise-distribution.zip"

ENV MAVEN_ARTIFACT_ID=hazelcast-enterprise-distribution \
    MAVEN_REPO=https://repository.hazelcast.com/release

COPY hazelcast-*.zip /tmp

RUN --mount=type=bind,source=maven.functions.sh,target=maven.functions.sh \
    echo "Installing new packages" \
    && apk add --no-cache curl unzip \
    && mkdir -p ${HZ_HOME} \
    && if [[ ! -f /tmp/${HAZELCAST_ZIP_FILE_NAME} ]]; then \
       if [ -z ${HAZELCAST_ZIP_URL} ]; then \
            source maven.functions.sh; \
            HAZELCAST_ZIP_URL="$(get_latest_url_without_extension com.hazelcast ${MAVEN_ARTIFACT_ID} ${MAVEN_REPO})".zip; \
       fi; \
       echo "Downloading Hazelcast distribution zip from ${HAZELCAST_ZIP_URL}..."; \
       curl --fail --silent --show-error --location ${HAZELCAST_ZIP_URL} --output /tmp/${HAZELCAST_ZIP_FILE_NAME}; \
    else \
           echo "Using local ${HAZELCAST_ZIP_FILE_NAME}"; \
    fi \
    && unzip -qq /tmp/${HAZELCAST_ZIP_FILE_NAME} -d /tmp/hz \
    # Distribution ZIP structure is a single folder (e.g. "hazelcast-5.4.0-slim") containing the content
    # Move all the content up a level so that the path contains no version and is constant
    && mv /tmp/hz/*/* ${HZ_HOME}/ \
    && echo "Removing unnecessary packages and redundant files/folders" \
    && apk del curl unzip \
    && rm -rf /tmp/*


FROM redhat/ubi9-minimal:9.7

ARG HZ_VERSION
ARG HZ_HOME
ARG USER_NAME
ARG USER_GROUP
ARG JDK_VERSION

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

LABEL name="Hazelcast Enterprise" \
      maintainer="info@hazelcast.com" \
      vendor="Hazelcast, Inc." \
      version="${HZ_VERSION}" \
      release="1" \
      summary="Hazelcast Enterprise Image" \
      description="Hazelcast Enterprise Image"

# Expose port
EXPOSE 5701

COPY licenses /licenses
COPY --from=get-distribution ${HZ_HOME} ${HZ_HOME}/

# Install
RUN echo "Upgrading packages" \
    && microdnf -y update --nodocs \
    && echo "Installing new packages" \
    && microdnf -y --nodocs --disablerepo=* --enablerepo=ubi-9-appstream-rpms --enablerepo=ubi-9-baseos-rpms \
        --disableplugin=subscription-manager install shadow-utils java-${JDK_VERSION}-openjdk-headless tar tzdata-java util-linux \
    && echo "Setting Pardot ID to 'docker'" \
    && echo 'hazelcastDownloadId=docker' > "${HZ_HOME}/lib/hazelcast-download.properties" \
    && echo "Granting read permission to ${HZ_HOME}" \
    && chmod -R +r ${HZ_HOME} \
    && echo "Removing unnecessary packages and redundant files/folders" \
    && microdnf -y clean all \
    && echo "Grant execute permission to scripts in order to address the issue of permissions not being accurately propagated on Windows OS" \
    && chmod +x ${HZ_HOME}/bin/*

COPY log4j2.properties log4j2-json.properties jmx_agent_config.yaml ${HZ_HOME}/config/

WORKDIR ${HZ_HOME}

RUN echo "Adding non-root user" \
    && groupadd --system ${USER_GROUP} \
    && useradd --no-log-init --system --gid ${USER_GROUP} --create-home ${USER_NAME}
USER ${USER_NAME}

HEALTHCHECK CMD ["hz-healthcheck"]

# Start Hazelcast server
CMD ["hz", "start"]
