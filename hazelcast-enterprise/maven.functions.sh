set -euo pipefail ${RUNNER_DEBUG:+-x}

# THIS FILE IS DUPLICATED AND MUST BE KEPT IN SYNC MANUALLY
# Docker requires any included script to be in the current folder, hence we must duplicate this script for OS and EE

# Prints the latest version in the Maven repository
#
# Parameters:
#   group_id        e.g. com.google.guava
#   artifact_id     e.g. guava
#   repository_url  e.g. https://repo1.maven.org
#
# Prints the latest released version of the given artifact in the provided Maven repository
# E.G. `33.2.0-jre`

function get_latest_version() {
  local group_id=$1
  local artifact_id=$2
  local repository_url=$3

  curl --fail --silent --show-error --location "${repository_url}/${group_id//./\/}/${artifact_id}/maven-metadata.xml" | awk -F'<release>|</release>' 'NF>1 {print $2; exit}'
}

# Prints a URL to the latest version in the Maven repository, without a file extension
#
# Parameters:
#   group_id        e.g. com.google.guava
#   artifact_id     e.g. guava
#   repository_url  e.g. https://repo1.maven.org
#
# Prints a URL to the latest released version of a given artifact in the Maven repository, without a file extension, assuming a "typical" naming format
# E.G. `https://repo.maven.apache.org/maven2/com/google/guava/guava/33.2.0-jre/guava-33.2.0-jre`
function get_latest_url_without_extension() {
  local group_id=$1
  local artifact_id=$2
  local repository_url=$3

  latest_version=$(get_latest_version "${group_id}" "${artifact_id}" "${repository_url}")
  echo "${repository_url}/${group_id//./\/}/${artifact_id}/${latest_version}/${artifact_id}-${latest_version}"
}
