set -euo pipefail ${RUNNER_DEBUG:+-x}

# Checks if we should build the OSS artefacts.
# Returns "yes" if we should build it or "no" if we shouldn't.
function should_build_oss() {

  local release_type=$1
  if [[ $release_type =~ ^(ALL|OSS)$ ]]; then
    echo "yes"
  else
    echo "no"
  fi
}

# Checks if we should build EE artefacts.
function should_build_ee() {

  local release_type=$1
  if [[ $release_type =~ ^(ALL|EE)$ ]]; then
    echo "yes"
  else
    echo "no"
  fi
}
