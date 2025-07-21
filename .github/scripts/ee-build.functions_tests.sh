#!/usr/bin/env bash

set -eu ${RUNNER_DEBUG:+-x}

SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"

# Source the latest version of assert.sh unit testing library and include in current shell
source /dev/stdin <<< "$(curl --silent https://raw.githubusercontent.com/hazelcast/assert.sh/main/assert.sh)"

. "$SCRIPT_DIR"/ee-build.functions.sh

TESTS_RESULT=0

function assert_get_hz_dist_zip {
  local hz_variant=$1
  local hz_version=$2
  local expected_url=$3
  local actual_url=$(get_hz_dist_zip "$hz_variant" "$hz_version")
  local MSG="Expected URL for variant \"$hz_variant\", version \"$hz_version\""
  assert_eq "$expected_url" "$actual_url" "$MSG" && log_success "$MSG" || TESTS_RESULT=$?
}

function assert_get_hz_dist_zip_for_snapshot {
  local hz_variant=$1
  local hz_version=$2
  local expected_url=$3
  local actual_url=$(get_hz_dist_zip "$hz_variant" "$hz_version")
  local MSG="Expected URL for variant \"$hz_variant\", version \"$hz_version\" should contain $expected_url"
  assert_contain "$actual_url" "$expected_url" "$MSG" && log_success "$MSG" || TESTS_RESULT=$?
}

log_header "Tests for get_hz_dist_zip"
assert_get_hz_dist_zip slim 5.4.0 https://repository.hazelcast.com/release/com/hazelcast/hazelcast-enterprise-distribution/5.4.0/hazelcast-enterprise-distribution-5.4.0-slim.zip
assert_get_hz_dist_zip "" 5.4.0 https://repository.hazelcast.com/release/com/hazelcast/hazelcast-enterprise-distribution/5.4.0/hazelcast-enterprise-distribution-5.4.0.zip
assert_get_hz_dist_zip "" 5.4.1-SNAPSHOT https://repository.hazelcast.com/snapshot/com/hazelcast/hazelcast-enterprise-distribution/5.4.1-SNAPSHOT/hazelcast-enterprise-distribution-5.4.1-SNAPSHOT.zip

assert_eq 0 "$TESTS_RESULT" "All tests should pass"
