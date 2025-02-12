#!/bin/bash

PROJECT=$1
helm uninstall "${PROJECT}" --timeout 30s
oc delete project "${PROJECT}"