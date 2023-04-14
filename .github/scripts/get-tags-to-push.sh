#!/usr/bin/env bash

function find_last_matching_version() {
  FILTER=$1
  git tag | grep -v BETA | grep '^v' | cut -c2- | grep "^$FILTER" | tail -n 1
}

function get_latest_version() {
  find_last_matching_version ""
}

function verlte() {
    [  "$1" = "`echo -e "$1\n$2" | sort -V | head -n1`" ]
}

VERSION_TO_RELEASE=$1
MINOR_VERSION_TO_RELEASE=${VERSION_TO_RELEASE%.*}
MAJOR_VERSION_TO_RELEASE=${MINOR_VERSION_TO_RELEASE%.*}

LATEST_FOR_MINOR=$(find_last_matching_version $MINOR_VERSION_TO_RELEASE)
LATEST_FOR_MAJOR=$(find_last_matching_version $MAJOR_VERSION_TO_RELEASE)
LATEST=$(get_latest_version)

TAGS_TO_PUSH+=($VERSION_TO_RELEASE)

if verlte "$LATEST_FOR_MINOR" "$VERSION_TO_RELEASE"; then
   TAGS_TO_PUSH+=($MINOR_VERSION_TO_RELEASE)
fi

if verlte "$LATEST_FOR_MAJOR" "$VERSION_TO_RELEASE"; then
   TAGS_TO_PUSH+=($MAJOR_VERSION_TO_RELEASE)
fi

if verlte "$LATEST" "$VERSION_TO_RELEASE"; then
   TAGS_TO_PUSH+=(latest)
fi

echo "${TAGS_TO_PUSH[@]}"
