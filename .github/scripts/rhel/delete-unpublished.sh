#!/bin/bash

set -o errexit -o nounset -o pipefail ${RUNNER_DEBUG:+-x}

# shellcheck source=../.github/scripts/rhel/functions.sh
. .github/scripts/rhel/functions.sh

RHEL_PROJECT_ID=$1
VERSION=$2
RHEL_API_KEY=$3

# Marks unpublished images as deleted for given version and then verifies if they were truly deleted
UNPUBLISHED_IMAGES=$(get_image not_published "${RHEL_PROJECT_ID}" "${VERSION}" "${RHEL_API_KEY}")
UNPUBLISHED_COUNT=$(echo "${UNPUBLISHED_IMAGES}" | jq -r '.total')

echo "Found '${UNPUBLISHED_COUNT}' unpublished images for '${VERSION}'"

# mark images as deleted
for ((idx = 0 ; idx < $((UNPUBLISHED_COUNT)) ; idx++));
do
    # this will actually send request to delete a single unpublished image
    IMAGE_ID=$(echo "${UNPUBLISHED_IMAGES}" | jq -r .data[${idx}]._id)

    echo "Marking image with ID=${IMAGE_ID} as deleted"

    # https://catalog.redhat.com/api/containers/docs/endpoints/RESTPatchImage.html
    RESPONSE=$( \
        curl --silent \
            --retry 5 --retry-all-errors \
            --request PATCH \
            --header "accept: application/json" \
            --header "Content-Type: application/json" \
            --header "X-API-KEY: ${RHEL_API_KEY}" \
            --data '{"deleted": true}' \
            "https://catalog.redhat.com/api/containers/v1/images/id/${IMAGE_ID}")

    echo "::debug::HTTP response after image deletion"
    echo "::debug::${RESPONSE}"
done

# verify we have actually deleted the images
if [[ ${UNPUBLISHED_COUNT} -gt 0 ]]; then
    # verifies there are no unpublished images for given version
    UNPUBLISHED_IMAGES=$(get_image not_published "${RHEL_PROJECT_ID}" "${VERSION}" "${RHEL_API_KEY}")
    UNPUBLISHED_COUNT=$(echo "${UNPUBLISHED_IMAGES}" | jq -r '.total')

    if [[ ${UNPUBLISHED_COUNT} == "0" ]]; then
        echo "No unpublished images found for '${VERSION}' after cleanup"
        return 0
    else
        echoerr "Exiting as found '${UNPUBLISHED_COUNT}' unpublished images for '${VERSION}'"
        echo_group "Unpublished images"
        echoerr "${UNPUBLISHED_IMAGES}"
        echo_group_end
        return 1
    fi
fi
