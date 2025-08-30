# Returns the base image of the specified Dockerfile
function get_base_image_name() {
  local dockerfile=$1
  # Read the (implicitly first) `FROM` line
  grep '^FROM ' ${dockerfile} | cut -d' ' -f2
}

# Determine if the specified image is outdated when compared to it's base image
# Returns exit code:
# 0 if the current image is outdated compared to the base image
# 1 if the current image is up-to-date compared to the base image
function base_image_outdated_from_dockerfile() {
  local current_image=$1
  local dockerfile=$2
  base_image_outdated "${current_image}" $(get_base_image_name "${dockerfile}")
}

# Determine if the specified image is outdated when compared to it's base image
# Returns exit code:
# 0 if the current image is outdated compared to the base image
# 1 if the current image is up-to-date compared to the base image
function base_image_outdated() {
  local base_image_sha=$(get_base_image_sha "${2}")
  local current_image_sha=$(get_base_image_sha "${1}")
  [[ "${current_image_sha}" != "${base_image_sha}" ]]
}

function get_base_image_sha() {
  local image=$1
  docker pull "${image}" --quiet
  echonotice excerpt
  echonotice $(docker image inspect --format '{{index .RootFS.Layers 0}}' "${image}")
  echonotice full
  echonotice $(docker image inspect "${image}")
  echonotice fin
  docker image inspect --format '{{index .RootFS.Layers 0}}' "${image}"
}
