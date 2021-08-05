#!/bin/bash

get_id_from_pid()
{
    local PROJECT_ID=$1
    local RHEL_API_KEY=$2
    
    local ID=$( \
        curl --silent \
             --request GET \
             -H "X-API-KEY: ${RHEL_API_KEY}" \
             "https://catalog.redhat.com/api/containers/v1/projects/certification/pid/${PROJECT_ID}" \
             | jq -r '._id')
    
    echo "${ID}"
}

get_image()
{
    local PUBLISHED=$1
    local ID=$2
    local VERSION=$3
    local RHEL_API_KEY=$4

    if [[ $PUBLISHED == "published" ]]; then
        local PUBLISHED_FILTER="repositories.published==true"
    elif [[ $PUBLISHED == "not_published" ]]; then
        local PUBLISHED_FILTER="repositories.published!=true"
    else
        echo "Need first parameter as 'published' or 'not_published'." ; return 1
    fi

    local FILTER="filter=deleted==false;${PUBLISHED_FILTER};repositories.tags.name==${VERSION}"
    local INCLUDE="include=total,data.repositories.tags.name,data.scan_status,data._id"

    local RESPONSE=$( \
        curl --silent \
             --request GET \
             --header "X-API-KEY: ${RHEL_API_KEY}" \
             "https://catalog.redhat.com/api/containers/v1/projects/certification/id/${ID}/images?${FILTER}&${INCLUDE}")

    echo "${RESPONSE}"
}

wait_for_container_scan()
{
    local PROJECT_ID=$1
    local VERSION=$2
    local RHEL_API_KEY=$3
    local TIMEOUT_IN_MINS=$4

    # Get ID of the PID from the API.
    local ID=$(get_id_from_pid "${PROJECT_ID}" "${RHEL_API_KEY}")

    local IS_PUBLISHED=$(get_image published "${ID}" "${VERSION}" "${RHEL_API_KEY}" | jq -r '.total')
    if [[ $IS_PUBLISHED == "1" ]]; then
        echo "Image is already published, exiting"
        return 0
    fi

    local NOF_RETRIES=$(( $TIMEOUT_IN_MINS / 2 ))
    # Wait until the image is scanned
    for i in `seq 1 ${NOF_RETRIES}`; do
        local IMAGE=$(get_image not_published "${ID}" "${VERSION}" "${RHEL_API_KEY}")
        local SCAN_STATUS=$(echo "$IMAGE" | jq -r '.data[0].scan_status')

        if [[ $SCAN_STATUS == "in progress" ]]; then
            echo "Scanning in progress, waiting..."
        elif [[ $SCAN_STATUS == "null" ]];  then
            echo "Image is still not present in the registry!"
        elif [[ $SCAN_STATUS == "passed" ]]; then
            echo "Scan passed!" ; return 0
        else
            echo "Scan failed!" ; return 1
        fi

        sleep 120

        if [[ $i == $NOF_RETRIES ]]; then
            echo "Timeout! Scan could not be finished"
            return 42
        fi
    done
}

publish_the_image()
{
    local PROJECT_ID=$1
    local VERSION=$2
    local RHEL_API_KEY=$3

    # Get ID of the PID from the API.
    local ID=$(get_id_from_pid "${PROJECT_ID}" "${RHEL_API_KEY}")

    local IS_PUBLISHED=$(get_image published "${ID}" "${VERSION}" "${RHEL_API_KEY}" | jq -r '.total')
    if [[ $IS_PUBLISHED == "1" ]]; then
        echo "Image is already published, exiting"
        return 0
    fi

    local IMAGE=$(get_image not_published "${ID}" "${VERSION}" "${RHEL_API_KEY}")
    local IMAGE_EXISTS=$(echo $IMAGE | jq -r '.total')
    if [[ $IMAGE_EXISTS == "1" ]]; then
        local SCAN_STATUS=$(echo $IMAGE | jq -r '.data[0].scan_status')
        if [[ $SCAN_STATUS != "passed" ]]; then
            echo "Image you are trying to publish did not pass the certification test, its status is \"${SCAN_STATUS}\""
            return 1
        fi
    else
        echo "Image you are trying to publish does not exist."
        return 1
    fi

    local IMAGE_ID=$(echo "$IMAGE" | jq -r '.data[0]._id')

    # Publish the image
    echo "Publishing the image..."
    RESPONSE=$( \
        curl --silent \
            --request POST \
            --header "X-API-KEY: ${RHEL_API_KEY}" \
            --header 'Cache-Control: no-cache' \
            --header 'Content-Type: application/json' \
            --data "{\"image_id\":\"${IMAGE_ID}\" , \"tag\" : \"${VERSION}\" }" \
            "https://catalog.redhat.com/api/containers/v1/projects/certification/id/${ID}/requests/tags")
    
    echo "Created a tag request, please check if the image is published."
}

wait_for_container_publish()
{
    local PROJECT_ID=$1
    local VERSION=$2
    local RHEL_API_KEY=$3
    local TIMEOUT_IN_MINS=$4

    # Get ID of the PID from the API.
    local ID=$(get_id_from_pid "${PROJECT_ID}" "${RHEL_API_KEY}")

    local NOF_RETRIES=$(( $TIMEOUT_IN_MINS / 2 ))
    # Wait until the image is published
    for i in `seq 1 ${NOF_RETRIES}`; do
        local IS_PUBLISHED=$(get_image published "${ID}" "${VERSION}" "${RHEL_API_KEY}" | jq -r '.total')

        if [[ $IS_PUBLISHED == "1" ]]; then
            echo "Image is published, exiting."
            return 0
        else
            echo "Image is still not published, waiting..."
        fi

        sleep 120

        if [[ $i == $NOF_RETRIES ]]; then
            echo "Timeout! Publish could not be finished"
            return 42
        fi
    done
}