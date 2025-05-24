function get_default_jdk() {
  local DIR=$1
  awk -F= '/^ARG JDK_VERSION=/{print $2}' "$DIR/Dockerfile" | tr -d '"'
}
