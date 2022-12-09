#!/usr/bin/env bash

set -e
set -o pipefail

export CLC_VERSION=v5.2.0-beta3

function test_docker_image() {
    local image=$1
    local container_name=$2
    echo "Starting container '$container_name' from image '$image'"
    docker run -it --name "$container_name" -d -p5701:5701 "$image"
    local key="some-key"
    local expected="some-value"
    echo "Putting value '$expected' for key '$key'"
    clc map set -n some-map $key $expected --log.path stderr
    echo "Getting value for key '$key'"
    local actual
    actual=$(clc map get -n some-map $key --log.path stderr)
    echo "Stopping container $container_name}"
    docker stop "$container_name"

    if [ "$expected" != "$actual" ]; then
        echo "Expected to read '${expected}' but got '${actual}'"
        exit 1;
    fi
}

function install_clc() {
  CLC_URL="https://github.com/hazelcast/hazelcast-commandline-client/releases/download/${CLC_VERSION}/hazelcast-clc_${CLC_VERSION}_linux_amd64.tar.gz"
  curl -L $CLC_URL | tar xzf - --strip-components=1 -C /usr/local/bin
  chmod +x /usr/local/bin/clc
}

install_clc
test_docker_image "$@"
