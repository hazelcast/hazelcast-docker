#!/usr/bin/env bash

set -e
set -o pipefail

function test_docker_image() {
    local image=$1
    local container_name=$2
    local expected_distribution_type=$3

    if [ "$(docker ps --all --quiet --filter name="$container_name")" ]; then
      echo "Removing existing '$container_name' container"
      docker container rm --force "$container_name"
    fi

    echo "Checking if $image is EE"
    if docker run -it  docker.io/hazelcast/hazelcast-enterprise:latest-snapshot bash -c 'compgen -G lib/*enterprise*'; then
      echo "EE contents identified"
      distribution_type="ee"
    else
      echo "No EE contents identified - assuming OSS"
      distribution_type="oss"
    fi

    if [[ "$distribution_type" != "$expected_distribution_type" ]]; then
      echo "Distribution was $distribution_type, not $expected_distribution_type as expected"
      exit 1
    fi

    echo "Starting container '$container_name' from image '$image'"
    docker run -it --name "$container_name" -e HZ_LICENSEKEY -e HZ_INSTANCETRACKING_FILENAME -d -p5701:5701 "$image"
    local key="some-key"
    local expected="some-value"
    echo "Putting value '$expected' for key '$key'"
    while ! clc --timeout 5s map set -n some-map $key $expected --log.path stderr
    do
      echo "Retrying..."
      sleep 3
    done
    echo "Getting value for key '$key'"
    local actual
    actual=$(clc map get --format delimited -n some-map $key --log.path stderr)
    echo "Stopping container $container_name}"
    docker stop "$container_name"

    if [ "$expected" != "$actual" ]; then
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
  export PATH=$PATH:$HOME/.hazelcast/bin
  clc config add default cluster.name=dev cluster.address=localhost
}

install_clc
test_docker_image "$@"
