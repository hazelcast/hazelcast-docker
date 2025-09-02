# https://docs.github.com/en/actions/writing-workflows/choosing-what-your-workflow-does/workflow-commands-for-github-actions

# Prints the given message to stderr
function echoerr() {
  # https://docs.github.com/en/actions/writing-workflows/choosing-what-your-workflow-does/workflow-commands-for-github-actions#setting-an-error-message
  __log "error" "ERROR - " "${*}"
}

# Prints the given message as a warning
function echowarning() {
  # https://docs.github.com/en/actions/writing-workflows/choosing-what-your-workflow-does/workflow-commands-for-github-actions#setting-a-warning-message
  __log "warning" "${*}"
}

# Prints the given message as a notice
function echonotice() {
  # https://docs.github.com/en/actions/writing-workflows/choosing-what-your-workflow-does/workflow-commands-for-github-actions#setting-a-notice-message
  # __log "notice" "${*}"
  echo "::notice::${*//$'\n'/%0A}" 1>&2;
}

# Prints the given message to debug logs, _if enabled_
function echodebug() {
  # https://docs.github.com/en/actions/writing-workflows/choosing-what-your-workflow-does/workflow-commands-for-github-actions#setting-a-debug-message
  __log "debug" "${*}"
}

# Create group
function echo_group() {
  # https://docs.github.com/en/actions/writing-workflows/choosing-what-your-workflow-does/workflow-commands-for-github-actions#grouping-log-lines
  __log "group" "${*}"
}

# Ends group after calling echo_group()
function echo_group_end() {
  # https://docs.github.com/en/actions/writing-workflows/choosing-what-your-workflow-does/workflow-commands-for-github-actions#grouping-log-lines
  __log "endgroup"
}

function __log() {
  local level=$1
  shift
  local msg="$*"

  # Support multi-line strings by replacing line separator with GitHub Actions compatible one
  msg="${msg//$'\n'/%0A}"
  echo "::${level}::$msg" 1>&2
}
