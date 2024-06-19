#!/usr/bin/env bash

set -e
set -o pipefail

function test_docker_image() {
    local image=$1
    local container_name=$2

    if [ "$(docker ps --all --quiet --filter name="$container_name")" ]; then
      echo "Removing existing '$container_name' container"
      docker container rm --force "$container_name"
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
  # Use specific version as the downloading the latest version often fails: https://hazelcast.slack.com/archives/C0319N7HV8W/p1718023112329759
  local CLC_VERSION=v5.4.0
  curl https://raw.githubusercontent.com/hazelcast/hazelcast-commandline-client/main/extras/unix/install.sh | bash -s -- --version "$CLC_VERSION"
  export PATH=$PATH:$HOME/.hazelcast/bin
  clc config add default cluster.name=dev cluster.address=localhost
}

install_clc
test_docker_image "$@"
