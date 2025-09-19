#!/bin/bash

set -o errexit -o nounset -o pipefail ${RUNNER_DEBUG:+-x}

# shellcheck source=../.github/scripts/logging.functions.sh
. .github/scripts/logging.functions.sh

get_image()
{
    local RESPONSE
    # https://catalog.redhat.com/api/containers/docs/endpoints/RESTGetImagesForCertProjectById.html
    RESPONSE=$( \
        curl --fail \
             --silent \
             --show-error \
             --header "X-API-KEY: ${RHEL_API_KEY}" \
             "https://catalog.redhat.com/api/containers/v1/projects/certification/id/${RHEL_PROJECT_ID}/images?filter=_id==${IMAGE_ID}")

    echodebug "${RESPONSE}"
    echo "${RESPONSE}"
}

wait_for_container_scan()
{
    local NOF_RETRIES=$(( TIMEOUT_IN_MINS / 2 ))
    # Wait until the image is scanned
    for i in $(seq 1 "${NOF_RETRIES}"); do
        local IMAGE
        local SCAN_STATUS
        local IMAGE_CERTIFIED

        IMAGE=$(get_image)
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

request_operation()
{
    local OPERATION=$1

    echo "Submitting '${OPERATION}' request for the image ${IMAGE_ID}..."
    local RESPONSE
    # https://catalog.redhat.com/api/containers/docs/endpoints/RESTPostImageRequestByCertProjectId.html
    RESPONSE=$( \
        curl --fail \
             --silent \
             --show-error \
             --retry 5 --retry-all-errors \
             --header "X-API-KEY: ${RHEL_API_KEY}" \
             --header 'Cache-Control: no-cache' \
             --header 'Content-Type: application/json' \
             --data "{\"image_id\":\"${IMAGE_ID}\" , \"operation\" : \"${OPERATION}\" }" \
             "https://catalog.redhat.com/api/containers/v1/projects/certification/id/${RHEL_PROJECT_ID}/requests/images")

    echo "'${OPERATION}' response: ${RESPONSE}"
}

wait_for_container_publish()
{
    local NOF_RETRIES=$(( TIMEOUT_IN_MINS * 2 ))
    # Wait until the image is published
    for i in $(seq 1 "${NOF_RETRIES}"); do
        local IMAGE
        local IS_PUBLISHED

        IMAGE=$(get_image)
        # Return the published status of the most recent repository entry
        IS_PUBLISHED=$(jq -r '.data[].repositories[-1].published' <<< "${IMAGE}")

        if [[ ${IS_PUBLISHED} == "true" ]]; then
            echo "Image is published, exiting."
            return 0
        elif [[ ${i} == "${NOF_RETRIES}" ]]; then
            echoerr "Timeout! Publish could not be finished"
            
            echoerr "Request Status:"
            local IMAGE_REQUESTS
            # https://catalog.redhat.com/api/containers/docs/endpoints/RESTGetImageRequestsByImageId.html
            IMAGE_REQUESTS=$(curl --fail \
                --silent \
                --show-error \
                --header "X-API-KEY: ${RHEL_API_KEY}" \
                "https://catalog.redhat.com/api/containers/v1/images/id/${IMAGE_ID}/requests")

            echoerr "${IMAGE_REQUESTS}"
            
            echoerr "Image Status:"
            echoerr "${IMAGE}"

            # Add additional logging context if possible
            echoerr "Test Results:"
            # https://catalog.redhat.com/api/containers/docs/endpoints/RESTGetTestResultsById.html
            echo "${IMAGE}" | jq -r '.data[]._links.test_results.href' | while read -r TEST_RESULTS_ENDPOINT; do
                local TEST_RESULTS
                TEST_RESULTS=$(curl --fail \
                    --silent \
                    --show-error \
                    --header "X-API-KEY: ${RHEL_API_KEY}" \
                    "https://catalog.redhat.com/api/containers/${TEST_RESULTS_ENDPOINT}")
                echoerr "${TEST_RESULTS}"
            done

            return 42
        else        
            echo "Image is still not published, waiting..."

            sleep 30
        fi
    done
}

RHEL_PROJECT_ID=$1
IMAGE_ID=$2
RHEL_API_KEY=$3
TIMEOUT_IN_MINS=$4

wait_for_container_scan
request_operation publish
wait_for_container_publish
request_operation sync-tags
