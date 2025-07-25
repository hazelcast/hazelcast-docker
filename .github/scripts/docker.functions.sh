function get_default_jdk() {
  local DIR=$1
  awk -F= '/^ARG JDK_VERSION=/{print $2}' "$DIR/Dockerfile" | tr -d '"'
}

function get_alpine_supported_platforms() {
  local JDK=$1
  local PLATFORMS="linux/arm64,linux/amd64,linux/s390x"
  #already fixed on alpine:edge, probably will be released in alpine:3.20
  if [[ "$JDK" -lt 17 ]]; then
    PLATFORMS="$PLATFORMS,linux/ppc64le"
  fi
  echo $PLATFORMS
}

function get_ubi_supported_platforms() {
  local JDK=$1
  echo "linux/arm64,linux/amd64,linux/s390x,linux/ppc64le"
}
