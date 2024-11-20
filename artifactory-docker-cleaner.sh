#!/usr/bin/env bash

# This script finds and deletes orphaned docker layers that were skipped by flawed tag retention logic in Artifactory.
#
# It's a workaround for a bug in JFrog artifactory that leaves untagged images in the storage despite Tag retention set to 1
#
# More details:
# - support.jfrog.com/s/tickets/500Tc00000Er7WN/digestbased-docker-images-are-not-deleted-when-removing-tags-that-reference-them
# - jfrog.atlassian.net/browse/RTFACT-30850

set -euo pipefail

BASE_URL="https://repository.hazelcast.com"
REPOSITORY_NAME="docker"

if [[ $# -lt 1 || $# -gt 2 ]]; then
  echo "Usage: $0 <IMAGE_NAME> [--remove]"
  echo "  IMAGE_NAME - name of the image in the artifactory repository, e.g. hazelcast/hazelcast"
  echo ""
  echo "  Options:"
  echo "    --remove  Remove unreferenced images. Run without this option to only list unreferenced images"
  exit 1
fi

IMAGE_NAME="$1"

REMOVE=false
if [[ "${2:-}" == "--remove" ]]; then
  REMOVE=true
fi

if [[ -z "${JFROG_USER:-}" ]]; then
  echo "Error: JFROG_USER environment variable must be set."
  exit 1
fi

if [[ -z "${JFROG_TOKEN:-}" ]]; then
  echo "Error: JFROG_TOKEN environment variable must be set."
  exit 1
fi

tags=$(curl -s -u "$JFROG_USER:$JFROG_TOKEN" "$BASE_URL/api/docker/$REPOSITORY_NAME/v2/$IMAGE_NAME/tags/list" | jq -r '.tags[]')

declare -A referenced_images

for tag in $tags; do
  echo ""
  echo "Checking tag $tag"
  manifest_url="$BASE_URL/$REPOSITORY_NAME/$IMAGE_NAME/$tag/list.manifest.json"
  manifest_content=$(curl -s -u "$JFROG_USER:$JFROG_TOKEN" "$manifest_url")

  if [[ $(echo "$manifest_content" | jq -e '.manifests') ]]; then
    while IFS= read -r digest; do
      referenced_images["digest_$digest"]=$tag
      echo "Found reference to $digest"
    done < <(echo "$manifest_content" | jq -r ".manifests[].digest[7:]")
  fi
done

all_images=$(curl -s -u "$JFROG_USER:$JFROG_TOKEN" "$BASE_URL/api/storage/$REPOSITORY_NAME/$IMAGE_NAME" | jq -r '.children[].uri | select(. | startswith("/sha256:")) | .[8:]')

FOUND_UNREFERENCED_IMAGE=false
echo ""
echo "Summary:"
  for image in $all_images; do
    if [[ -z "${referenced_images[digest_$image]:-}" ]]; then
      FOUND_UNREFERENCED_IMAGE=true
      if [[ "$REMOVE" == true ]]; then
        echo "REMOVING unreferenced image $image"
        curl -s --show-error -u "$JFROG_USER:$JFROG_TOKEN" -X DELETE "$BASE_URL/$REPOSITORY_NAME/$IMAGE_NAME/sha256:$image" || echo "Failed to delete image $image"
      else
        echo "Found unreferenced image: $image"
      fi
    fi
  done

if [[ "$FOUND_UNREFERENCED_IMAGE" == false ]]; then
  echo "No unreferenced images found"
fi
