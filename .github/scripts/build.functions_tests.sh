#!/usr/bin/env bash

SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"

. "$SCRIPT_DIR"/build.functions.sh

TESTS_RESULT=0

download_maven_artifact \
  "https://repo.maven.apache.org/maven2" \
  com.google.guava  \
  listenablefuture \
  9999.0-empty-to-avoid-conflict-with-guava \
  "" \
  "jar" \
  .
