#!/bin/bash

if [[ "${HZ_VERSION}" == *"SNAPSHOT"* ]]
then
    xml=$(curl -sSL https://oss.sonatype.org/content/repositories/snapshots/com/hazelcast/hazelcast-all/${HZ_VERSION}/maven-metadata.xml)
    version=$(echo $xml | xpath -q  -e  '/metadata/versioning/snapshotVersions/snapshotVersion[1]/value' | grep -oP '(?<=<value>).*(?=</value>)')
    url="https://oss.sonatype.org/content/repositories/snapshots/com/hazelcast/hazelcast-all/${HZ_VERSION}/hazelcast-all-${version}.jar"
else
    url="https://repo1.maven.org/maven2/com/hazelcast/hazelcast-all/${HZ_VERSION}/hazelcast-all-${HZ_VERSION}.jar"
fi

echo $url