set -euo pipefail ${RUNNER_DEBUG:+-x}

# Checks if we should build the OSS docker image.
# Returns "yes" if we should build it or "no" if we shouldn't.
function should_build_oss() {

  local release_type=$1
  if [[ $release_type =~ ^(ALL|OSS)$ ]]; then
    echo "yes"
  else
    echo "no"
  fi
}

# Checks if we should build the OSS docker image.
function should_build_ee() {

  local release_type=$1
  if [[ $release_type =~ ^(ALL|EE)$ ]]; then
    echo "yes"
  else
    echo "no"
  fi
}

# Checks if we should rebuild the docker EE image description.
function should_build_readme_ee() {

  local release_type=$1
  if [[ $release_type =~ ^(ALL|EE|README)$ ]]; then
    echo "yes"
  else
    echo "no"
  fi
}

# Checks if we should rebuild the docker OSS image description.
function should_build_readme_oss() {

  local release_type=$1
  if [[ $release_type =~ ^(ALL|OSS|README)$ ]]; then
    echo "yes"
  else
    echo "no"
  fi
}
