#!/usr/bin/env bash

set -o errexit -o nounset -o pipefail ${RUNNER_DEBUG:+-x}

# Returns an output _like_:
# - 5, 5-jdk21, 5.5, 5.5-jdk21, 5.5.0, 5.5.0-jdk21, latest, latest-jdk21
# - 5-jdk11, 5.3.7, 5.3.7-jdk11, latest-jdk11
# - 5-jdk17, 5.5-jdk17, 5.5.0-jdk17, latest-jdk17
function get_formatted_latest_docker_tags() {
  local REPO_NAME=$1
  local PAGE=1
  local TAGS=""
  local TOKEN=$(get_docker_token)

  while true; do
    local RESPONSE=$( \
      curl --fail \
        --silent \
        --show-error \
        --header "Authorization: Bearer ${TOKEN}" \
        "https://hub.docker.com/v2/repositories/$REPO_NAME/tags/?page=${PAGE}&page_size=100")
    local CURRENT_TAGS=$(echo "${RESPONSE}" | jq -r '.results | group_by(.digest) | .[] | {image: .[0].name, tags: [.[].name]}')
    local TAGS="${TAGS}${CURRENT_TAGS}"
    local  HAS_NEXT=$(echo "${RESPONSE}" | jq -r '.next')
    if [ "$HAS_NEXT" == "null" ]; then
      break
    else
      PAGE=$((PAGE + 1))
    fi
  done

  local LATEST_TAGS=$(echo "${TAGS}" | jq -sr '.[] | select(
  any(.tags[]; match("^5\\..(-slim)?$|latest"))
)')

  echo "${LATEST_TAGS}"| jq -sr '.[] | " - " + (.tags | sort_by(.) | join(", "))' | sort -V
}

function get_docker_token() {
  curl --fail \
    --silent \
    --show-error \
    --header "Content-Type: application/json" \
    --data "{\"username\":\"${USERNAME}\",\"password\":\"${PASSWORD}\"}" \
    https://hub.docker.com/v2/users/login/ | 
    jq -r '.token'
}

function fill_readme_with_tags() {
   local filename=$1
   local repo_name=$2
   local matching_line="$3"
   local tags_file="tags-$(basename "$repo_name").md"
   get_formatted_latest_docker_tags "$repo_name" > "$tags_file"

   sed -i -e "/$matching_line/ {
a\\

a\\
#### Latest Versions
a\\

r $tags_file
    }" "$filename"

   rm "$tags_file"
}

cp README.md README-docker.md
fill_readme_with_tags README-docker.md "${NAMESPACE}/${OSS_IMAGE_NAME}" "### Hazelcast Versions"
fill_readme_with_tags README-docker.md "${NAMESPACE}/${EE_IMAGE_NAME}" "### Hazelcast Enterprise Versions"
