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

should_build_os() {

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
