#!/usr/bin/env bash

set -o errexit -o nounset -o pipefail

function test_docker_image() {
    local image=$1
    local container_name=$2
    local expected_distribution_type=$3
    local expected_version=$4

    remove_container_if_exists "${container_name}"

    check_distribution_type "${image}" "${expected_distribution_type}"
    check_version "${image}" "${expected_version}"

    test_map_read_write "${image}" "${container_name}"
}

function remove_container_if_exists() {
    local container_name=$1

    local containers
    containers=$(docker ps --all --quiet --filter name="${container_name}")

    if [[ -n ${containers} ]]; then
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
      echo "Distribution was ${distribution_type}, not ${expected_distribution_type} as expected"
      exit 1
    fi
}

function check_version() {
    local image=$1
    local expected_version=$2

    echo "Checking ${image} version"
    local version
    version=$(docker run --rm "${image}" bin/hz-cli --version | awk '/Hazelcast/ {print $2}')
    if [[ "${version}" != "${expected_version}" ]]; then
      echo "${image} was ${version}, not ${expected_version} as expected"
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
        echo "Expected to read '${expected}' but got '${actual}'"
        exit 1;
    fi
}

function install_clc() {
  while ! curl https://hazelcast.com/clc/install.sh | bash
    do
      echo "Retrying clc installation..."
      sleep 3
    done
  export PATH=${PATH}:${HOME}/.hazelcast/bin
  clc config add default cluster.name=dev cluster.address=localhost
}

install_clc
test_docker_image "$@"
