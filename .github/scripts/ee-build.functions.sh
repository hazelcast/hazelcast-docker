#!/bin/bash

set -euo pipefail

# This is a simple script imitating what maven does for snapshot versions. We are not using maven because currently Docker Buildx and QEMU on Github Actions
# don't work with Java on architectures ppc64le and s390x. When the problem is fixed we will revert back to using maven.
# If the version is snapshot, the script downloads the 'maven-metadata.xml' and parses it for the snapshot version. 'maven-metadata.xml' only holds the values for
# the latest snapshot version. Thus, the [1] in snapshotVersion[1] is arbitrary because all of elements in the list have same value. The list consists of 'jar', 'pom', 'sources' and 'javadoc'.
function get_hz_dist_zip() {
  local hz_variant=$1
  local hz_version=$2
  local suffix=$3

  # The slim is an artifact with a classifier, need to add `-` there
  if [[ -n "${hz_variant}" ]]; then suffix="-${hz_variant}"; fi

  if [[ "${hz_version}" == *"SNAPSHOT"* ]]
  then  
      if [ -n "$hz_variant" ]; then
          classifier_filter="classifier='$hz_variant'"
      else
          classifier_filter="not(classifier)"
      fi
      version=$(curl --fail --silent --show-error --location https://repository.hazelcast.com/snapshot/com/hazelcast/hazelcast-enterprise-distribution/"${hz_version}"/maven-metadata.xml | xmllint --xpath "/metadata/versioning/snapshotVersions/snapshotVersion[extension='zip' and $classifier_filter]/value/text()" -)

      url="https://repository.hazelcast.com/snapshot/com/hazelcast/hazelcast-enterprise-distribution/${hz_version}/hazelcast-enterprise-distribution-${version}${suffix}.zip"
  else
      url="https://repository.hazelcast.com/release/com/hazelcast/hazelcast-enterprise-distribution/${hz_version}/hazelcast-enterprise-distribution-${hz_version}${suffix}.zip"
  fi

  echo "$url"
}
