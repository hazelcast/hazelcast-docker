#!/usr/bin/env bash

set -eu

SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"

# Source the latest version of assert.sh unit testing library and include in current shell
assert_script_content=$(curl --silent https://raw.githubusercontent.com/hazelcast/assert.sh/main/assert.sh)
# shellcheck source=/dev/null
. <(echo "${assert_script_content}")
. "$SCRIPT_DIR"/build.functions.sh

TESTS_RESULT=0

function assert_should_build_oss {
  local release_type=$1
  local expected_should_build_os=$2
  local actual=$(should_build_oss "$release_type")
  local MSG="For release_type=$release_type we should$( [ "$expected_should_build_os" = "no" ] && echo " NOT") build OS"
  assert_eq "$expected_should_build_os" "$actual" "$MSG" && log_success "$MSG" || TESTS_RESULT=$?
}

function assert_should_build_ee {
  local release_type=$1
  local expected_should_build_ee=$2
  local actual=$(should_build_ee "$release_type")
  local MSG="For release_type=$release_type we should$( [ "$expected_should_build_ee" = "no" ] && echo " NOT") build EE"
  assert_eq "$expected_should_build_ee" "$actual" "$MSG" && log_success "$MSG" || TESTS_RESULT=$?
}

function assert_should_build_readme_ee {
  local release_type=$1
  local expected_should_build_ee=$2
  local actual=$(should_build_readme_ee "$release_type")
  local MSG="For release_type=$release_type we should$( [ "$expected_should_build_ee" = "no" ] && echo " NOT") build Readme EE"
  assert_eq "$expected_should_build_ee" "$actual" "$MSG" && log_success "$MSG" || TESTS_RESULT=$?
}

function assert_should_build_readme_oss {
  local release_type=$1
  local expected_should_build_readme_oss=$2
  local actual=$(should_build_readme_oss "$release_type")
  local MSG="For release_type=$release_type we should$( [ "$expected_should_build_readme_oss" = "no" ] && echo " NOT") build Readme OSS"
  assert_eq "$expected_should_build_readme_oss" "$actual" "$MSG" && log_success "$MSG" || TESTS_RESULT=$?
}

log_header "Tests for should_build_oss"
assert_should_build_oss  "ALL" "yes"
assert_should_build_oss  "OSS" "yes"
assert_should_build_oss  "EE" "no"
assert_should_build_oss  "README" "no"
assert_should_build_oss  "dummy value" "no"

log_header "Tests for should_build_ee"
assert_should_build_ee  "ALL" "yes"
assert_should_build_ee  "OSS" "no"
assert_should_build_ee  "EE" "yes"
assert_should_build_ee  "README" "no"
assert_should_build_ee  "dummy value" "no"

log_header "Tests for should_build_readme_oss"
assert_should_build_readme_oss  "ALL" "yes"
assert_should_build_readme_oss  "OSS" "yes"
assert_should_build_readme_oss  "oss" "no"
assert_should_build_readme_oss  "EE" "no"
assert_should_build_readme_oss  "README" "yes"
assert_should_build_readme_oss  "dummy value" "no"

log_header "Tests for should_build_readme_ee"
assert_should_build_readme_ee  "ALL" "yes"
assert_should_build_readme_ee  "OSS" "no"
assert_should_build_readme_ee  "EE" "yes"
assert_should_build_readme_ee  "ee" "no"
assert_should_build_readme_ee  "README" "yes"
assert_should_build_readme_ee  "dummy value" "no"


assert_eq 0 "$TESTS_RESULT" "All tests should pass"
