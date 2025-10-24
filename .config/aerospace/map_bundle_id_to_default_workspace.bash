#!/usr/bin/env bash

apps="$HOME/.config/karabiner-config/src/apps.json"

if [[ ! -f "$apps" ]]; then
    echo "File $apps not found"
    exit 1
fi

if [[ -z "$1" ]]; then
    echo "Usage: $0 <bundle-id>"
    exit 1
fi

bundle_id="$1"
key=$(jq -r --arg bundle_id "$bundle_id" 'to_entries[] | select(.value == $bundle_id) | .key' "$apps")

if [[ -n "$key" ]]; then
    echo "$key"
else
    echo "q"
fi
