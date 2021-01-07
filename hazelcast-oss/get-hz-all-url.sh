#!/bin/bash

# This is a simple script imitating what maven does for snapshot versions. We are not using maven because currently Docker Buildx and QEMU on Github Actions
# don't work with Java on architectures ppc64le and s390x.
# If the version is snapshot, the script downloads the 'maven-metadata.xml' and parses it for the latest snapshot version. 'maven-metadata.xml' only holds the values for 
# the latest snapshot version. Thus, the [1] in snapshotVersion[1] is arbitrary because all of elements in the list have same value. The list consists of 'jar', 'pom', 'sources' and 'javadoc'.
if [[ "${HZ_VERSION}" == *"SNAPSHOT"* ]]
then
    xml=$(curl -sSL https://oss.sonatype.org/content/repositories/snapshots/com/hazelcast/hazelcast-all/${HZ_VERSION}/maven-metadata.xml)
    version=$(echo $xml | xpath -q -e '/metadata/versioning/snapshotVersions/snapshotVersion[1]/value' | grep -oP '(?<=<value>).*(?=</value>)')
    url="https://oss.sonatype.org/content/repositories/snapshots/com/hazelcast/hazelcast-all/${HZ_VERSION}/hazelcast-all-${version}.jar"
else
    url="https://repo1.maven.org/maven2/com/hazelcast/hazelcast-all/${HZ_VERSION}/hazelcast-all-${HZ_VERSION}.jar"
fi

echo $url