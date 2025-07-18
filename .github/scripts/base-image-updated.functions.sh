function get_base_image_name() {
  local DOCKERFILE=$1
  grep '^FROM ' ${DOCKERFILE} | cut -d' ' -f2
}

function base_image_updated_from_dockerfile() {
  local CURRENT_IMAGE=$1
  local DOCKERFILE=$2
  base_image_updated "${CURRENT_IMAGE}" $(get_base_image_name "${DOCKERFILE}")
}

function base_image_updated() {
  local CURRENT_IMAGE=$1
  local BASE_IMAGE=$2
  local BASE_IMAGE_SHA
  BASE_IMAGE_SHA=$(get_sha "${BASE_IMAGE}")
  local CURRENT_IMAGE_SHA
  CURRENT_IMAGE_SHA=$(get_sha "${CURRENT_IMAGE}")
  [[ "${CURRENT_IMAGE_SHA}" != "${BASE_IMAGE_SHA}" ]]
}

function get_sha() {
  local IMAGE=$1
  docker pull "${IMAGE}" --quiet
  docker image inspect --format '{{index .RootFS.Layers 0}}' "${IMAGE}"
}
