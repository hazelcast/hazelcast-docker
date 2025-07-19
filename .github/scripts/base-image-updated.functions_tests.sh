#!/usr/bin/env bash

set -eu ${RUNNER_DEBUG:+-x}

SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"

# Source the latest version of assert.sh unit testing library and include in current shell
source /dev/stdin <<< "$(curl --silent https://raw.githubusercontent.com/hazelcast/assert.sh/main/assert.sh)"

. "$SCRIPT_DIR"/base-image-updated.functions.sh

TESTS_RESULT=0

function assert_base_image_outdated {
  local current_image=$1
  local base_image=$2
  local expected_exit_code=$3
  base_image_outdated "${current_image}" "${base_image}" && true
  local actual_exit_code=$?
  local msg="Expected exit code for \"${current_image}\" compared to \"${base_image}\""
  assert_eq "${expected_exit_code}" "${actual_exit_code}" "${msg}" && log_success "${msg}" || TESTS_RESULT=$?
}

log_header "Tests for base_image_outdated"
assert_base_image_outdated alpine:latest alpine:latest 1
assert_base_image_outdated hazelcast/hazelcast:5.0.1-slim alpine:latest 0

assert_eq 0 "$TESTS_RESULT" "All tests should pass"
