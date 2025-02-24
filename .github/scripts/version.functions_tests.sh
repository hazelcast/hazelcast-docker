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
. "$SCRIPT_DIR"/version.functions.sh

TESTS_RESULT=0

function assert_minor_versions_contain {
  local MINIMAL_SUPPORTED_VERSION=$1
  local EXPECTED_VERSION=$2
  local ACTUAL_MINOR_VERSIONS=$(get_minor_versions "$MINIMAL_SUPPORTED_VERSION")
  assert_contain "$ACTUAL_MINOR_VERSIONS" "$EXPECTED_VERSION" "Minor versions starting from $MINIMAL_SUPPORTED_VERSION should contain $EXPECTED_VERSION " || TESTS_RESULT=$?
}

function assert_minor_versions_not_contain {
  local MINIMAL_SUPPORTED_VERSION=$1
  local EXPECTED_VERSION=$2
  local ACTUAL_MINOR_VERSIONS=$(get_minor_versions "$MINIMAL_SUPPORTED_VERSION")
  assert_not_contain "$ACTUAL_MINOR_VERSIONS" "$EXPECTED_VERSION" "Minor versions starting from $MINIMAL_SUPPORTED_VERSION should NOT contain $EXPECTED_VERSION " || TESTS_RESULT=$?
}

function assert_latest_patch_version {
  local MINOR_VERSION=$1
  local EXPECTED_VERSION=$2
  local ACTUAL_VERSION=$(get_latest_patch_version "$MINOR_VERSION")
  assert_eq "$ACTUAL_VERSION" "$EXPECTED_VERSION" "Latest patch version of $MINOR_VERSION should be $EXPECTED_VERSION " || TESTS_RESULT=$?
}


function assert_latest_patch_versions_contain {
  local MINIMAL_SUPPORTED_VERSION=$1
  local EXPECTED_VERSION=$2
  local ACTUAL_LATEST_PATCH_VERSIONS=$(get_latest_patch_versions "$MINIMAL_SUPPORTED_VERSION")
  assert_contain "$ACTUAL_LATEST_PATCH_VERSIONS" "$EXPECTED_VERSION" "Latest patch versions starting from $MINIMAL_SUPPORTED_VERSION should contain $EXPECTED_VERSION " || TESTS_RESULT=$?
}

function assert_latest_patch_versions_not_contain {
  local MINIMAL_SUPPORTED_VERSION=$1
  local EXPECTED_VERSION=$2
  local ACTUAL_LATEST_PATCH_VERSIONS=$(get_latest_patch_versions "$MINIMAL_SUPPORTED_VERSION")
  assert_not_contain "$ACTUAL_LATEST_PATCH_VERSIONS" "$EXPECTED_VERSION" "Latest patch versions starting from $MINIMAL_SUPPORTED_VERSION should NOT contain $EXPECTED_VERSION " || TESTS_RESULT=$?
}

function assert_get_last_version_tag_from_github {
  local REPO=$1
  local EXPECTED_TAG=$2
  local ACTUAL_TAG=$(get_last_version_tag_from_github "${REPO}")
  assert_eq "${ACTUAL_TAG}" "${EXPECTED_TAG}" "Last tag of ${REPO} should be ${EXPECTED_TAG} " || TESTS_RESULT=$?
}

log_header "Tests for get_latest_patch_version"
assert_latest_patch_version "4.2.1" "4.2.8"
assert_latest_patch_version "4.2" "4.2.8"
assert_latest_patch_version "4.2" "4.2.8"
assert_latest_patch_version "4.0" "4.0.6"
assert_latest_patch_version "4.1-BETA-1" "4.1.10"
assert_latest_patch_version "4.1" "4.1.10"
assert_latest_patch_version "3.9" "3.9.4"

log_header "Tests for get_minor_versions"
assert_minor_versions_contain "3.12" "3.12"
assert_minor_versions_contain "4.2" "4.2"
assert_minor_versions_contain "4.2" "5.0"
assert_minor_versions_contain "4.2" "5.1"
assert_minor_versions_contain "4.2" "5.2"
assert_minor_versions_not_contain "4.2" "4.1"
assert_minor_versions_not_contain "4.2" "4.0"
assert_minor_versions_not_contain "4.2" "3.9"

log_header "Tests for get_latest_patch_versions"
assert_latest_patch_versions_contain "3.9" "3.9.4"
assert_latest_patch_versions_contain "3.12" "3.12.12-1"
assert_latest_patch_versions_contain "4.0.1" "4.0.6"
assert_latest_patch_versions_contain "4.0-BETA-2" "4.0.6"
assert_latest_patch_versions_contain "4.1" "4.1.10"
assert_latest_patch_versions_not_contain "3.12" "3.12.11"
assert_latest_patch_versions_not_contain "4.2" "3.9.4"
assert_latest_patch_versions_not_contain "4.2" "4.1.10"
LATEST_5_4_DEVEL="$(git tag | sort -V | grep 'v5.4.0-DEVEL-' | tail -n 1 | cut -c2-)"
assert_latest_patch_versions_not_contain "5.3" "$LATEST_5_4_DEVEL"

log_header "Tests for get_last_version_tag_from_github"
# Use archived repos for tests to ensure constant results
assert_get_last_version_tag_from_github hazelcast/management-center-openshift v5.3.2
assert_get_last_version_tag_from_github hazelcast/hazelcast-jet v4.5.4

assert_eq 0 "$TESTS_RESULT" "All tests should pass"
