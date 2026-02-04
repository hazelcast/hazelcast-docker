# shellcheck source=../.github/scripts/logging.functions.sh
. .github/scripts/logging.functions.sh

__get_certification_project_image_request()
{
  local image_id=$1
  local api_key=$2
  local operation=$3

  # https://catalog.redhat.com/api/containers/docs/endpoints/RESTGetImageRequestsByImageId.html
  curl --fail \
    --silent \
    --show-error \
    --header "X-API-KEY: ${api_key}" \
    "https://catalog.redhat.com/api/containers/v1/images/id/${image_id}/requests?filter=operation==${operation}"

  return 0
}

__get_image_tags()
{
  local image_id=$1
  local api_key=$2

  local response
  # https://catalog.redhat.com/api/containers/docs/endpoints/RESTGetImage.html
  response=$( \
    curl --fail \
      --silent \
      --show-error \
      --header "X-API-KEY: ${api_key}" \
      "https://catalog.redhat.com/api/containers/v1/images/id/${image_id}")

  jq --raw-output '[.repositories[].tags[].name] | unique | .[]' <<< "${response}"
  return 0
}

__sync_tags()
{
  local project_id=$1
  local image_id=$2
  local api_key=$3

  # https://catalog.redhat.com/api/containers/docs/endpoints/RESTPostImageRequestByCertProjectId.html
  curl --fail \
        --silent \
        --show-error \
        --header "X-API-KEY: ${api_key}" \
        --header 'Content-Type: application/json' \
        --data "{\"image_id\":\"${image_id}\" , \"operation\" : \"sync-tags\" }" \
        "https://catalog.redhat.com/api/containers/v1/projects/certification/id/${project_id}/requests/images"

  return 0
}

__contains_all_expected_tags() {
  local actual_tags=$1
  local expected_tags=$2

  for expected_tag in ${expected_tags}
  do
      if grep --fixed-strings --line-regexp --silent "${expected_tag}" <<< "${actual_tags}"; then
        echodebug "${expected_tag} found in ${actual_tags}"
      else
        echo "${expected_tag} not found in ${actual_tags}"
        return 1
      fi
  done

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
    request=$(__get_certification_project_image_request "${image_id}" "${api_key}" "${operation}")
    
    # Print request for status purposes
    jq <<< "${request}"

    # Check the status of the most recent repository entry
    case "$(jq -r '.data[-1].status' <<< "${request}")" in
      "completed")
        echo "Image '${image_id}' ${operation} operation completed"
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

# Checks image has expected tags - if not, calls "sync-tags" until it does
check_image_tags()
{
  local project_id=$1
  local image_id=$2
  local api_key=$3
  local expected_tags=$4

  while true; do
    await_image_operation "${image_id}" "${api_key}" "sync-tags"

    local actual_tags
    actual_tags=$(__get_image_tags "${image_id}" "${api_key}")

    echodebug "Checking actual tags (${actual_tags}) contains all expected tags (${expected_tags})"

    if __contains_all_expected_tags "${actual_tags}" "${expected_tags}"; then
      return 0
    else 
      echo "Resyncing tags"
      __sync_tags "${project_id}" "${image_id}" "${api_key}"
    fi

  done
}
