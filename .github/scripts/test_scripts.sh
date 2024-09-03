#!/bin/bash

function findScriptDir() {
  CURRENT=$PWD

  DIR=$(dirname "$0")
  cd "$DIR" || exit
  TARGET_FILE=$(basename "$0")

  # Iterate down a (possible) chain of symlinks
  while [ -L "$TARGET_FILE" ]
  do
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

find "$SCRIPT_DIR" -name "*_tests.sh" -print0 | xargs -0 -n1 bash
