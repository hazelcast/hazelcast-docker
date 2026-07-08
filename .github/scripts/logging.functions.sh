# Delegate to "github-actions-common-scripts" implementation
source /dev/stdin <<< "$(curl --fail --retry 5 --retry-all-errors --show-error --silent https://raw.githubusercontent.com/hazelcast/github-actions-common-scripts/main/logging.functions.sh)"
