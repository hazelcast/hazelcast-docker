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
. "$SCRIPT_DIR"/get-supported-versions.sh

TESTS_RESULT=0

function assert_supported_versions_contain {
  local MINIMAL_SUPPORTED_VERSION=$1
  local EXPECTED_VERSION=$2
  local ACTUAL_SUPPORTED_VERSIONS=$(get_supported_versions "$MINIMAL_SUPPORTED_VERSION")
  assert_contain "$ACTUAL_SUPPORTED_VERSIONS" "$EXPECTED_VERSION" "Versions starting from $MINIMAL_SUPPORTED_VERSION should contain $EXPECTED_VERSION " || TESTS_RESULT=$?
}

function assert_supported_versions_not_contain {
  local MINIMAL_SUPPORTED_VERSION=$1
  local EXPECTED_VERSION=$2
  local ACTUAL_SUPPORTED_VERSIONS=$(get_supported_versions "$MINIMAL_SUPPORTED_VERSION")
  assert_not_contain "$ACTUAL_SUPPORTED_VERSIONS" "$EXPECTED_VERSION" "Versions starting from $MINIMAL_SUPPORTED_VERSION should NOT contain $EXPECTED_VERSION " || TESTS_RESULT=$?
}

log_header "Tests for get_supported_versions"
assert_supported_versions_contain "4.2" "4.2.7"
assert_supported_versions_contain "4.2" "5.0"
assert_supported_versions_contain "4.2" "5.1.5"
assert_supported_versions_contain "5.0" "5.2.3"
assert_supported_versions_contain "5.1-BETA-1" "5.1.5"
assert_supported_versions_not_contain "4.2" "5.3.0-BETA-1"
assert_supported_versions_not_contain "5.1.3" "4.2.1"
assert_supported_versions_not_contain "5.1.3" "99.0.0"
assert_supported_versions_not_contain "5.1-BETA-1" "5.0.1"

assert_eq 0 "$TESTS_RESULT" "All tests should pass"
