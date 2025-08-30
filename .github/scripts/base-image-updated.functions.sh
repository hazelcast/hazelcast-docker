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
  docker pull "${2}" --quiet
  docker pull "${1}" --quiet

  local base_image_sha=$(docker image inspect --format '{{index .RootFS.Layers 0}}' "${2}")
  local current_image_sha=$(docker image inspect --format '{{index .RootFS.Layers 0}}' "${1}")
}
