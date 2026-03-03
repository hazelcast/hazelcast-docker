#!/usr/bin/env bash

set -o errexit -o nounset -o pipefail ${RUNNER_DEBUG:+-x}

# Verifies Docker image build reproducibility by building twice and comparing layer digests.
# Exits 0 if all layers are identical across both builds, 1 if any differ.
#
# Usage:
#   verify-layer-reproducibility.sh <dockerfile> [extra buildx build args...]
#
# Examples:
#   verify-layer-reproducibility.sh hazelcast-oss/Dockerfile hazelcast-oss/
#   verify-layer-reproducibility.sh hazelcast-oss/Dockerfile --output type=docker,rewrite-timestamp=true hazelcast-oss/

readonly RANDOM_SUFFIX="$(head -c 8 /dev/urandom | od -An -tx1 | tr -d ' \n')"
readonly TAG_A="repro-check-a-${RANDOM_SUFFIX}"
readonly TAG_B="repro-check-b-${RANDOM_SUFFIX}"

cleanup() {
    docker rmi "${TAG_A}" "${TAG_B}" 2>/dev/null || true
}
trap cleanup EXIT

readonly dockerfile="${1:?Error: <dockerfile> is required}"
shift

# Add --load if user didn't provide --output
load_flag="--load"
for arg in "$@"; do
    case "${arg}" in
        --output|--output=*) load_flag="" ;;
    esac
done

build_image() {
    local tag="$1"
    shift
    echo "==> Building image '${tag}'..."
    docker buildx build \
        --no-cache \
        ${load_flag} \
        -f "${dockerfile}" \
        -t "${tag}" \
        "$@"
}

get_layers() {
    docker inspect --format '{{json .RootFS.Layers}}' "$1"
}

build_image "${TAG_A}" "$@"
echo ""
build_image "${TAG_B}" "$@"
echo ""

layers_a=$(get_layers "${TAG_A}")
layers_b=$(get_layers "${TAG_B}")

count_a=$(echo "${layers_a}" | jq 'length')
count_b=$(echo "${layers_b}" | jq 'length')

echo "=== Layer Reproducibility Report ==="
echo ""

if [[ "${count_a}" -ne "${count_b}" ]]; then
    echo "WARNING: Layer count mismatch (${count_a} vs ${count_b})"
    echo ""
fi

max_count=$(( count_a > count_b ? count_a : count_b ))
has_diff=false
for i in $(seq 0 $((max_count - 1))); do
    digest_a=$(echo "${layers_a}" | jq -r ".[$i] // empty")
    digest_b=$(echo "${layers_b}" | jq -r ".[$i] // empty")
    if [[ -z "${digest_a}" ]]; then
        echo "  Layer $((i + 1))/${max_count}: ONLY IN B"
        echo "    B: ${digest_b}"
        has_diff=true
    elif [[ -z "${digest_b}" ]]; then
        echo "  Layer $((i + 1))/${max_count}: ONLY IN A"
        echo "    A: ${digest_a}"
        has_diff=true
    elif [[ "${digest_a}" == "${digest_b}" ]]; then
        echo "  Layer $((i + 1))/${max_count}: MATCH"
    else
        echo "  Layer $((i + 1))/${max_count}: DIFFER"
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
