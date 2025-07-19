#!/usr/bin/env bash

SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"

find "$SCRIPT_DIR" -name "*_tests.sh" -print0 | xargs -0 -n1 bash
