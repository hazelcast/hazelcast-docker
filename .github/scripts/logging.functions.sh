# https://docs.github.com/en/actions/writing-workflows/choosing-what-your-workflow-does/workflow-commands-for-github-actions

# Prints the given message to stderr
function echoerr() {
  # https://docs.github.com/en/actions/writing-workflows/choosing-what-your-workflow-does/workflow-commands-for-github-actions#setting-an-error-message
  echo "::error::ERROR - $*" 1>&2;
}

# Prints the given message to debug logs, _if enabled_
function echodebug() {
  # https://docs.github.com/en/actions/writing-workflows/choosing-what-your-workflow-does/workflow-commands-for-github-actions#setting-a-debug-message
  echo "::debug::$*" 1>&2;
}

# Create group
function echo_group() {
  # https://docs.github.com/en/actions/writing-workflows/choosing-what-your-workflow-does/workflow-commands-for-github-actions#grouping-log-lines
  local TITLE=$1
  echo "::group::${TITLE}"
}

# Ends group after calling echo_group()
function echo_group_end() {
  # https://docs.github.com/en/actions/writing-workflows/choosing-what-your-workflow-does/workflow-commands-for-github-actions#grouping-log-lines
  echo "::endgroup::"
}
