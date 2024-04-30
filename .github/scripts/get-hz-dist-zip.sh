#!/bin/bash

# The slim is an artifact with a classifier, need to add `-` there
if [[ -n "${HZ_VARIANT}" ]]; then SUFFIX="-${HZ_VARIANT}"; fi

if [[ "${HZ_VERSION}" == *"SNAPSHOT"* ]]
then
    # DI-95 - Do not rely on the OSS distribution zip in the hazelcast-docker PR builder
    # https://hazelcast.atlassian.net/browse/DI-95
    url="$(aws s3 presign s3://hazelcast/distribution-snapshot/hazelcast-"${HZ_VERSION}""${SUFFIX}".zip --expires-in 600)"
else
    url="https://repo1.maven.org/maven2/com/hazelcast/hazelcast-distribution/${HZ_VERSION}/hazelcast-distribution-${HZ_VERSION}${SUFFIX}.zip"
fi

echo "$url"
