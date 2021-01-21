#!/bin/bash

get_containers()
{
    PROJECT_ID=$1
    VERSION=$2
    RHEL_API_KEY=$3

    RESPONSE=$( \
        curl --silent \
             --request POST \
             --header "Content-Type: application/json" \
             --header "Authorization: Bearer ${RHEL_API_KEY}" \
             --data {} \
             "https://connect.redhat.com/api/v2/projects/${PROJECT_ID}/tags?tags=${VERSION}")

    echo "${RESPONSE}"
}

get_container_build()
{
    PROJECT_ID=$1
    VERSION=$2
    RHEL_API_KEY=$3

    BUILD=$(get_containers "${PROJECT_ID}" "${VERSION}" "${RHEL_API_KEY}" | jq -r '.tags[0]')
    if [ "${BUILD}" == "null" ]; then
        # TAG can be also stored as "${VERSION}, latest"
        BUILD=$(get_containers "${PROJECT_ID}" "${VERSION}%2C%20latest" "${RHEL_API_KEY}" | jq -r '.tags[0]')
    fi
    echo "${BUILD}"
}

is_build_valid()
{
    BUILD=$1

    echo "${BUILD}" | jq -r '.digest' > /dev/null
    return $?
}


wait_for_container_build_or_scan()
{
    TIMEOUT_IN_MINS=$1
    NOF_RETRIES=$(( $TIMEOUT_IN_MINS / 2 ))
    # Wait until the image is built and scanned
    for i in `seq 1 10`; do
        BUILD=$(get_container_build "${PROJECT_ID}" "${VERSION}" ${RHEL_API_KEY})
        SCAN_STATUS=$(echo "${BUILD}" | jq -r '.scan_status')
        DIGEST=$(echo "${BUILD}" | jq -r '.digest')
        if [ "${SCAN_STATUS}" == "passed" ]; then
            break
        fi
        echo "Building or scanning in progress, waiting..."
        sleep 120
        if [ "$i" = "$NOF_RETRIES" ]; then
            echo "Timeout! Scan could not be finished"
            return 42
        fi
    done
}

publish_the_image()
{
    # Publish the image
    echo "Publishing the image..."
    RESPONSE=$( \
    #    curl --silent \
            --request POST \
            --header "Authorization: Bearer ${RHEL_API_KEY}" \
            --header 'Cache-Control: no-cache' \
            --header 'Content-Type: application/json' \
            --data {} \
            "https://connect.redhat.com/api/v2/projects/${PROJECT_ID}/containers/${DIGEST}/tags/${VERSION}/publish")
    STATUS=$(echo "${RESPONSE}" | jq -r '.status')

    # Result message
    if [ "${STATUS}" == "OK" ]; then
        echo "Done."
        return 0
    else
        ERROR=$(echo "${RESPONSE}" | jq -r '.data.errors[0]')
        if [[ "${ERROR}" == 'Container image is already published'* ]]; then
            echo "Image is already published. Skipped."
            return 0
        else
            echo "Error, result message: ${RESPONSE}"
            return 42
        fi
    fi
}
