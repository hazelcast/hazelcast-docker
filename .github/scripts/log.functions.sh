#!/bin/bash

if command -v tput &>/dev/null && tty -s; then
  RED=$(tput setaf 1)
  GREEN=$(tput setaf 2)
  YELLOW=$(tput setaf 3)
  MAGENTA=$(tput setaf 5)
  NORMAL=$(tput sgr0)
  BOLD=$(tput bold)
else
  RED=$(echo -en "\e[31m")
  GREEN=$(echo -en "\e[32m")
  YELLOW=$(echo -en "\e[33m")
  MAGENTA=$(echo -en "\e[35m")
  NORMAL=$(echo -en "\e[00m")
  BOLD=$(echo -en "\e[01m")
fi

log_info() {
  printf "${GREEN}%s${NORMAL}\n" "$@" >&2
}

log_warn() {
  printf "${YELLOW}%s${NORMAL}\n" "$@" >&2
}

log_error() {
  printf "${RED}%s${NORMAL}\n" "$@" >&2
}
