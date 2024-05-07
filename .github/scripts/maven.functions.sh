#!/bin/bash

set -x
set -euo pipefail

function get_latest_version() {
  local group=$1
  local artifactId=$2

  curl -O -fsSL https://repo1.maven.org/maven2/"${group//./\/}"/"${artifactId}"/maven-metadata.xml
  version=$(xmllint --xpath "string(/metadata/versioning/release)" maven-metadata.xml)

  echo "${version}"
  rm maven-metadata.xml
}
