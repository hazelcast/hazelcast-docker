#!/usr/bin/env bash

# shellcheck source=../.github/scripts/versions.functions.sh
. .github/scripts/version.functions.sh

# Returns tags, ordered by specificality 
function get_version_only_tags_to_push() {
  local VERSION_TO_RELEASE=$1
  local IS_LATEST_LTS=$2

  if [ "$#" -ne 2 ]; then
    echo "Error: Incorrect number of arguments. Usage: ${FUNCNAME[0]} VERSION_TO_RELEASE IS_LATEST_LTS"
    exit 1;
  fi

  if [[ "${VERSION_TO_RELEASE}" =~ (BETA|DEVEL) ]]; then
    echo "$VERSION_TO_RELEASE"
    return
  fi

  local MINOR_VERSION_TO_RELEASE=${VERSION_TO_RELEASE%.*}
  local MAJOR_VERSION_TO_RELEASE=${MINOR_VERSION_TO_RELEASE%.*}

  local LATEST_FOR_MINOR=$(get_latest_patch_version "${MINOR_VERSION_TO_RELEASE}")
  local LATEST_FOR_MAJOR=$(get_latest_patch_version "${MAJOR_VERSION_TO_RELEASE}")
  local LATEST=$(get_latest_patch_version "")

  local TAGS_TO_PUSH+=($VERSION_TO_RELEASE)

  if version_less_or_equal "$LATEST_FOR_MINOR" "$VERSION_TO_RELEASE"; then
    TAGS_TO_PUSH+=($MINOR_VERSION_TO_RELEASE)
  fi

  if version_less_or_equal "$LATEST_FOR_MAJOR" "$VERSION_TO_RELEASE"; then
    TAGS_TO_PUSH+=($MAJOR_VERSION_TO_RELEASE)
  fi

  if version_less_or_equal "$LATEST" "$VERSION_TO_RELEASE"; then
    TAGS_TO_PUSH+=("latest")
  fi
  if [ "$IS_LATEST_LTS" == "true" ] ; then
    TAGS_TO_PUSH+=("latest-lts")
  fi

  __sort_tags "${TAGS_TO_PUSH[@]}"
}

# Returns tags, ordered by specificality
function get_tags_to_push() {

  if [ "$#" -ne 5 ]; then
    echo "Error: Incorrect number of arguments. Usage: ${FUNCNAME[0]} VERSION_TO_RELEASE SUFFIX CURRENT_JDK DEFAULT_JDK IS_LATEST_LTS"
    exit 1;
  fi

  local VERSION_TO_RELEASE=$1
  local SUFFIX=$2
  local CURRENT_JDK=$3
  local DEFAULT_JDK=$4
  local IS_LATEST_LTS=$5

  local tags
  tags=$(get_version_only_tags_to_push "$VERSION_TO_RELEASE" "$IS_LATEST_LTS")
  tags=$(__augment_with_suffixed_tags "${tags[*]}" "$SUFFIX" "$CURRENT_JDK" "$DEFAULT_JDK")

  __sort_tags "${tags}"
}

function __augment_with_suffixed_tags() {
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

# Sort tags by specificality - most specific first (e.g. "5.5.0-jdk11 5.5.0 5.5 latest-lts latest")
# Expects space-separated list as input
# Internally converts to line-separator separated list for sorting and then inverses
function __sort_tags() {
  local tags=$*
  tags=$(tr ' ' '\n' <<< "${tags}")
  tags=$(sort --general-numeric-sort --reverse <<< "${tags}")
  paste -sd' ' - <<< "${tags}"
}


tags="5.5 5.5.0 5.5.0-jdk11 latest latest-lts"
echo $(__sort_tags $tags)