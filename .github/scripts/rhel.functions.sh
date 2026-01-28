# shellcheck source=../.github/scripts/logging.functions.sh
. .github/scripts/logging.functions.sh

get_certification_project_image_request()
{
  local image_id=$1
  local api_key=$2
  local operation=$3

  local response
  # https://catalog.redhat.com/api/containers/docs/endpoints/RESTGetImageRequestsByImageId.html
  response=$( \
    curl --fail \
      --silent \
      --show-error \
      --header "X-API-KEY: ${api_key}" \
      "https://catalog.redhat.com/api/containers/v1/images/id/${image_id}/requests?filter=operation==${operation}")

  echo "${response}"
  return 0
}

# Blocks/waits until the specified image operation is completed
await_image_operation()
{
  local image_id=$1
  local api_key=$2
  local operation=$3

  while true; do
    local request
    request=$(get_certification_project_image_request "${image_id}" "${api_key}" "${operation}")
    
    # Print request for status purposes
    jq <<< "${request}"

    # Check the status of the most recent repository entry
    case "$(jq -r '.data[-1].status' <<< "${request}")" in
      "completed")
        echo "Image '${image_id}' ${operation} operation completed, exiting."
        return 0
        ;;
      "aborted" | "failed")
        echo_group "Image '${image_id}' failed to complete ${operation}"
        echoerr "$(jq <<< "${request}" || true)"
        echo_group_end
        return 1
        ;;
      *)
        echo "Image '${image_id}' still not finished ${operation}, waiting..."
        sleep 5
        ;;
    esac
  done
}
