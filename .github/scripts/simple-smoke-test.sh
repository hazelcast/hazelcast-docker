#!/usr/bin/env bash

set -o errexit -o nounset -o pipefail

function test_docker_image() {
    local image=$1
    local container_name=$2
    local expected_distribution_type=$3
    local expected_version=$4

    remove_container_if_exists "${container_name}"

    check_distribution_type "${image}" "${expected_distribution_type}"
    check_image_hz_version "${image}" "${expected_version}"

    test_map_read_write "${image}" "${container_name}"
}

function remove_container_if_exists() {
    local container_name=$1

    local containers
    containers=$(docker ps --all --quiet --filter name="${container_name}")

    if [[ -n "${containers}" ]]; then
      echo "Removing existing '${container_name}' container"
      docker container rm --force "${container_name}"
    fi
}

function check_distribution_type() {
    local image=$1
    local expected_distribution_type=$2

    echo "Checking ${image} distribution type"
    if docker run --rm "${image}" bash -c 'compgen -G lib/*enterprise*'; then
      echo "EE contents identified"
      distribution_type="ee"
    else
      echo "No EE contents identified - assuming OSS"
      distribution_type="oss"
    fi

    if [[ "${distribution_type}" != "${expected_distribution_type}" ]]; then
      echoerr "Image ${image} should contain ${expected_distribution_type} distribution but ${distribution_type} was detected"
      exit 1
    fi
}

function check_image_hz_version() {
    local image=$1
    local expected_version=$2

    echo "Checking ${image} version"
    local version
    version=$(docker run --rm "${image}" bin/hz-cli --version | awk '/Hazelcast/ {print $2}')
    if [[ "${version}" == "${expected_version}" ]]; then
      echo "${image} version identified as ${version}"
    else
      echoerr "${image} version was ${version}, not ${expected_version} as expected"
      exit 1
    fi
}

function test_map_read_write() {
    local image=$1
    local expected_distribution_type=$2

    echo "Starting container '${container_name}' from image '${image}'"
    docker run -it --name "${container_name}" -e HZ_LICENSEKEY -e HZ_INSTANCETRACKING_FILENAME -d -p5701:5701 "${image}"
    local key="some-key"
    local expected="some-value"
    echo "Putting value '${expected}' for key '${key}'"
    while ! clc --timeout 5s map set -n some-map "${key}" "${expected}" --log.path stderr
    do
      echo "Retrying..."
      sleep 3
    done
    echo "Getting value for key '${key}'"
    local actual
    actual=$(clc map get --format delimited -n some-map "${key}" --log.path stderr)
    echo "Stopping container ${container_name}"
    docker stop "${container_name}"

    if [[ "${expected}" != "${actual}" ]]; then
        echoerr "Expected to read '${expected}' but got '${actual}'"
        exit 1;
    fi
}

function check_java_version() {
    local expected_major_version=$1
    local actual_major_version
    actual_major_version=$(docker run --rm "${image}" sh -c 'java -version 2>&1 | head -n 1 | awk -F "\"" "{print \$2}" | awk -F "." "{print \$1}"')

    if [[ "${expected_major_version}" == "${actual_major_version}" ]]; then
      echo "Expected Java version (${expected_distribution_type}) identified."
    else
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
