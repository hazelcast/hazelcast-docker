#!/usr/bin/env bash

set -eu ${RUNNER_DEBUG:+-x}

SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"

# Source the latest version of assert.sh unit testing library and include in current shell
source /dev/stdin <<< "$(curl --silent https://raw.githubusercontent.com/hazelcast/assert.sh/main/assert.sh)"

. "$SCRIPT_DIR"/get-tags-to-push.sh

TESTS_RESULT=0

function assert_get_version_only_tags_to_push {
  local VERSION_TO_RELEASE=$1
  local IS_LTS=$2
  local EXPECTED_TAGS_TO_PUSH=$3
  local ACTUAL_TAGS_TO_PUSH=$(__get_version_only_tags_to_push "$VERSION_TO_RELEASE" "$IS_LTS")
  local MSG="Tags to push for version $VERSION_TO_RELEASE and is_lts = '$IS_LTS' should be equal to $EXPECTED_TAGS_TO_PUSH, not $ACTUAL_TAGS_TO_PUSH"
  assert_eq "$EXPECTED_TAGS_TO_PUSH" "$ACTUAL_TAGS_TO_PUSH" "$MSG" && log_success "$MSG" || TESTS_RESULT=$?
}

function assert_augment_with_suffixed_tags {
  local INITIAL_TAGS=($1)
  local SUFFIX=$2
  local CURRENT_JDK=$3
  local DEFAULT_JDK=$4
  local EXPECTED_TAGS_TO_PUSH=$5
  local ACTUAL_TAGS_TO_PUSH=$(augment_with_suffixed_tags "${INITIAL_TAGS[*]}" "$SUFFIX" "$CURRENT_JDK" "$DEFAULT_JDK")
  local MSG="Suffixed tags to push for (tags=$INITIAL_TAGS suffix=$SUFFIX current_jdk=$CURRENT_JDK default_jdk=$DEFAULT_JDK) should be equal to: $EXPECTED_TAGS_TO_PUSH"
  assert_eq "$EXPECTED_TAGS_TO_PUSH" "$ACTUAL_TAGS_TO_PUSH" "$MSG" && log_success "$MSG" || TESTS_RESULT=$?
}

function assert_get_tags_to_push {
  local VERSION_TO_RELEASE=$1
  local SUFFIX=$2
  local CURRENT_JDK=$3
  local DEFAULT_JDK=$4
  local IS_LATEST_LTS=$5
  local EXPECTED_TAGS_TO_PUSH=$6
  local ACTUAL_TAGS_TO_PUSH=$(get_tags_to_push "$VERSION_TO_RELEASE" "$SUFFIX" "$CURRENT_JDK" "$DEFAULT_JDK" "$IS_LATEST_LTS")
  local MSG="Tags to push for (version_to_release=$VERSION_TO_RELEASE suffix=$SUFFIX current_jdk=$CURRENT_JDK default_jdk=$DEFAULT_JDK is_latest_lts=$IS_LATEST_LTS) should be equal to: $EXPECTED_TAGS_TO_PUSH "
  assert_eq "$EXPECTED_TAGS_TO_PUSH" "$ACTUAL_TAGS_TO_PUSH" "$MSG" && log_success "$MSG" || TESTS_RESULT=$?
}

log_header "Tests for get_version_only_tags_to_push"
assert_get_version_only_tags_to_push "5.2.0" "false" "5.2.0"
assert_get_version_only_tags_to_push "5.2.1" "false" "5.2.1"
assert_get_version_only_tags_to_push "5.1.99" "false" "5.1.99 5.1"
assert_get_version_only_tags_to_push "4.99.0" "false" "4.99.0 4.99 4"
assert_get_version_only_tags_to_push "99.0.0" "false" "99.0.0 99.0 99 latest"
assert_get_version_only_tags_to_push "5.3.0-BETA-1" "false" "5.3.0-BETA-1"
assert_get_version_only_tags_to_push "5.4.0-DEVEL-9" "false" "5.4.0-DEVEL-9"
assert_get_version_only_tags_to_push "5.99.0-BETA-1" "false" "5.99.0-BETA-1"
assert_get_version_only_tags_to_push "99.0.0-BETA-1" "false" "99.0.0-BETA-1"
assert_get_version_only_tags_to_push "99.0.0" "true" "99.0.0 99.0 99 latest-lts latest"
assert_get_version_only_tags_to_push "5.2.0" "true" "5.2.0 latest-lts"

log_header "Tests for augment_with_suffixed_tags"
assert_augment_with_suffixed_tags "1.2.3" "" "11" "11" "1.2.3-jdk11 1.2.3"
assert_augment_with_suffixed_tags "1.2.3 latest" "" "11" "11" "1.2.3-jdk11 1.2.3 latest-jdk11 latest"
assert_augment_with_suffixed_tags "1.2.3" "" "17" "11" "1.2.3-jdk17"
assert_augment_with_suffixed_tags "1.2.3 latest" "" "17" "11" "1.2.3-jdk17 latest-jdk17"
assert_augment_with_suffixed_tags "1.2.3" "-slim" "11" "11" "1.2.3-slim-jdk11 1.2.3-slim"
assert_augment_with_suffixed_tags "1.2.3" "-slim" "17" "11" "1.2.3-slim-jdk17"
assert_augment_with_suffixed_tags "1.2.3 latest" "-slim" "17" "11" "1.2.3-slim-jdk17 latest-slim-jdk17"
assert_augment_with_suffixed_tags "1.2.3 latest-lts" "-slim" "17" "11" "1.2.3-slim-jdk17 latest-lts-slim-jdk17"
tags_array=(1.2.3 latest)
assert_augment_with_suffixed_tags "${tags_array[*]}" "-slim" "17" "11" "1.2.3-slim-jdk17 latest-slim-jdk17"
assert_augment_with_suffixed_tags "1.2.3 1.2" "-slim" "17" "11" "1.2.3-slim-jdk17 1.2-slim-jdk17"

log_header "Tests for get_tags_to_push"
assert_get_tags_to_push "5.2.0" "" "11" "11" "false" "5.2.0-jdk11 5.2.0"
assert_get_tags_to_push "99.0.0" "" "11" "11" "false" "99.0.0-jdk11 99.0.0 99.0-jdk11 99.0 99-jdk11 99 latest-jdk11 latest"
assert_get_tags_to_push "99.0.0-BETA-1" "" "17" "11" "false" "99.0.0-BETA-1-jdk17"
assert_get_tags_to_push "5.4.0-DEVEL-9" "-slim" "17" "false" "11" "5.4.0-DEVEL-9-slim-jdk17"
assert_get_tags_to_push "5.2.0" "" "11" "11" "true" "5.2.0-jdk11 5.2.0 latest-lts-jdk11 latest-lts"
assert_get_tags_to_push "99.0.0" "" "11" "11" "true" "99.0.0-jdk11 99.0.0 99.0-jdk11 99.0 99-jdk11 99 latest-lts-jdk11 latest-lts latest-jdk11 latest"

assert_eq 0 "$TESTS_RESULT" "All tests should pass"
