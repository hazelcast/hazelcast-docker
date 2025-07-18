# shellcheck source=../.github/scripts/logging.functions.sh
. .github/scripts/logging.functions.sh

function packages_updated_oss() {
  local IMAGE=$1
  OUTPUT=$(docker run --user 0 --rm "${IMAGE}" sh -c 'apk update >/dev/null && apk list --upgradeable')
  echodebug "${OUTPUT}"
  [[ -n "${OUTPUT}" ]]
}

function packages_updated_ee() {
  local IMAGE=$1
  local OUTPUT
  # use assumeno as a workaround for lack of dry-run option
  OUTPUT=$(docker run --user 0 --rm "${IMAGE}" sh -c "microdnf --assumeno upgrade --nodocs")
  echodebug "${OUTPUT}"
  PACKAGE_UPGRADES=$(echo "${OUTPUT}" | grep --count Upgrading)
  [[ "${PACKAGE_UPGRADES}" -ne 0 ]]
}
