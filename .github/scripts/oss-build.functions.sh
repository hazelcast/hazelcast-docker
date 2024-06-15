#!/bin/bash

set -euo pipefail

function get_hz_dist_zip() {
  local hz_variant=$1
  local hz_version=$2

  # The slim is an artifact with a classifier, need to add `-` there
  suffix=${hz_variant:+-$hz_variant}

  if [[ "${hz_version}" == *"SNAPSHOT"* ]]
  then
      # DI-95 - Do not rely on the OSS distribution zip in the hazelcast-docker PR builder
      # https://hazelcast.atlassian.net/browse/DI-95
      url="$(aws s3 presign "s3://hazelcast/distribution-snapshot/hazelcast-${hz_version}${suffix}.zip" --expires-in 600)"
  else
      url="https://repo1.maven.org/maven2/com/hazelcast/hazelcast-distribution/${hz_version}/hazelcast-distribution-${hz_version}${suffix}.zip"
  fi

  echo "$url"
}
