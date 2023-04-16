#!/usr/bin/env bash

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

. "$SCRIPT_DIR"/assert.sh/assert.sh
. "$SCRIPT_DIR"/get-tags-to-push.sh

TESTS_RESULT=0

function assert_tags_to_push {
  local VERSION_TO_RELEASE=$1
  local EXPECTED_TAGS_TO_PUSH=$2
  local ACTUAL_TAGS_TO_PUSH=$(get_tags_to_push "$VERSION_TO_RELEASE")
  assert_eq "$EXPECTED_TAGS_TO_PUSH" "$ACTUAL_TAGS_TO_PUSH" "Tags to push for version $VERSION_TO_RELEASE should be equal to $EXPECTED_TAGS_TO_PUSH " || TESTS_RESULT=$?
}

log_header "Tests for get_tags_to_push"
assert_tags_to_push "5.2.0" "5.2.0"
assert_tags_to_push "5.2.1" "5.2.1"
assert_tags_to_push "5.1.99" "5.1.99 5.1"
assert_tags_to_push "5.99.0" "5.99.0 5.99 5 latest" #this needs adjustment when we release 6.0
assert_tags_to_push "99.0.0" "99.0.0 99.0 99 latest"
assert_tags_to_push "5.3.0-BETA-1" "5.3.0-BETA-1"
assert_tags_to_push "5.99.0-BETA-1" "5.99.0-BETA-1"
assert_tags_to_push "99.0.0-BETA-1" "99.0.0-BETA-1"

assert_eq 0 "$TESTS_RESULT" "All tests should pass"
