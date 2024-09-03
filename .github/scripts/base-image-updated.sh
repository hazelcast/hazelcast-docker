#!/bin/bash

function findScriptDir() {
  CURRENT=$PWD

  DIR=$(dirname "$0")
  cd "$DIR" || exit
  TARGET_FILE=$(basename "$0")

  # Iterate down a (possible) chain of symlinks
  while [ -L "$TARGET_FILE" ]; do
    TARGET_FILE=$(readlink "$TARGET_FILE")
    DIR=$(dirname "$TARGET_FILE")
    cd "$DIR" || exit
    TARGET_FILE=$(basename "$TARGET_FILE")
  done

  SCRIPT_DIR=$(pwd -P)
  # Restore current directory
  cd "$CURRENT" || exit
}

findScriptDir

function get_base_image_name() {
  local DOCKERFILE=$1
  grep '^FROM ' $DOCKERFILE | cut -d' ' -f2
}

function base_image_updated() {
  local CURRENT_IMAGE=$1
  local DOCKERFILE=$2
  local BASE_IMAGE=$(get_base_image_name "$DOCKERFILE")
  docker pull "$BASE_IMAGE"
  docker pull "$CURRENT_IMAGE"
  local BASE_IMAGE_SHA=$(docker image inspect "$BASE_IMAGE" | jq -r '.[].RootFS.Layers[0]')
  local CURRENT_IMAGE_SHA=$(docker image inspect "$CURRENT_IMAGE" | jq -r '.[].RootFS.Layers[0]')
  if [ "$CURRENT_IMAGE_SHA" = "$BASE_IMAGE_SHA" ]; then
    return 1
  fi
  return 0
}
