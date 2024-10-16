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

function verlte() {
  [ "$1" = "$(echo -e "$1\n$2" | sort -V | head -n1)" ]
}

get_tags_descending() {
  git tag -l "v*" | sort -V -r | grep -v '-'
}

file_exists_in_tag() {
  local file=$1
  local tag=$2
  # subshell to wrap directory change
  (
    set -e
    cd -- "$(git rev-parse --show-toplevel)"
    git ls-tree -r "$tag" --name-only | grep "^$file$" | grep -q "^$file$"
  )
}

function get_last_version_with_file() {
  local file=$1
  if [ "$#" -ne 1 ]; then
    echo "Error: Incorrect number of arguments. Usage: ${FUNCNAME[0]} <file>"
    exit 1
  fi
  for tag in $(get_tags_descending); do
    if file_exists_in_tag "$file" "$tag"; then
      echo "$tag" | cut -c2-
      return
    fi
  done
}
