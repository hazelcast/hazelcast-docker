#!/usr/bin/env bash

set -eu ${RUNNER_DEBUG:+-x}

SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"

# Source the latest version of assert.sh unit testing library and include in current shell
source /dev/stdin <<< "$(curl --silent https://raw.githubusercontent.com/hazelcast/assert.sh/main/assert.sh)"

. "$SCRIPT_DIR"/packages-updated.functions.sh

TESTS_RESULT=0


function assert_packages_updatable_oss {
  local image=$1
  local expected_exit_code=$2
  packages_updatable_oss "${image}" && true
  local actual_exit_code=$?
  local msg="Expected exit code for image \"${image}\""
  assert_eq "${expected_exit_code}" "${actual_exit_code}" "${msg}" && log_success "${msg}" || TESTS_RESULT=$?
}

function assert_packages_updatable_ee {
  local image=$1
  local expected_exit_code=$2
  packages_updatable_ee "${image}" && true
  local actual_exit_code=$?
  local msg="Expected exit code for image \"${image}\""
  assert_eq "${expected_exit_code}" "${actual_exit_code}" "${msg}" && log_success "${msg}" || TESTS_RESULT=$?
}

log_header "Tests for packages_updatable_oss"
assert_packages_updatable_oss hazelcast/hazelcast:5.0.1-slim 0
# Cannot guarantee the latest upstream image is fully updated
# assert_packages_updatable_oss alpine:latest 1

log_header "Tests for packages_updatable_ee"
assert_packages_updatable_ee hazelcast/hazelcast-enterprise:5.0.1-slim 0
# Cannot guarantee the latest upstream image is fully updated
# assert_packages_updatable_ee redhat/ubi9-minimal:latest 1

assert_eq 0 "$TESTS_RESULT" "All tests should pass"
