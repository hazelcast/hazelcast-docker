#!/bin/bash

# This is a simple script imitating what maven does for snapshot versions. We are not using maven because currently Docker Buildx and QEMU on Github Actions
# don't work with Java on architectures ppc64le and s390x. When the problem is fixed we will revert back to using maven.
# If the version is snapshot, the script downloads the 'maven-metadata.xml' and parses it for the snapshot version. 'maven-metadata.xml' only holds the values for
# the latest snapshot version. Thus, the [1] in snapshotVersion[1] is arbitrary because all of elements in the list have same value. The list consists of 'jar', 'pom', 'sources' and 'javadoc'.

# The slim is an artifact with a classifier, need to add `-` there
if [[ -n "${HZ_VARIANT}" ]]; then SUFFIX="-${HZ_VARIANT}"; fi

if [[ "${HZ_VERSION}" == *"SNAPSHOT"* ]]
then
    curl -O -fsSL https://oss.sonatype.org/content/repositories/snapshots/com/hazelcast/hazelcast-distribution/${HZ_VERSION}/maven-metadata.xml
    classifier_filter="not(classifier)"
    if [ -n "$HZ_VARIANT" ]; then
        classifier_filter="classifier='$HZ_VARIANT'"
    fi
    version=$(xmllint --xpath "/metadata/versioning/snapshotVersions/snapshotVersion[extension='zip' and $classifier_filter]/value/text()" maven-metadata.xml)

    url="https://oss.sonatype.org/content/repositories/snapshots/com/hazelcast/hazelcast-distribution/${HZ_VERSION}/hazelcast-distribution-${version}${SUFFIX}.zip"
    rm maven-metadata.xml
else
    url="https://repo1.maven.org/maven2/com/hazelcast/hazelcast-distribution/${HZ_VERSION}/hazelcast-distribution-${HZ_VERSION}${SUFFIX}.zip"
fi

echo $url
