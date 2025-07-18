#!/usr/bin/env bash

set -eu ${RUNNER_DEBUG:+-x}

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
# Assuming the latest upstream image is fully updated
assert_packages_updatable_oss alpine:latest 1

log_header "Tests for packages_updatable_ee"
assert_packages_updatable_ee hazelcast/hazelcast-enterprise:5.0.1-slim 0
# Assuming the latest upstream image is fully updated
assert_packages_updatable_ee redhat/ubi9-minimal:latest 1

assert_eq 0 "$TESTS_RESULT" "All tests should pass"
