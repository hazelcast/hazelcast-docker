# shellcheck source=../.github/scripts/logging.functions.sh
. .github/scripts/logging.functions.sh

function packages_updated_oss() {
  local image=$1
  local output
  output=$(docker run --user 0 --rm "${image}" sh -c 'apk update >/dev/null && apk list --upgradeable')
  echodebug "${output}"
  [[ -n "${output}" ]]
}

function packages_updated_ee() {
  local image=$1
  local output
  # use assumeno as a workaround for lack of dry-run option
  output=$(docker run --user 0 --rm "${image}" sh -c "microdnf --assumeno upgrade --nodocs")
  echodebug "${output}"
  local package_upgrades
  package_upgrades=$(echo "${output}" | grep --count Upgrading)
  [[ "${package_upgrades}" -ne 0 ]]
}
