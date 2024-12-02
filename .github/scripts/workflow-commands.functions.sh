#!/usr/bin/env bash

# https://docs.github.com/en/actions/writing-workflows/choosing-what-your-workflow-does/workflow-commands-for-github-actions

# Prints the given message to stderr
function echoerr() {
  # https://docs.github.com/en/actions/writing-workflows/choosing-what-your-workflow-does/workflow-commands-for-github-actions#setting-an-error-message
  echo "::error::ERROR - $*" 1>&2;
}
