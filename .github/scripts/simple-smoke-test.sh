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


remove_container_if_exists
start_container

trap stop_container EXIT

expected_distribution_type=$(derive_expected_distribution_type "${input_distribution_type}")
test_package "${expected_distribution_type}" "${expected_version}"
