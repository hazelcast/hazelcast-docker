function download_maven_artifact() {
  local repo=$1
  local groupId=$2
  local artifactId=$3
  local version=$4
  local classifier=$5
  local packaging=$6
  local destination=$7

  mvn \
    dependency:2.10:get \
    -DremoteRepositories="${repo}" \
    -DgroupId="${groupId}" \
    -DartifactId="${artifactId}" \
    -Dversion="${version}" \
    -Dclassifier="${classifier}" \
    -Dpackaging=${packaging} \
    -Dtransitive=false \
    -Ddest="${destination}" \
    --batch-mode \
    --no-transfer-progress
}
