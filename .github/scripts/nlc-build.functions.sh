set -euo pipefail ${RUNNER_DEBUG:+-x}

function get_hz_dist_zip() {
  local hz_variant=$1
  local hz_version=$2

  if [[ "${hz_version}" =~ SNAPSHOT ]]
  then  
    subdir=/snapshot
  else
    subdir=
  fi

  aws s3 presign "${REPO_URL}${subdir}/hazelcast-enterprise-${hz_version}-nlc.zip" --expires-in 600
}
