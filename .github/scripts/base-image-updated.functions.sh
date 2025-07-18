# Returns the base image of the specified Dockerfile
function get_base_image_name() {
  local DOCKERFILE=$1
  # Read the (implicitly first) `FROM` line
  grep '^FROM ' ${DOCKERFILE} | cut -d' ' -f2
}

# Determine if the specified image is up-to-date
function base_image_updated_from_dockerfile() {
  local CURRENT_IMAGE=$1
  local DOCKERFILE=$2
  base_image_updated "${CURRENT_IMAGE}" $(get_base_image_name "${DOCKERFILE}")
}

# Determine if the specified image is up-to-date
function base_image_updated() {
  local CURRENT_IMAGE=$1
  local BASE_IMAGE=$2
  local BASE_IMAGE_SHA
  BASE_IMAGE_SHA=$(get_base_image_sha "${BASE_IMAGE}")
  local CURRENT_IMAGE_SHA
  CURRENT_IMAGE_SHA=$(get_base_image_sha "${CURRENT_IMAGE}")
  [[ "${CURRENT_IMAGE_SHA}" != "${BASE_IMAGE_SHA}" ]]
}

function get_base_image_sha() {
  local IMAGE=$1
  docker pull "${IMAGE}" --quiet
  docker image inspect --format '{{index .RootFS.Layers 0}}' "${IMAGE}"
}
