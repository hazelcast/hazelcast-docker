# shellcheck source=../.github/scripts/logging.functions.sh
. .github/scripts/logging.functions.sh

get_image()
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

  echodebug "${response}"
  echo "${response}"
  return 0
}

get_image_requests()
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
      "https://catalog.redhat.com/api/containers/v1/images/id/${image_id}/requests")

  echodebug "${response}"
  echo "${response}"
  return 0
}

# Blocks/waits until the specified image is marked as published
await_image_publish()
{
  local image_id=$1
  local api_key=$2

  while true; do
    local image
    image=$(get_image "${image_id}" "${api_key}")

    # Check the published status of the most recent repository entry
    if jq --exit-status '.data[].repositories[-1].published' <<< "${image}"; then
      echo "Image '${image_id}' is published, exiting."
      return 0
    else
      echo "Image '${image_id}' is still not published, waiting..."
      get_image_requests "${image_id}" "${api_key}"
      sleep 5
    fi
  done
}
