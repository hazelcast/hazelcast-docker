# Returns the base image of the specified Dockerfile
function get_base_image_name() {
  local dockerfile=$1
  # Read the (implicitly first) `FROM` line
  grep '^FROM ' ${dockerfile} | cut -d' ' -f2
}

# Determine if the specified image is up-to-date
function base_image_updated_from_dockerfile() {
  local current_image=$1
  local dockerfile=$2
  base_image_updated "${current_image}" $(get_base_image_name "${dockerfile}")
}

# Determine if the specified image is up-to-date
function base_image_updated() {
  local current_image=$1
  local base_image=$2
  local base_image_sha
  base_image_sha=$(get_base_image_sha "${base_image}")
  local current_image_sha
  current_image_sha=$(get_base_image_sha "${current_image}")
  [[ "${current_image_sha}" != "${base_image_sha}" ]]
}

function get_base_image_sha() {
  local image=$1
  docker pull "${image}" --quiet
  docker image inspect --format '{{index .RootFS.Layers 0}}' "${image}"
}
