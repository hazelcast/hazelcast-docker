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
