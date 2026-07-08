#!/usr/bin/env bash

if [[ -z "$1" ]]; then
    echo "Usage: $0 <bundle-id>"
    exit 1
fi

bundle_id=$1

focused_app=$(aerospace list-windows --focused --format "%{app-bundle-id}")
focused_window_workspace=$(aerospace list-windows --focused --format "%{workspace}")
focused_workspace=$(aerospace list-workspaces --focused)
if [[ "$focused_app" == "$bundle_id" && "$focused_window_workspace" == "$focused_workspace" ]]; then
    echo "Hiding $bundle_id"
    aerospace close
    exit 0
fi

app_window_id=$(aerospace list-windows --app-bundle-id "$bundle_id" --monitor all --format "%{window-id}")
echo "App $bundle_id is on window: $app_window_id"

if [[ -z "$app_window_id" ]]; then
    echo "App $bundle_id is not running, starting it"
    open -b "$bundle_id"
    exit 0
fi

echo "Moving window $app_window_id from app $bundle_id to focused workspace: $focused_workspace"
aerospace move-node-to-workspace --window-id "$app_window_id" --focus-follows-window --fail-if-noop "$focused_workspace" || aerospace focus --window-id "$app_window_id"
exit 0
