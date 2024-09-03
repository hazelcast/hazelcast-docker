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


function packages_updated_oss() {
  local IMAGE=$1
  docker pull "$IMAGE"
  local OUTPUT=$(docker run --user 0 --rm $IMAGE sh -c 'apk update && apk upgrade -s')
  echo "$OUTPUT"
  PACKAGE_UPGRADES=$(echo "$OUTPUT" | grep --count Upgrading)
  if [ "$PACKAGE_UPGRADES" -ne 0 ]; then
        return 0
  fi
  return 1
}

function packages_updated_ee() {
  local IMAGE=$1
  docker pull "$IMAGE"
  local OUTPUT=$(docker run --user 0 --rm $IMAGE sh -c 'microdnf -y upgrade --nodocs')
  echo "$OUTPUT"
  PACKAGE_UPGRADES=$(echo "$OUTPUT" | grep --count Upgrading)
  if [ "$PACKAGE_UPGRADES" -ne 0 ]; then
        return 0
  fi
  return 1
}
