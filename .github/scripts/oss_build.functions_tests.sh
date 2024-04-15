#!/usr/bin/env bash

set -eu
function findScriptDir() {
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

  SCRIPT_DIR=$(pwd -P)
  cd "$CURRENT" || exit
}

findScriptDir

. "$SCRIPT_DIR"/assert.sh/assert.sh
. "$SCRIPT_DIR"/oss_build.functions.sh

TESTS_RESULT=0

function assert_get_patch_part {
  local version_to_release=$1
  local expected=$2
  local actual=$(get_patch_part "$version_to_release")
  assert_eq "$expected" "$actual" "Expected patch part for version $version_to_release should be equal to $expected " || TESTS_RESULT=$?
}

function assert_is_patch_release {
  local version_to_release=$1
  local expected="yes"
  local actual=$(is_patch_release "$version_to_release")
  assert_eq "$expected" "$actual" "Version $version_to_release should be patch release" || TESTS_RESULT=$?
}

function assert_is_numeric {
  local str=$1
  local expected=$2
  local actual=$(is_numeric "$str"; echo $?)
  assert_eq "$expected" "$actual" "String $str should$( [ "$expected" != 0 ] && echo " NOT") be numeric" || TESTS_RESULT=$?
}

function assert_should_build_os {
  local os_version=$1
  local ee_version=$2
  local triggered_by=$3
  local editions=$4
  local expected_should_build_os=$5
  local actual=$(should_build_oss "$os_version" "$ee_version" "$triggered_by" "$editions")
  assert_eq "$expected_should_build_os" "$actual" "For OS=$os_version EE=$ee_version triggered_by=$triggered_by editions=$editions we should$( [ "$expected_should_build_os" = "no" ] && echo " NOT") build OS" || TESTS_RESULT=$?
}

log_header "Tests for get_patch_part"
assert_get_patch_part "5.2.0" "0"
assert_get_patch_part "5.2.1" "1"
assert_get_patch_part "5.1.99" "99"
assert_get_patch_part "5.3.0-BETA-1" "0-BETA-1"
assert_get_patch_part "5.4.0-DEVEL-9" "0-DEVEL-9"

log_header "Tests for is_numeric"
assert_is_numeric "0" 0
assert_is_numeric "1" 0
assert_is_numeric "0-BETA-1" 1
assert_is_numeric "0-DEVEL-9" 1
assert_is_numeric "0-SNAPSHOT" 1

log_header "Tests for should_build_oss"
assert_should_build_os "5.0.0" "5.0.0" "push" "All" "yes"
assert_should_build_os "5.0.0" "5.0.0" "push" "OSS" "yes"
assert_should_build_os "5.0.0" "5.0.0" "push" "EE" "yes"
assert_should_build_os "5.0.0" "5.0.0" "workflow_dispatch" "All" "yes"
assert_should_build_os "5.0.0" "5.0.0" "workflow_dispatch" "OSS" "yes"
assert_should_build_os "5.0.0" "5.0.0" "workflow_dispatch" "EE" "no"

assert_should_build_os "5.0.0" "5.0.1" "push" "All" "no"
assert_should_build_os "5.0.0" "5.0.1" "push" "OSS" "no"
assert_should_build_os "5.0.0" "5.0.1" "push" "EE" "no"
assert_should_build_os "5.0.0" "5.0.1" "workflow_dispatch" "All" "yes"
assert_should_build_os "5.0.0" "5.0.1" "workflow_dispatch" "OSS" "yes"
assert_should_build_os "5.0.0" "5.0.1" "workflow_dispatch" "EE" "no"

assert_should_build_os "5.0.1" "5.0.1" "push" "All" "yes"
assert_should_build_os "5.0.1" "5.0.1" "workflow_dispatch" "All" "yes"
assert_should_build_os "5.0.1" "5.0.1" "workflow_dispatch" "OSS" "yes"
assert_should_build_os "5.0.1" "5.0.1" "workflow_dispatch" "EE" "no"

assert_should_build_os "5.0.1" "5.0.2" "push" "All" "no"
assert_should_build_os "5.0.1" "5.0.2" "workflow_dispatch" "All" "yes"
assert_should_build_os "5.0.1" "5.0.2" "workflow_dispatch" "OSS" "yes"
assert_should_build_os "5.0.1" "5.0.2" "workflow_dispatch" "EE" "no"

assert_should_build_os "5.0.2" "5.1.0" "push" "All" "Error: OSS and EE version must have same minor version"
assert_should_build_os "5.0.2" "5.1.0" "workflow_dispatch" "All" "Error: OSS and EE version must have same minor version"
assert_should_build_os "5.0.2" "5.1.0" "workflow_dispatch" "OSS" "Error: OSS and EE version must have same minor version"
assert_should_build_os "5.0.2" "5.1.0" "workflow_dispatch" "EE" "Error: OSS and EE version must have same minor version"

assert_should_build_os "5.1.0" "5.1.0" "push" "All" "yes"
assert_should_build_os "5.1.0" "5.1.0" "workflow_dispatch" "All" "yes"
assert_should_build_os "5.1.0" "5.1.0" "workflow_dispatch" "OSS" "yes"
assert_should_build_os "5.1.0" "5.1.0" "workflow_dispatch" "EE" "no"

assert_should_build_os "5.1.0" "5.1.1" "push" "All" "no"
assert_should_build_os "5.1.0" "5.1.1" "workflow_dispatch" "All" "yes"
assert_should_build_os "5.1.0" "5.1.1" "workflow_dispatch" "OSS" "yes"
assert_should_build_os "5.1.0" "5.1.1" "workflow_dispatch" "EE" "no"

assert_should_build_os "5.3.0-BETA-1" "5.3.0-BETA-1" "push" "All" "no"
assert_should_build_os "5.3.0-BETA-1" "5.3.0-BETA-1" "workflow_dispatch" "All" "yes"
assert_should_build_os "5.3.0-BETA-1" "5.3.0-BETA-1" "workflow_dispatch" "OSS" "yes"
assert_should_build_os "5.3.0-BETA-1" "5.3.0-BETA-1" "workflow_dispatch" "EE" "no"

assert_should_build_os "5.3.0-SNAPSHOT" "5.3.0-SNAPSHOT" "push" "All" "no"
assert_should_build_os "5.3.0-SNAPSHOT" "5.3.0-SNAPSHOT" "workflow_dispatch" "All" "yes"
assert_should_build_os "5.3.0-SNAPSHOT" "5.3.0-SNAPSHOT" "workflow_dispatch" "OSS" "yes"
assert_should_build_os "5.3.0-SNAPSHOT" "5.3.0-SNAPSHOT" "workflow_dispatch" "EE" "no"

assert_should_build_os "5.4.0-DEVEL-9" "5.4.0-DEVEL-9" "push" "All" "no"
assert_should_build_os "5.4.0-DEVEL-9" "5.4.0-DEVEL-9" "workflow_dispatch" "All" "yes"
assert_should_build_os "5.4.0-DEVEL-9" "5.4.0-DEVEL-9" "workflow_dispatch" "OSS" "yes"
assert_should_build_os "5.4.0-DEVEL-9" "5.4.0-DEVEL-9" "workflow_dispatch" "EE" "no"

assert_eq 0 "$TESTS_RESULT" "All tests should pass"
