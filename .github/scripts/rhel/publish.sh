#!/bin/bash

set -o errexit -o nounset -o pipefail ${RUNNER_DEBUG:+-x}

# shellcheck source=../.github/scripts/rhel/functions.sh
. .github/scripts/rhel/functions.sh

wait_for_container_scan()
{    
    local IMAGE
    local IS_PUBLISHED

    IMAGE=$(get_image published "${RHEL_PROJECT_ID}" "${VERSION}" "${RHEL_API_KEY}")
    IS_PUBLISHED=$(echo "${IMAGE}" | jq -r '.total')

    if [[ ${IS_PUBLISHED} == "1" ]]; then
        echo "Image is already published, exiting"
        return 0
    fi

    local NOF_RETRIES=$(( TIMEOUT_IN_MINS / 2 ))
    # Wait until the image is scanned
    for i in $(seq 1 "${NOF_RETRIES}"); do
        local IMAGE
        local SCAN_STATUS
        local IMAGE_CERTIFIED

        IMAGE=$(get_image not_published "${RHEL_PROJECT_ID}" "${VERSION}" "${RHEL_API_KEY}")
        SCAN_STATUS=$(echo "${IMAGE}" | jq -r '.data[0].container_grades.status')
        IMAGE_CERTIFIED=$(echo "${IMAGE}" | jq -r '.data[0].certified')

        if [[ ${SCAN_STATUS} == "pending" ]]; then
            echo "Scanning pending, waiting..."
        elif [[ ${SCAN_STATUS} == "in progress" ]]; then
            echo "Scanning in progress, waiting..."
        elif [[ ${SCAN_STATUS} == "null" ]];  then
            echo "Image is still not present in the registry!"
        elif [[ ${SCAN_STATUS} == "completed" && "${IMAGE_CERTIFIED}" == "true" ]]; then
            echo "Scan passed!" ; return 0
        else
            echoerr "Scan failed with '${SCAN_STATUS}!"
            echoerr "${IMAGE}"
            return 1
        fi

        sleep 120

        if [[ ${i} == "${NOF_RETRIES}" ]]; then
            echoerr "Timeout! Scan could not be finished"
            echoerr "${IMAGE}"
            return 42
        fi
    done
}

publish_the_image()
{
    echo "Starting publishing the image for ${VERSION}"

    local IMAGE
    local IMAGE_EXISTS

    IMAGE=$(get_image not_published "${RHEL_PROJECT_ID}" "${VERSION}" "${RHEL_API_KEY}")
    IMAGE_EXISTS=$(echo "${IMAGE}" | jq -r '.total')

    if [[ ${IMAGE_EXISTS} == "1" ]]; then
        local SCAN_STATUS
        local IMAGE_CERTIFIED

        SCAN_STATUS=$(echo "${IMAGE}" | jq -r '.data[0].container_grades.status')
        IMAGE_CERTIFIED=$(echo "${IMAGE}" | jq -r '.data[0].certified')

        if [[ ${SCAN_STATUS} != "completed" ||  "${IMAGE_CERTIFIED}" != "true" ]]; then
            echoerr "Image you are trying to publish did not pass the certification test, its status is \"${SCAN_STATUS}\" and certified is \"${IMAGE_CERTIFIED}\""
            return 1
        fi
    else
        echoerr "Image you are trying to publish does not exist."
        echoerr "${IMAGE}"
        return 1
    fi

    local IMAGE_ID
    IMAGE_ID=$(echo "${IMAGE}" | jq -r '.data[0]._id')

    echo "Publishing the image ${IMAGE_ID}..."
    # https://catalog.redhat.com/api/containers/docs/endpoints/RESTPostImageRequestByCertProjectId.html
    RESPONSE=$( \
        curl --silent \
            --retry 5 --retry-all-errors \
            --request POST \
            --header "X-API-KEY: ${RHEL_API_KEY}" \
            --header 'Cache-Control: no-cache' \
            --header 'Content-Type: application/json' \
            --data "{\"image_id\":\"${IMAGE_ID}\" , \"operation\" : \"publish\" }" \
            "https://catalog.redhat.com/api/containers/v1/projects/certification/id/${RHEL_PROJECT_ID}/requests/images")

    echo "Response: ${RESPONSE}"
    echo "Created a publish request, please check if the image is published."
}

wait_for_container_publish()
{
    local NOF_RETRIES=$(( TIMEOUT_IN_MINS * 2 ))
    # Wait until the image is published
    for i in $(seq 1 "${NOF_RETRIES}"); do
        local IMAGE
        local IS_PUBLISHED

        IMAGE=$(get_image published "${RHEL_PROJECT_ID}" "${VERSION}" "${RHEL_API_KEY}")
        IS_PUBLISHED=$(echo "${IMAGE}" | jq -r '.total')

        if [[ ${IS_PUBLISHED} == "1" ]]; then
            echo "Image is published, exiting."
            return 0
        else
            echo "Image is still not published, waiting..."
        fi

        sleep 30

        if [[ ${i} == "${NOF_RETRIES}" ]]; then
            echoerr "Timeout! Publish could not be finished"
            echoerr "Image Status:"
            echoerr "${IMAGE}"

            # Add additional logging context if possible
            echoerr "Test Results:"
            # https://catalog.redhat.com/api/containers/docs/endpoints/RESTGetTestResultsById.html
            get_image not_published "${RHEL_PROJECT_ID}" "${VERSION}" "${RHEL_API_KEY}" | jq -r '.data[]._links.test_results.href' | while read -r TEST_RESULTS_ENDPOINT; do
                local TEST_RESULTS
                TEST_RESULTS=$(curl --silent \
                    --request GET \
                    --header "X-API-KEY: ${RHEL_API_KEY}" \
                    "https://catalog.redhat.com/api/containers/${TEST_RESULTS_ENDPOINT}")
                echoerr "${TEST_RESULTS}"
            done

            return 42
        fi
    done
}

sync_tags()
{
    echo "Starting sync tags for ${VERSION}"

    local IMAGE
    local IMAGE_EXISTS

    IMAGE=$(get_image published "${RHEL_PROJECT_ID}" "${VERSION}" "${RHEL_API_KEY}")
    IMAGE_EXISTS=$(echo "${IMAGE}" | jq -r '.total')

    if [[ ${IMAGE_EXISTS} == "0" ]]; then
        echo "Image you are trying to sync does not exist."
        return 1
    fi

    local IMAGE_ID
    IMAGE_ID=$(echo "${IMAGE}" | jq -r '.data[0]._id')

    echo "Syncing tags of the image ${IMAGE_ID}..."
    # https://catalog.redhat.com/api/containers/docs/endpoints/RESTPostImageRequestByCertProjectId.html
    RESPONSE=$( \
        curl --silent \
            --retry 5 --retry-all-errors \
            --request POST \
            --header "X-API-KEY: ${RHEL_API_KEY}" \
            --header 'Cache-Control: no-cache' \
            --header 'Content-Type: application/json' \
            --data "{\"image_id\":\"${IMAGE_ID}\" , \"operation\" : \"sync-tags\" }" \
            "https://catalog.redhat.com/api/containers/v1/projects/certification/id/${RHEL_PROJECT_ID}/requests/images")

    echo "Response: ${RESPONSE}"
    echo "Created a sync-tags request, please check if the tags image are in sync."
}

RHEL_PROJECT_ID=$1
VERSION=$2
RHEL_API_KEY=$3
TIMEOUT_IN_MINS=$4

wait_for_container_scan
publish_the_image
wait_for_container_publish
sync_tags
