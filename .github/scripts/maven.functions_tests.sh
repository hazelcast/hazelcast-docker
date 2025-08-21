#!/usr/bin/env bash

set -eu ${RUNNER_DEBUG:+-x}

SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"

# Source the latest version of assert.sh unit testing library and include in current shell
source /dev/stdin <<< "$(curl --silent https://raw.githubusercontent.com/hazelcast/assert.sh/main/assert.sh)"

TESTS_RESULT=0

# Functions overlap, so likely only testing one implementation - but as are duplicated, *shouldn't* be an issue
OSS_SCRIPT="$SCRIPT_DIR"/../../hazelcast-oss/maven.functions.sh
EE_SCRIPT="$SCRIPT_DIR"/../../hazelcast-enterprise/maven.functions.sh
MSG="Contents of $OSS_SCRIPT and $EE_SCRIPT should be the same"
assert_eq "$(cat "$OSS_SCRIPT")" "$(cat "$EE_SCRIPT")" "$MSG" && log_success "$MSG" || TESTS_RESULT=$?

. "$OSS_SCRIPT"
. "$EE_SCRIPT"


function assert_get_latest_version {
  local group_id=$1
  local artifact_id=$2
  local repository_url=$3
  local expected_version=$4
  local actual_version=$(get_latest_version "$group_id" "$artifact_id" "$repository_url")
  local msg="Latest version of $group_id:$artifact_id expected to be equal to $expected_version"
  assert_eq "$expected_version" "$actual_version" "$msg" && log_success "$msg" || TESTS_RESULT=$?
}


function assert_get_latest_url_without_extension {
  local group_id=$1
  local artifact_id=$2
  local repository_url=$3
  local expected_url=$4
  local actual_url=$(get_latest_url_without_extension "$group_id" "$artifact_id" "$repository_url")
  local msg="Latest URL of $group_id:$artifact_id expected to be equal to $expected_url"
  assert_eq "$expected_url" "$actual_url" "$msg" && log_success "$msg" || TESTS_RESULT=$?
}

log_header "Tests for get_latest_version"
assert_get_latest_version com.google.guava listenablefuture https://repo.maven.apache.org/maven2 9999.0-empty-to-avoid-conflict-with-guava
assert_get_latest_version com.google.guava listenablefuture https://maven-central.storage.googleapis.com/maven2 9999.0-empty-to-avoid-conflict-with-guava

log_header "Tests for get_latest_url_without_extension"
assert_get_latest_url_without_extension com.google.guava listenablefuture https://repo.maven.apache.org/maven2 https://repo.maven.apache.org/maven2/com/google/guava/listenablefuture/9999.0-empty-to-avoid-conflict-with-guava/listenablefuture-9999.0-empty-to-avoid-conflict-with-guava
assert_get_latest_url_without_extension com.google.guava listenablefuture https://maven-central.storage.googleapis.com/maven2 https://maven-central.storage.googleapis.com/maven2/com/google/guava/listenablefuture/9999.0-empty-to-avoid-conflict-with-guava/listenablefuture-9999.0-empty-to-avoid-conflict-with-guava

assert_eq 0 "$TESTS_RESULT" "All tests should pass"
