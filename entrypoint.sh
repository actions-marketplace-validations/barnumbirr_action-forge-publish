#! /usr/bin/env bash

set -eo pipefail

if [ ! -f metadata.json ]; then
    echo "metadata.json not found. Are you in a Puppet module directory?"
    exit 1
fi

RELEASE_NAME=$(jq -r .name metadata.json)
RELEASE_VERSION=$(jq -r .version metadata.json)

if [ -z "$RELEASE_NAME" ] || [ "$RELEASE_NAME" = "null" ]; then
    echo "Could not read 'name' from metadata.json, exiting..."
    exit 1
fi

if [ -z "$RELEASE_VERSION" ] || [ "$RELEASE_VERSION" = "null" ]; then
    echo "Could not read 'version' from metadata.json, exiting..."
    exit 1
fi

NAME="pkg/$RELEASE_NAME-$RELEASE_VERSION"

FORGE_API_KEY="${FORGE_API_KEY:-$INPUT_FORGE_API_KEY}"
REPOSITORY_URL="${REPOSITORY_URL:-$INPUT_REPOSITORY_URL}"

if [ -z "$FORGE_API_KEY" ]; then
    echo "FORGE_API_KEY is not set, exiting..."
    exit 1
fi

if [ -z "$REPOSITORY_URL" ]; then
    echo "REPOSITORY_URL is not set, using Puppet Forge."
    REPOSITORY_URL='https://forgeapi.puppet.com/v3/releases'
fi

function build() {
    pdk build --force
    if [ ! -f "${NAME}.tar.gz" ]; then
        echo "Build artifact ${NAME}.tar.gz not found after pdk build, exiting..."
        exit 1
    fi
}

function upload() {
    curl \
        --fail \
        --silent \
        --max-time 120 \
        --show-error \
        --connect-timeout 5 \
        --retry 3 \
        --form "file=@${NAME}.tar.gz" \
        --header "Authorization: Bearer $FORGE_API_KEY" \
        "$REPOSITORY_URL"
    echo "Successfully published ${RELEASE_NAME} v${RELEASE_VERSION} to ${REPOSITORY_URL}."
}

build
upload
