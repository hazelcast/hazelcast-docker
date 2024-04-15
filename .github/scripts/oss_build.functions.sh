#!/bin/bash

set -euo pipefail

get_patch_part() {
  local version=$1
  local patch_part=$(echo "$version" | awk -F'.' '{print $3}')
  echo "$patch_part"
}

is_numeric() {
  local str=$1
  [[ $str =~ ^[0-9]+$ ]]
}

assert_same_minor_version() {
  local oss_version=$1
  local ee_version=$2

  local oss_xy_part=$(echo "$oss_version" | awk -F'.' '{print $1 "." $2}')
  local ee_xy_part=$(echo "$ee_version" | awk -F'.' '{print $1 "." $2}')

  if [[ $oss_xy_part != $ee_xy_part ]]; then
    echo "Error: OSS and EE version must have same minor version"
    exit 1
  fi
}

# Checks if we should build the OSS docker image.
# Returns "yes" if we should build it or "no" if we shouldn't.
# If the workflow was triggered by "push" (usually tag push) we two conditions:
#  - both (OSS and EE) HZ versions are final release (non-BETA/DEVEL/SNAPSHOT)
#  - both (OSS and EE) HZ versions are equal
#
# The reasoning:
# - For minor releases we will have the same version set (OSS=`6.6.0` and EE=`6.6.0`) which means
# we should build both editions.
#
# - For patch releases we will increment only EE version (i.e. OSS="6.6.0" and EE=`6.6.1`) which means we should build EE only
#
# - If for some reason we will have to build an emergency OSS patch release we should change OSS version
# as well (i.e. OSS="6.6.1" and EE=`6.6.1`) this will mean we should build both editions
#
# - If the workflows was triggered manually by `workflow_dispatch` we assume that the caller knows what they're doing
# so we return "yes" for "All" and "OSS" editions
#
# Check test cases in `oss_build.functions_tests.sh` to see the examples
should_build_oss() {

  local oss_version=$1
  local ee_version=$2
  local triggered_by=$3
  local editions=$4

  assert_same_minor_version "$oss_version" "$ee_version"

  if [[ $triggered_by == "workflow_dispatch" ]]; then
    if [[ $editions == "All" || $editions == "OSS" ]]; then
      echo "yes"
      return
    fi
  fi

  if [[ $triggered_by == "push" ]]; then
    local oss_patch_part=$(get_patch_part "$oss_version")
    local ee_patch_part=$(get_patch_part "$ee_version")

    if is_numeric "$oss_patch_part" && [[ "$oss_patch_part" == "$ee_patch_part" ]]; then
      echo "yes"
      return
    fi
  fi

  echo "no"
}
