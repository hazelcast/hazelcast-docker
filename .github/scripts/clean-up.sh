#!/bin/bash

set -e
set -o pipefail

PROJECT=$1
helm uninstall ${PROJECT} --timeout 30s
oc delete project ${PROJECT}