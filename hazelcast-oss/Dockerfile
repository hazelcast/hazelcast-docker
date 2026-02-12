# Used for image metadata only
# Describes the version of the Dockerfile, *not* the version of the bundled Hazelcast binary as this is/can be controlled externally
# Dockerfile needs some concept of versioning so that the release pipeline can tag/archive with an appropriate label
ARG HZ_VERSION=5.7.0-SNAPSHOT

# Build constants
ARG HZ_HOME="/opt/hazelcast"

FROM scratch AS get-distribution

ARG HZ_HOME
ARG HAZELCAST_DISTRIBUTION_FILE_NAME="hazelcast-distribution.tar.gz"

# Expects distribution file to be on the local filesystem within the build context
ADD ${HAZELCAST_DISTRIBUTION_FILE_NAME} /tmp/hz


FROM alpine:3

ARG HZ_HOME
ARG USER_NAME
ARG USER_GROUP

COPY --from=get-distribution /tmp/hz/ /tmp/hz/

