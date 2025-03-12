#!/usr/bin/env bash

function get_supported_versions() {
    local MINIMAL_VERSION=$1
    git tag | sort -V | grep '^v' | cut -c2- | sed -n "/^${MINIMAL_VERSION}.*\$/,\$p" | grep -v BETA | grep -v DEVEL
}

function get_minor_versions() {
  local MINIMAL_VERSION=$1
  get_supported_versions "$MINIMAL_VERSION" | cut -d'-' -f1 |  cut  -d'.' -f1,2 | uniq
}

function get_latest_patch_version() {
  local MINOR_VERSION=$(echo "$1" | cut  -d'-' -f1 |  cut  -d'.' -f1,2)
  get_supported_versions "" | grep "^$MINOR_VERSION" | tail -n 1
}

function get_latest_patch_versions() {
    local MINIMAL_VERSION=$1
    MINOR_VERSIONS=$(get_minor_versions "$MINIMAL_VERSION")
    LATEST_PATCH_VERSIONS=()
    for minor in ${MINOR_VERSIONS}
    do
      LATEST_PATCH_VERSIONS+=($(get_latest_patch_version "$minor"))
    done
    echo "${LATEST_PATCH_VERSIONS[@]}"
}

# Find the highest-versioned, non BETA or otherwise suffix-ed tag in the repo
function get_last_version_tag_from_github() {
  local repo=$1
  tags=$(gh api repos/"${repo}"/tags \
      --paginate \
      --jq '.[] | select(.name | test("^v\\d+(\\.\\d+)*$")) | .name')
  tags_sorted=$(sort --version-sort --reverse <<< "${tags}")
  head --lines=1  <<< "${tags_sorted}"
}
