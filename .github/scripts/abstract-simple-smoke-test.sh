#!/usr/bin/env bash

set -o errexit -o nounset -o pipefail ${RUNNER_DEBUG:+-x}

# Performs simple validation tests on an already-running Hazelcast instance
# Abstract as could be from Docker, Homebrew, local binary etc
# Because abstract, expects callers to implement required, but absent functions
function test_package() {
    local expected_distribution_type=$1
    local expected_version=$2

    test_health
    test_map_read_write

    # Deliberately last step as it doesn't block-and-wait until the instance is initialized
    # Otherwise would have false positives if instance still starting and logs empty
    check_metadata "${expected_distribution_type}" "${expected_version}"
}

# Search logs for entries _like_:
# Hazelcast Platform 5.5.0 (20240725) starting at [172.17.0.2]:5701
# To validate the version and distribution is correct
function check_metadata() {
    local expected_distribution_type=$1
    local expected_version=$2

    logs=$(get_hz_logs)

    if [[ -z "${logs}" ]]; then
      echoerr "Failed to read logs"
      exit 1;
    fi

    if grep -q "${expected_distribution_type} ${expected_version}" <<< "${logs}"; then
      echo "Expected contents (${expected_distribution_type}) and version (${expected_version}) identified."
    else
      echoerr "Failed to find ${expected_distribution_type} ${expected_version} in logs:"
      echoerr "${logs}"
      exit 1;
    fi
}

function test_health() {
  local attempts=0
  local max_attempts=30
  until curl --silent --fail "127.0.0.1:5701/hazelcast/health/ready"; do
    if [[ ${attempts} -eq ${max_attempts} ]];then
        echoerr "Hazelcast not responding"
        exit 1;
    fi
    printf '.'
    attempts=$((attempts+1))
    sleep 2
  done
}

function test_map_read_write() {
    install_clc

    local key="some-key"
    local expected="some-value"
    echo "Putting value '${expected}' for key '${key}'"
    clc --timeout 5s map set -n some-map "${key}" "${expected}" --log.path stderr
    echo "Getting value for key '${key}'"
    local actual
    actual=$(clc map get --format delimited -n some-map "${key}" --log.path stderr)

    if [[ "${expected}" != "${actual}" ]]; then
        echoerr "Expected to read '${expected}' but got '${actual}'"
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

# Prints the given message to stderr
function echoerr() {
  echo "ERROR - $*" 1>&2;
}
