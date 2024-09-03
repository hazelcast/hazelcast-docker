#!/bin/bash

set -eEuo pipefail ${RUNNER_DEBUG:+-x}

get_formatted_latest_docker_tags() {
  local REPO_NAME=$1
  local PAGE=1
  local TAGS=""
  while true; do
    local RESPONSE=$(curl -s "https://hub.docker.com/v2/repositories/$REPO_NAME/tags/?page=${PAGE}&page_size=100")
    local CURRENT_TAGS=$(echo "${RESPONSE}" | jq -r '.results | group_by(.full_size) | .[] | {image: .[0].name, tags: [.[].name]}')
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

fill_readme_with_tags() {
   local filename=$1
   local repo_name=$2
   local matching_line="$3"
   local tags_file="tags-$(basename "$repo_name").md"
   get_formatted_latest_docker_tags "$repo_name" > "$tags_file"

   sed -i -e "/$matching_line/ {
        a\

        a\
        #### Latest Versions
        a\

        r $tags_file
    }" "$filename"

   rm "$tags_file"
}

cp README.md README-docker.md
fill_readme_with_tags README-docker.md "hazelcast/hazelcast" "### Hazelcast Versions"
fill_readme_with_tags README-docker.md "hazelcast/hazelcast-enterprise" "### Hazelcast Enterprise Versions"
