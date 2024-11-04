#!/usr/bin/env bash

set -o errexit

# shellcheck source=../.github/scripts/abstract-simple-smoke-test.sh
. .github/scripts/abstract-simple-smoke-test.sh

function remove_container_if_exists() {
    local containers
    containers=$(docker ps --all --quiet --filter name="${container_name}")

    if [[ -n "${containers}" ]]; then
      echo "Removing existing '${container_name}' container"
      docker container rm --force "${container_name}"
    fi
}

function start_container() {
    echo "Starting container '${container_name}' from image '${image}'"
    docker run -it --name "${container_name}" -e HZ_LICENSEKEY -e HZ_INSTANCETRACKING_FILENAME -d -p5701:5701 "${image}"
}

function get_hz_logs() {
    docker logs "${container_name}"
}

function stop_container() {
    echo "Stopping container ${container_name}"
    docker stop "${container_name}"
}

function check_java_version() {
    local expected_major_version=$1
    local actual_major_version
    actual_major_version=$(docker run --rm "${image}" sh -c 'java -version 2>&1 | head -n 1 | awk -F "\"" "{print \$2}" | awk -F "." "{print \$1}"')

    if [[ "${expected_major_version}" != "${actual_major_version}" ]]; then
      echoerr "Expected Java version '${expected_major_version}' but got '${actual_major_version}'"
      exit 1;
    fi
}

function derive_expected_distribution_type() {
  local input_distribution_type=$1

  case "${input_distribution_type}" in
    "oss")
      echo "Hazelcast Platform"
      ;;
    "ee")
      echo "Hazelcast Enterprise"
      ;;
    *)
      echoerr "Unrecognized distribution type ${input_distribution_type}"
      exit 1
      ;;
  esac
}

image=$1
container_name=$2
input_distribution_type=$3
expected_version=$4
expected_java_major_version=$5


remove_container_if_exists
start_container

trap stop_container EXIT

expected_distribution_type=$(derive_expected_distribution_type "${input_distribution_type}")
test_package "${expected_distribution_type}" "${expected_version}"
check_java_version "${expected_java_major_version}"
