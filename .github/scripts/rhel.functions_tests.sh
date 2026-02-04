#!/usr/bin/env bash

SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"

# Source the latest version of assert.sh unit testing library and include in current shell
source /dev/stdin <<< "$(curl --silent https://raw.githubusercontent.com/hazelcast/assert.sh/main/assert.sh)"

. "$SCRIPT_DIR"/rhel.functions.sh

TESTS_RESULT=0

function assert_contains_all_expected_tags {
  local actual_tags=$1
  local expected_tags=$2
  local expected_exit_code
  expected_exit_code=$3
  contains_all_expected_tags "${actual_tags}" "${expected_tags}" && true
  local actual_exit_code=$?
  local msg="Expected exit code for \"${actual_tags}\" compared to \"${expected_tags}\""
  assert_eq "${expected_exit_code}" "${actual_exit_code}" "${msg}" && log_success "${msg}" || TESTS_RESULT=$?
}

log_header "Tests for contains_all_expected_tags"
assert_contains_all_expected_tags "4.2.1" "4.2.1" 0
assert_contains_all_expected_tags "4.2.1" "4.2 4.2.1" 0
assert_contains_all_expected_tags "4.2.1" "4.2.1 4.2" 0
assert_contains_all_expected_tags "4.2" "4.1 4.2 4.3" 0

assert_contains_all_expected_tags "4.2" "" 1
assert_contains_all_expected_tags "4.2" "4.1" 1
assert_contains_all_expected_tags "4.2" "4.2.1" 1
assert_contains_all_expected_tags "4.2" "4.1 4.3" 1

assert_eq 0 "${TESTS_RESULT}" "All tests should pass"
