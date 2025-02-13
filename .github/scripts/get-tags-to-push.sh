#!/usr/bin/env bash

function find_last_matching_version() {
  FILTER=$1
  git tag | grep -v BETA | grep -v DEVEL | grep '^v' | cut -c2- | grep "^$FILTER" | tail -n 1
}

function get_latest_version() {
  find_last_matching_version ""
}

function verlte() {
  [ "$1" = "$(echo -e "$1\n$2" | sort -V | head -n1)" ]
}

function get_version_only_tags_to_push() {
  local VERSION_TO_RELEASE=$1

  if [ "$#" -ne 1 ]; then
    echo "Error: Incorrect number of arguments. Usage: ${FUNCNAME[0]} VERSION_TO_RELEASE"
    exit 1;
  fi

  if [[ "$VERSION_TO_RELEASE" =~ BETA|DEVEL ]]; then
    echo "$VERSION_TO_RELEASE"
    return
  fi

  local MINOR_VERSION_TO_RELEASE=${VERSION_TO_RELEASE%.*}
  local MAJOR_VERSION_TO_RELEASE=${MINOR_VERSION_TO_RELEASE%.*}

  local LATEST_FOR_MINOR=$(find_last_matching_version $MINOR_VERSION_TO_RELEASE)
  local LATEST_FOR_MAJOR=$(find_last_matching_version $MAJOR_VERSION_TO_RELEASE)
  local LATEST=$(get_latest_version)

  local TAGS_TO_PUSH+=($VERSION_TO_RELEASE)

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
}

function get_tags_to_push() {

  if [ "$#" -ne 4 ]; then
    echo "Error: Incorrect number of arguments. Usage: ${FUNCNAME[0]} VERSION_TO_RELEASE SUFFIX CURRENT_JDK DEFAULT_JDK"
    exit 1;
  fi

  local VERSION_TO_RELEASE=$1
  local SUFFIX=$2
  local CURRENT_JDK=$3
  local DEFAULT_JDK=$4
  local VERSION_ONLY_TAGS_TO_PUSH=$(get_version_only_tags_to_push "$VERSION_TO_RELEASE")
  augment_with_suffixed_tags "${VERSION_ONLY_TAGS_TO_PUSH[*]}" "$SUFFIX" "$CURRENT_JDK" "$DEFAULT_JDK"
}

function augment_with_suffixed_tags() {

  if [ "$#" -ne 4 ]; then
    echo "Error: Incorrect number of arguments. Usage: ${FUNCNAME[0]} INITIAL_TAGS SUFFIX CURRENT_JDK DEFAULT_JDK"
    exit 1;
  fi

  local INITIAL_TAGS=$1
  local SUFFIX=$2
  local CURRENT_JDK=$3
  local DEFAULT_JDK=$4

    for tag in ${INITIAL_TAGS[@]}
    do
      if [[ "$CURRENT_JDK" == "$DEFAULT_JDK" ]]; then
          TAGS_TO_PUSH+=(${tag}$SUFFIX)
      fi
      TAGS_TO_PUSH+=(${tag}${SUFFIX}-jdk${CURRENT_JDK})
    done

  echo "${TAGS_TO_PUSH[@]}"
}

function add_non_moveable_tag_to_push() {
  local -n CURRENT_TAGS="$1"
  local VERSION_TO_RELEASE=$2
  local SUFFIX=$3
  local CURRENT_JDK=$4

  local dt=$(date "+%Y%m%d%H%M%S")
  local ver_array=("${VERSION_TO_RELEASE}")
  local aug_tag=$(augment_with_suffixed_tags "${ver_array[*]}" "${SUFFIX}" "${CURRENT_JDK}" "")
  CURRENT_TAGS+=("${aug_tag[0]}-$dt")
}
