#!/usr/bin/env bash

set -o errexit -o nounset -o pipefail ${RUNNER_DEBUG:+-x}

# Verifies Docker image build reproducibility by building twice and comparing layer digests.
# Exits 0 if all layers are identical across both builds, 1 if any differ.
#
# Usage:
#   verify-layer-reproducibility.sh -f <dockerfile> [-- <extra buildx build args...>]
#
# Example:
#   verify-layer-reproducibility.sh -f hazelcast-oss/Dockerfile -- hazelcast-oss/

RANDOM_SUFFIX="$(head -c 8 /dev/urandom | od -An -tx1 | tr -d ' \n')"
readonly RANDOM_SUFFIX
readonly TAG_A="repro-check-a-${RANDOM_SUFFIX}"
readonly TAG_B="repro-check-b-${RANDOM_SUFFIX}"

cleanup() {
    docker rmi "${TAG_A}" "${TAG_B}" 2>/dev/null || true
}
trap cleanup EXIT

dockerfile=""
while [[ $# -gt 0 ]]; do
    case "$1" in
        -f) dockerfile="$2"; shift 2 ;;
        --) shift; break ;;
        *) echo "Unknown option: $1" >&2; exit 1 ;;
    esac
done

if [[ -z "${dockerfile}" ]]; then
    echo "Error: -f <dockerfile> is required" >&2
    exit 1
fi

extra_args=("$@")

build_image() {
    local tag="$1"
    echo "==> Building image '${tag}'..."
    docker buildx build \
        --no-cache \
        --load \
        -f "${dockerfile}" \
        -t "${tag}" \
        "${extra_args[@]}"
}

get_layers() {
    docker inspect --format '{{json .RootFS.Layers}}' "$1"
}

build_image "${TAG_A}"
echo ""
build_image "${TAG_B}"
echo ""

layers_a=$(get_layers "${TAG_A}")
layers_b=$(get_layers "${TAG_B}")

count_a=$(echo "${layers_a}" | jq 'length')
count_b=$(echo "${layers_b}" | jq 'length')

echo "=== Layer Reproducibility Report ==="
echo ""

if [[ "${count_a}" -ne "${count_b}" ]]; then
    echo "FAIL: Layer count mismatch (${count_a} vs ${count_b})"
    exit 1
fi

has_diff=false
for i in $(seq 0 $((count_a - 1))); do
    digest_a=$(echo "${layers_a}" | jq -r ".[$i]")
    digest_b=$(echo "${layers_b}" | jq -r ".[$i]")
    if [[ "${digest_a}" == "${digest_b}" ]]; then
        echo "  Layer $((i + 1))/${count_a}: MATCH"
    else
        echo "  Layer $((i + 1))/${count_a}: DIFFER"
        echo "    A: ${digest_a}"
        echo "    B: ${digest_b}"
        has_diff=true
    fi
done

echo ""
if [[ "${has_diff}" == "true" ]]; then
    echo "RESULT: FAIL - some layers differ between builds"
    exit 1
fi

echo "RESULT: PASS - all ${count_a} layers are identical"