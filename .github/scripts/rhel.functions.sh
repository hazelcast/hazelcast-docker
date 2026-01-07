# shellcheck source=../.github/scripts/logging.functions.sh
. .github/scripts/logging.functions.sh

get_image()
{
  local project_id=$1
  local image_id=$2
  local api_key=$3

  local response
  # https://catalog.redhat.com/api/containers/docs/endpoints/RESTGetImagesForCertProjectById.html
  response=$( \
    curl --fail \
      --silent \
      --show-error \
      --header "X-API-KEY: ${api_key}" \
      "https://catalog.redhat.com/api/containers/v1/projects/certification/id/${project_id}/images?filter=_id==${image_id}")

  echodebug "${response}"
  echo "${response}"
  return 0
}

# Blocks/waits until the specified image is marked as published
await_image_publish()
{
  local project_id=$1
  local image_id=$2
  local api_key=$3

  while true; do
    local image
    image=$(get_image "${project_id}" "${image_id}" "${api_key}")

    # Check the published status of the most recent repository entry
    if jq --exit-status '.data[].repositories[-1].published' <<< "${image}"; then
      echo "Image '${image_id}' is published, exiting."
      return 0
    else
      echo "Image '${image_id}' is still not published, waiting..."
      sleep 5
    fi
  done
}
