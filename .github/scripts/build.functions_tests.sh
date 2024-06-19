#!/usr/bin/env bash

set -eu

SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"

. "$SCRIPT_DIR"/assert.sh/assert.sh
. "$SCRIPT_DIR"/build.functions.sh

TESTS_RESULT=0

function assert_should_build_oss {
  local release_type=$1
  local expected_should_build_os=$2
  local actual=$(should_build_oss "$release_type")
  assert_eq "$expected_should_build_os" "$actual" "For release_type=$release_type we should$( [ "$expected_should_build_os" = "no" ] && echo " NOT") build OS" || TESTS_RESULT=$?
}

function assert_should_build_ee {
  local release_type=$1
  local expected_should_build_os=$2
  local actual=$(should_build_ee "$release_type")
  assert_eq "$expected_should_build_os" "$actual" "For release_type=$release_type we should$( [ "$expected_should_build_os" = "no" ] && echo " NOT") build EE" || TESTS_RESULT=$?
}

log_header "Tests for should_build_oss"
assert_should_build_oss  "ALL" "yes"
assert_should_build_oss  "OSS" "yes"
assert_should_build_oss  "EE" "no"
assert_should_build_oss  "dummy value" "no"

log_header "Tests for should_build_ee"
assert_should_build_ee  "ALL" "yes"
assert_should_build_ee  "OSS" "no"
assert_should_build_ee  "EE" "yes"
assert_should_build_ee  "dummy value" "no"

assert_eq 0 "$TESTS_RESULT" "All tests should pass"
