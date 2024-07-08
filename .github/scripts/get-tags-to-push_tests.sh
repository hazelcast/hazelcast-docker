#!/usr/bin/env bash

set -eu

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

. <(curl --silent https://raw.githubusercontent.com/hazelcast/assert.sh/main/assert.sh)
. "$SCRIPT_DIR"/get-tags-to-push.sh

TESTS_RESULT=0

function assert_get_version_only_tags_to_push {
  local VERSION_TO_RELEASE=$1
  local EXPECTED_TAGS_TO_PUSH=$2
  local ACTUAL_TAGS_TO_PUSH=$(get_version_only_tags_to_push "$VERSION_TO_RELEASE")
  assert_eq "$EXPECTED_TAGS_TO_PUSH" "$ACTUAL_TAGS_TO_PUSH" "Tags to push for version $VERSION_TO_RELEASE should be equal to $EXPECTED_TAGS_TO_PUSH " || TESTS_RESULT=$?
}

function assert_augment_with_suffixed_tags {
  local INITIAL_TAGS=($1)
  local SUFFIX=$2
  local CURRENT_JDK=$3
  local DEFAULT_JDK=$4
  local EXPECTED_TAGS_TO_PUSH=$5
  local ACTUAL_TAGS_TO_PUSH=$(augment_with_suffixed_tags "${INITIAL_TAGS[*]}" "$SUFFIX" "$CURRENT_JDK" "$DEFAULT_JDK")
  assert_eq "$EXPECTED_TAGS_TO_PUSH" "$ACTUAL_TAGS_TO_PUSH" "Suffixed tags to push for (tags=$INITIAL_TAGS suffix=$SUFFIX current_jdk=$CURRENT_JDK default_jdk=$DEFAULT_JDK) should be equal to: $EXPECTED_TAGS_TO_PUSH " || TESTS_RESULT=$?
}

function assert_get_tags_to_push {
  local VERSION_TO_RELEASE=$1
  local SUFFIX=$2
  local CURRENT_JDK=$3
  local DEFAULT_JDK=$4
  local EXPECTED_TAGS_TO_PUSH=$5
  local ACTUAL_TAGS_TO_PUSH=$(get_tags_to_push "$VERSION_TO_RELEASE" "$SUFFIX" "$CURRENT_JDK" "$DEFAULT_JDK")
  assert_eq "$EXPECTED_TAGS_TO_PUSH" "$ACTUAL_TAGS_TO_PUSH" "Tags to push for (version_to_release=$VERSION_TO_RELEASE suffix=$SUFFIX current_jdk=$CURRENT_JDK default_jdk=$DEFAULT_JDK) should be equal to: $EXPECTED_TAGS_TO_PUSH " || TESTS_RESULT=$?
}

log_header "Tests for get_version_only_tags_to_push"
assert_get_version_only_tags_to_push "5.2.0" "5.2.0"
assert_get_version_only_tags_to_push "5.2.1" "5.2.1"
assert_get_version_only_tags_to_push "5.1.99" "5.1.99 5.1"
assert_get_version_only_tags_to_push "4.99.0" "4.99.0 4.99 4"
assert_get_version_only_tags_to_push "99.0.0" "99.0.0 99.0 99 latest"
assert_get_version_only_tags_to_push "5.3.0-BETA-1" "5.3.0-BETA-1"
assert_get_version_only_tags_to_push "5.4.0-DEVEL-9" "5.4.0-DEVEL-9"
assert_get_version_only_tags_to_push "5.99.0-BETA-1" "5.99.0-BETA-1"
assert_get_version_only_tags_to_push "99.0.0-BETA-1" "99.0.0-BETA-1"

log_header "Tests for augment_with_suffixed_tags"
assert_augment_with_suffixed_tags "1.2.3" "" "11" "11" "1.2.3 1.2.3-jdk11"
assert_augment_with_suffixed_tags "1.2.3 latest" "" "11" "11" "1.2.3 1.2.3-jdk11 latest latest-jdk11"
assert_augment_with_suffixed_tags "1.2.3" "" "17" "11" "1.2.3-jdk17"
assert_augment_with_suffixed_tags "1.2.3 latest" "" "17" "11" "1.2.3-jdk17 latest-jdk17"
assert_augment_with_suffixed_tags "1.2.3" "-slim" "11" "11" "1.2.3-slim 1.2.3-slim-jdk11"
assert_augment_with_suffixed_tags "1.2.3" "-slim" "17" "11" "1.2.3-slim-jdk17"
assert_augment_with_suffixed_tags "1.2.3 latest" "-slim" "17" "11" "1.2.3-slim-jdk17 latest-slim-jdk17"
tags_array=(1.2.3 latest)
assert_augment_with_suffixed_tags "${tags_array[*]}" "-slim" "17" "11" "1.2.3-slim-jdk17 latest-slim-jdk17"
assert_augment_with_suffixed_tags "1.2.3 1.2" "-slim" "17" "11" "1.2.3-slim-jdk17 1.2-slim-jdk17"

log_header "Tests for get_tags_to_push"
assert_get_tags_to_push "5.2.0" "" "11" "11" "5.2.0 5.2.0-jdk11"
assert_get_tags_to_push "99.0.0" "" "11" "11" "99.0.0 99.0.0-jdk11 99.0 99.0-jdk11 99 99-jdk11 latest latest-jdk11"
assert_get_tags_to_push "99.0.0-BETA-1" "" "17" "11" "99.0.0-BETA-1-jdk17"
assert_get_tags_to_push "5.4.0-DEVEL-9" "-slim" "17" "11" "5.4.0-DEVEL-9-slim-jdk17"

assert_eq 0 "$TESTS_RESULT" "All tests should pass"
