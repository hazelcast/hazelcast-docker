#!/bin/bash

set -euo pipefail

# TODO DOCS
function get_latest_version() {
  local group_id=$1
  local artifact_id=$2
  local repository_url=$3

  curl --fail --silent --show-error --location "${repository_url}/${group_id//./\/}/${artifact_id}/maven-metadata.xml" | xmllint --xpath "string(/metadata/versioning/release)" -
}

# TODO DOCS
function get_latest_url_without_extension() {
  local group_id=$1
  local artifact_id=$2
  local repository_url=$3

  latest_version=$(get_latest_version "${group_id}" "${artifact_id}" "${repository_url}")
  echo "${repository_url}/${group_id//./\/}/${artifact_id}/${latest_version}/${artifact_id}-${latest_version}"
}
