#!/usr/bin/env bash

set -o errexit -o nounset -o pipefail ${RUNNER_DEBUG:+-x}

# shellcheck source=../.github/scripts/logging.functions.sh
. .github/scripts/logging.functions.sh

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
    local tag="$1"
    docker inspect --format '{{json .RootFS.Layers}}' "${tag}"
}

get_digest() {
    local layers="$1"
    local index="$2"
    echo "${layers}" | jq -r ".[${index}] // empty"
}

build_image "${TAG_A}" "$@"
echo ""
build_image "${TAG_B}" "$@"
echo ""

layers_a=$(get_layers "${TAG_A}")
layers_b=$(get_layers "${TAG_B}")

layer_count_a=$(echo "${layers_a}" | jq 'length')
layer_count_b=$(echo "${layers_b}" | jq 'length')

echo "=== Layer Reproducibility Report ==="
echo ""

if [[ "${layer_count_a}" -ne "${layer_count_b}" ]]; then
    echoerr "WARNING: Layer count mismatch (${layer_count_a} vs ${layer_count_b})"
    echo ""
fi

layer_max_count=$(( layer_count_a > layer_count_b ? layer_count_a : layer_count_b ))
has_diff=false
for layerIndex in $(seq 0 $((layer_max_count - 1))); do
    layer_digest_a=$(get_digest "${layers_a}" "${layerIndex}")
    layer_digest_b=$(get_digest "${layers_b}" "${layerIndex}")
    if [[ -z "${layer_digest_a}" ]]; then
        echo "  Layer $((layerIndex + 1))/${layer_max_count}: ONLY IN B"
        echo "    B: ${layer_digest_b}"
        has_diff=true
    elif [[ -z "${layer_digest_b}" ]]; then
        echo "  Layer $((layerIndex + 1))/${layer_max_count}: ONLY IN A"
        echo "    A: ${layer_digest_a}"
        has_diff=true
    elif [[ "${layer_digest_a}" == "${layer_digest_b}" ]]; then
        echo "  Layer $((layerIndex + 1))/${layer_max_count}: MATCH"
    else
        echo "  Layer $((layerIndex + 1))/${layer_max_count}: DIFFER"
        echo "    A: ${layer_digest_a}"
        echo "    B: ${layer_digest_b}"
        has_diff=true
    fi
done

echo ""
if [[ "${has_diff}" == "true" ]]; then
    echoerr "RESULT: FAIL - some layers differ between builds"
    exit 1
fi

echo "RESULT: PASS - all ${layer_count_a} layers are identical"
