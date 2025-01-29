#!/bin/bash

set -o errexit -o nounset -o pipefail ${RUNNER_DEBUG:+-x}

# shellcheck source=../.github/scripts/logging.functions.sh
. .github/scripts/logging.functions.sh

get_image()
{
    local PUBLISHED=$1
    local RHEL_PROJECT_ID=$2
    local VERSION=$3
    local RHEL_API_KEY=$4

    case "${PUBLISHED}" in
        "published")
        local PUBLISHED_FILTER="repositories.published==true"
        ;;
        "not_published")
        local PUBLISHED_FILTER="repositories.published!=true"
        ;;
        *)
        echoerr "Need first parameter as 'published' or 'not_published', not '${PUBLISHED}'." ; return 1
        ;;
    esac

    local FILTER="filter=deleted==false;${PUBLISHED_FILTER};repositories.tags=em=(name=='${VERSION}')"
    local INCLUDE="include=total,data.repositories,data.certified,data.container_grades,data._id,data.creation_date"
    local SORT_BY='sort_by=creation_date\[desc\]'

    local RESPONSE
    # https://catalog.redhat.com/api/containers/docs/endpoints/RESTGetImagesForCertProjectById.html
    RESPONSE=$( \
        curl --silent \
             --request GET \
             --header "X-API-KEY: ${RHEL_API_KEY}" \
             "https://catalog.redhat.com/api/containers/v1/projects/certification/id/${RHEL_PROJECT_ID}/images?${FILTER}&${INCLUDE}&${SORT_BY}")

    echo "${RESPONSE}"
}

wait_for_container_scan()
{
    local RHEL_PROJECT_ID=$1
    local VERSION=$2
    local RHEL_API_KEY=$3

    local IMAGE
    local IS_PUBLISHED

    IMAGE=$(get_image published "${RHEL_PROJECT_ID}" "${VERSION}" "${RHEL_API_KEY}")
    IS_PUBLISHED=$(echo "${IMAGE}" | jq -r '.total')

    if [[ ${IS_PUBLISHED} == "1" ]]; then
        echo "Image is already published, exiting"
        return 0
    fi

    # start timer
    _start_stopwatch

    while true
    do
        local IMAGE
        local SCAN_STATUS
        local IMAGE_CERTIFIED
        local RESULT=-1

        IMAGE=$(get_image not_published "${RHEL_PROJECT_ID}" "${VERSION}" "${RHEL_API_KEY}")
        SCAN_STATUS=$(echo "${IMAGE}" | jq -r '.data[0].container_grades.status')
        IMAGE_CERTIFIED=$(echo "${IMAGE}" | jq -r '.data[0].certified')

        if _is_stopwatch_expired; then
            RESULT=42
            echoerr "Timeout! Scan could not be finished"
        elif [[ ${SCAN_STATUS} == "pending" ]]; then
            echo "Scanning pending, waiting..."
        elif [[ ${SCAN_STATUS} == "in progress" ]]; then
            echo "Scanning in progress, waiting..."
        elif [[ ${SCAN_STATUS} == "null" ]];  then
            echo "Image is still not present in the registry!"
        elif [[ ${SCAN_STATUS} == "completed" && "${IMAGE_CERTIFIED}" == "true" ]]; then
            RESULT=0
            echo "Scan passed!"
        else
            RESULT=1
            echoerr "Scan failed with '${SCAN_STATUS}!"
        fi

        if [[ ${RESULT} -ge 0 ]]; then
            # cancel stopwatch if error or sucess
            _cancel_stopwatch

            if [[ ${RESULT} -gt 0 ]]; then
                echoerr "${IMAGE}"
            fi
            return ${RESULT}
        fi

        # Wait a little before next retry
        sleep 120
    done
}

publish_the_image()
{
    local RHEL_PROJECT_ID=$1
    local VERSION=$2
    local RHEL_API_KEY=$3

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

sync_tags()
{
    local RHEL_PROJECT_ID=$1
    local VERSION=$2
    local RHEL_API_KEY=$3

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

wait_for_container_publish()
{
    local RHEL_PROJECT_ID=$1
    local VERSION=$2
    local RHEL_API_KEY=$3

    # start timer
    _start_stopwatch

    while true
    do
        local IMAGE
        local IS_PUBLISHED
        local RESULT=-1

        IMAGE=$(get_image published "${RHEL_PROJECT_ID}" "${VERSION}" "${RHEL_API_KEY}")
        IS_PUBLISHED=$(echo "${IMAGE}" | jq -r '.total')

        if _is_stopwatch_expired; then
            RESULT=42
            echoerr "Timeout! Publish could not be finished"
        elif [[ ${IS_PUBLISHED} == "1" ]]; then
            RESULT=0
            echo "Image is published, exiting."
        else
            echo "Image is still not published, waiting..."
        fi

        if [[ $RESULT -ge 0 ]]; then
            # cancel stopwatch if error or sucess
            _cancel_stopwatch

            if [[ $RESULT -gt 0 ]]; then
                echoerr "Image Status:"
                echoerr "${IMAGE}"
                print_test_results_on_error "${RHEL_PROJECT_ID}" "${VERSION}" "${RHEL_API_KEY}"
            fi
            return $RESULT
        fi

        # Wait a little before next retry
        sleep 30
    done
}

# Prints test result for additional debug info after error
function print_test_results_on_error() {
    local RHEL_PROJECT_ID=$1
    local VERSION=$2
    local RHEL_API_KEY=$3

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
}

# Marks unpublished images as deleted for given version and then verifies if they were truly deleted
function delete_unpublished_images() {
    local RHEL_PROJECT_ID=$1
    local VERSION=$2
    local RHEL_API_KEY=$3

    local IMAGE
    local IS_PUBLISHED

    UNPUBLISHED_IMAGES=$(get_image not_published "${RHEL_PROJECT_ID}" "${VERSION}" "${RHEL_API_KEY}")
    UNPUBLISHED_COUNT=$(echo "${UNPUBLISHED_IMAGES}" | jq -r '.total')

    if [[ ${UNPUBLISHED_COUNT} == "0" ]]; then
        echo "No unpublished images found for ${VERSION}"
        return 0
    fi

    # mark images as deleted
    echo "Found '${UNPUBLISHED_COUNT}' unpublished images for '${VERSION}'"
    for ((idx = 0 ; idx < $((UNPUBLISHED_COUNT)) ; idx++));
    do
        local IMAGE_ID=$(echo "${UNPUBLISHED_IMAGES}" | jq -r .data[${idx}]._id)
        do_delete_unpublished_images "${RHEL_API_KEY}" "${IMAGE_ID}"
    done

    # verify we have actually deleted the images. returning explictly to make it clearer
    verify_no_unpublished_images "$RHEL_PROJECT_ID" "$VERSION" "$RHEL_API_KEY"
}

# this will actually send request to delete a single unpublished image
function do_delete_unpublished_images() {
    local RHEL_API_KEY=$1
    local IMAGE_ID=$2
    echo "Marking image with ID=${IMAGE_ID} as deleted"

    # https://catalog.redhat.com/api/containers/docs/endpoints/RESTPatchImage.html
    RESPONSE=$( \
        curl --silent \
            --request PATCH \
            --header "accept: application/json" \
            --header "Content-Type: application/json" \
            --header "X-API-KEY: ${RHEL_API_KEY}" \
            --data '{"deleted": true}' \
            "https://catalog.redhat.com/api/containers/v1/images/id/${IMAGE_ID}")
}

# verifies there are no unblished images for given version
function verify_no_unpublished_images() {
    local RHEL_PROJECT_ID=$1
    local VERSION=$2
    local RHEL_API_KEY=$3

    UNPUBLISHED_IMAGES=$(get_image not_published "${RHEL_PROJECT_ID}" "${VERSION}" "${RHEL_API_KEY}")
    UNPUBLISHED_COUNT=$(echo "${UNPUBLISHED_IMAGES}" | jq -r '.total')

    if [[ ${UNPUBLISHED_COUNT} == "0" ]]; then
        echo "No unpublished images found for '${VERSION}' after cleanup"
        return 0
    fi

    echoerr "Exiting as found '${UNPUBLISHED_COUNT}' unblished images for '${VERSION}'"
    return 1
}

# Starts timer with default timeout of 4h. See RedHat ticket https://connect.redhat.com/support/partner-acceleration-desk/#/case/04042093
# The scan/publish can take from 2m to 3hrs but we set higher just in case
STOPWATCH_PID=-1
STOPWATCH_DEFAULT_TIMEOUT=4h
function _start_stopwatch() {
    # Only use this within this script as only designed for single use for now.
    # The stopwatch funstions start with '_' to denote them as private
    local timeout="${1:-$STOPWATCH_DEFAULT_TIMEOUT}"
    echo "Starting timeout timer for ${timeout}"
    sleep $timeout &
    STOPWATCH_PID=$!
    echo "Stopwatch PID=${STOPWATCH_PID}"
}

# Private function to stop current stopwatch
function _cancel_stopwatch() {
    echo "Stoppping stopwatch timer PID=${STOPWATCH_PID}"
    kill ${STOPWATCH_PID} > /dev/null 2>&1 || true
    STOPWATCH_PID=-1
}

# Private function to check if stopwatch timer is still running
function _is_stopwatch_expired() {
    ! kill -0 ${STOPWATCH_PID} > /dev/null 2>&1
}

