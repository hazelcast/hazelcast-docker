#!/usr/bin/env bash

set -eu ${RUNNER_DEBUG:+-x}

SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"

# Source the latest version of assert.sh unit testing library and include in current shell
source /dev/stdin <<< "$(curl --silent https://raw.githubusercontent.com/hazelcast/assert.sh/main/assert.sh)"

. "$SCRIPT_DIR"/oss-build.functions.sh

TESTS_RESULT=0

function assert_get_hz_dist_zip {
  local hz_variant=$1
  local hz_version=$2
  local expected_url=$3
  local actual_url=$(get_hz_dist_zip "$hz_variant" "$hz_version")
  local msg="Expected URL for variant \"$hz_variant\", version \"$hz_version\""
  assert_eq "$expected_url" "$actual_url" "$msg" && log_success "$msg" || TESTS_RESULT=$?
}

log_header "Tests for get_hz_dist_zip"
assert_get_hz_dist_zip slim 5.4.0 https://repo1.maven.org/maven2/com/hazelcast/hazelcast-distribution/5.4.0/hazelcast-distribution-5.4.0-slim.zip
assert_get_hz_dist_zip "" 5.4.0 https://repo1.maven.org/maven2/com/hazelcast/hazelcast-distribution/5.4.0/hazelcast-distribution-5.4.0.zip

assert_eq 0 "$TESTS_RESULT" "All tests should pass"
