#!/usr/bin/env bash

function get_supported_versions() {
    local MINIMAL_VERSION=$1
    VERSIONS=$(git tag | grep '^v' | cut -c2- | sed -n "/^${MINIMAL_VERSION}\$/,\$p" | grep -v BETA)
    echo "$VERSIONS"
}
