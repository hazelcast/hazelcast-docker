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
    local INCLUDE="include=total,data.repositories.tags.name,data.certified,data.container_grades,data._id,data.creation_date"
    local SORT_BY='sort_by=creation_date\[desc\]'

    local RESPONSE
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
    local TIMEOUT_IN_MINS=$4
    
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
    local TIMEOUT_IN_MINS=$4

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
            echoerr "${IMAGE}"
            return 42
        fi
    done
}
