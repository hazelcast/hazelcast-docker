# shellcheck source=../.github/scripts/logging.functions.sh
. .github/scripts/logging.functions.sh

# Determine if the packages in the specified image are updatable
# Returns exit code:
# 0 if the packages in the image are updatable
# 1 if the packages in the image is up-to-date
function packages_updatable_oss() {
  local image=$1
  local output
  output=$(docker run --user 0 --rm "${image}" sh -c 'apk update >/dev/null && apk list --upgradeable')
  echodebug "${output}"
  [[ -n "${output}" ]]
}

# Determine if the packages in the specified image are updatable
# Returns exit code:
# 0 if the packages in the image are updatable
# 1 if the packages in the image is up-to-date
function packages_updatable_ee() {
  local image=$1
  local output
  # use assumeno as a workaround for lack of dry-run option
  output=$(docker run --user 0 --rm "${image}" sh -c "microdnf --assumeno upgrade --nodocs")
  echodebug "${output}"
  local package_upgrades
  package_upgrades=$(echo "${output}" | grep --count Upgrading)
  [[ "${package_upgrades}" -ne 0 ]]
}
