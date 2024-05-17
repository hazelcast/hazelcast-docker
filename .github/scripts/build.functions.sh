#!/bin/bash

set -euo pipefail

# Checks if we should build the OSS docker image.
# Returns "yes" if we should build it or "no" if we shouldn't.
function should_build_oss() {

  local release_type=$1
  if [[ $release_type == "ALL" || $release_type == "OSS" ]]; then
    echo "yes"
    return
  fi

  echo "no"
}

# Checks if we should build the OSS docker image.
# Returns "yes" if we should build it or "no" if we shouldn't.
function should_build_ee() {

  local release_type=$1
  if [[ $release_type == "ALL" || $release_type == "EE" ]]; then
    echo "yes"
    return
  fi
  echo "no"
}
