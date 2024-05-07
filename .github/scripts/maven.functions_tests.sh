#!/usr/bin/env bash

set -eu

function find_script_dir() {
  CURRENT=$PWD

  DIR=$(dirname "$0")
  cd "$DIR" || exit
  TARGET_FILE=$(basename "$0")

  while [ -L "$TARGET_FILE" ]
  do
      TARGET_FILE=$(readlink "$TARGET_FILE")
      DIR=$(dirname "$TARGET_FILE")
      cd "$DIR" || exit
      TARGET_FILE=$(basename "$TARGET_FILE")
  done

  local SCRIPT_DIR=$(pwd -P)
  cd "$CURRENT" || exit
  echo "$SCRIPT_DIR"
}

SCRIPT_DIR=$(find_script_dir)

. "$SCRIPT_DIR"/assert.sh/assert.sh
. "$SCRIPT_DIR"/maven.functions.sh

TESTS_RESULT=0

function assert_get_latest_version {
  local groupId=$1
  local artifactId=$2
  local expected_version=$3
  local actual_version=$(get_latest_version "$groupId" "$artifactId")
  assert_eq "$expected_version" "$actual_version" "Latest version of $groupId:$artifactId expected to be equal to $expected_version " || TESTS_RESULT=$?
}

function assert_get_latest_url_without_extension {
  local groupId=$1
  local artifactId=$2
  local expected_url=$3
  local actual_url=$(get_latest_url_without_extension "$groupId" "$artifactId")
  assert_eq "$expected_url" "$actual_url" "Latest URL of $groupId:$artifactId expected to be equal to $expected_url " || TESTS_RESULT=$?
}

log_header "Tests for get_latest_version"
assert_get_latest_version com.google.guava listenablefuture 9999.0-empty-to-avoid-conflict-with-guava

log_header "Tests for get_latest_url_without_extension"
get_latest_url_without_extension com.google.guava listenablefuture https://repo1.maven.org/maven2/com/google/guava/listenablefuture/9999.0-empty-to-avoid-conflict-with-guava/listenablefuture-9999.0-empty-to-avoid-conflict-with-guava

assert_eq 0 "$TESTS_RESULT" "All tests should pass"
