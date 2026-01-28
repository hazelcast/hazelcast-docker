# shellcheck source=../.github/scripts/logging.functions.sh
. .github/scripts/logging.functions.sh

get_certification_project_image_request()
{
  local image_id=$1
  local api_key=$2

  local response
  # https://catalog.redhat.com/api/containers/docs/endpoints/RESTGetImageRequestsByImageId.html
  response=$( \
    curl --fail \
      --silent \
      --show-error \
      --header "X-API-KEY: ${api_key}" \
      "https://catalog.redhat.com/api/containers/v1/images/id/${image_id}/requests?filter=operation==publish")

  echo "${response}"
  return 0
}

sync_tags()
{
  local project_id=$1
  local image_id=$2
  local api_key=$3

  local RESPONSE
  # https://catalog.redhat.com/api/containers/docs/endpoints/RESTPostImageRequestByCertProjectId.html
  RESPONSE=$( \
      curl --fail \
            --silent \
            --show-error \
            --header "X-API-KEY: ${api_key}" \
            --header 'Content-Type: application/json' \
            --data "{\"image_id\":\"${image_id}\" , \"operation\" : \"sync-tags\" }" \
            "https://catalog.redhat.com/api/containers/v1/projects/certification/id/${project_id}/requests/images")

  echodebug "${RESPONSE}"
}

# Blocks/waits until the specified image is marked as published
await_image_publish()
{
  local image_id=$1
  local api_key=$2

  while true; do
    local request
    request=$(get_certification_project_image_request "${image_id}" "${api_key}")
    
    # Print request for status purposes
    jq <<< "${request}"

    # Check the published status of the most recent repository entry
    case "$(jq -r '.data[-1].status' <<< "${request}")" in
      "completed")
        echo "Image '${image_id}' is published, exiting."
        return 0
        ;;
      "aborted" | "failed")
        echo_group "Image '${image_id}' failed to publish"
        echoerr "$(jq <<< "${request}" || true)"
        echo_group_end
        return 1
        ;;
      *)
        echo "Image '${image_id}' is still not published, waiting..."
        sleep 5
        ;;
    esac
  done
}
