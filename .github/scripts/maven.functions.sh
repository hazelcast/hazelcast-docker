#!/bin/bash

set -euo pipefail

function get_latest_version() {
  local groupId=$1
  local artifactId=$2

  curl -fsSL https://repo1.maven.org/maven2/"${groupId//./\/}"/"${artifactId}"/maven-metadata.xml | xmllint --xpath "string(/metadata/versioning/release)" -
}

function get_latest_url_without_extension() {
  local groupId=$1
  local artifactId=$2

  latest_version=$(get_latest_version "${groupId}" "${artifactId}")
  echo "https://repo1.maven.org/maven2/${groupId//./\/}/${artifactId}/${latest_version}/${artifactId}-${latest_version}"
}
