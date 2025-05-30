set -euo pipefail ${RUNNER_DEBUG:+-x}

function get_hz_dist_zip() {
  local hz_variant=$1
  local hz_version=$2

  # The slim is an artifact with a classifier, need to add `-` there
  suffix=${hz_variant:+-$hz_variant}

  if [[ "${hz_version}" == *"SNAPSHOT"* ]]
  then
      url="https://${HZ_SNAPSHOT_INTERNAL_USERNAME}:${HZ_SNAPSHOT_INTERNAL_PASSWORD}@repository.hazelcast.com/snapshot-internal/com/hazelcast/hazelcast-distribution/${hz_version}/hazelcast-distribution-${hz_version}${suffix}.zip"
  else
      url="https://repo1.maven.org/maven2/com/hazelcast/hazelcast-distribution/${hz_version}/hazelcast-distribution-${hz_version}${suffix}.zip"
  fi

  echo "$url"
}
