set -euo pipefail ${RUNNER_DEBUG:+-x}

# This is a simple script imitating what maven does for snapshot versions. We are not using maven because currently Docker Buildx and QEMU on Github Actions
# don't work with Java on architectures ppc64le and s390x. When the problem is fixed we will revert back to using maven.
# If the version is snapshot, the script downloads the 'maven-metadata.xml' and parses it for the snapshot version. 'maven-metadata.xml' only holds the values for
# the latest snapshot version. Thus, the [1] in snapshotVersion[1] is arbitrary because all of elements in the list have same value. The list consists of 'jar', 'pom', 'sources' and 'javadoc'.
#
# 'maven-metadata.xml' example - https://repo1.maven.org/maven2/com/hazelcast/hazelcast/maven-metadata.xml
function get_hz_dist_zip() {
  local hz_variant=$1
  local hz_version=$2

  # The slim is an artifact with a classifier, need to add `-` there
  suffix=${hz_variant:+-${hz_variant}}

  if [[ "${hz_version}" == *"SNAPSHOT"* ]]
  then  
      repository=snapshot
  else
      repository=release
  fi

  echo "https://repository.hazelcast.com/${repository}/com/hazelcast/hazelcast-enterprise-distribution/${hz_version}/hazelcast-enterprise-distribution-${hz_version}${suffix}.zip"
}
