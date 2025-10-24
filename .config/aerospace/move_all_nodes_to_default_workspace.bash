#!/usr/bin/env bash

default_workspace="q"
echo "Default workspace: $default_workspace"

all_windows=$(aerospace list-windows --all --format "%{window-id} %{app-bundle-id}")

IFS=$'\n'
for window in $all_windows; do
    window_id=$(echo "$window" | awk '{print $1}')
    app_bundle_id=$(echo "$window" | awk '{print $2}')
    echo "Window ID: $window_id, App Bundle ID: $app_bundle_id"

    target_workspace=$(bash ~/.config/aerospace/map_bundle_id_to_default_workspace.bash "$app_bundle_id")
    if [[ "$current_workspace" == "$target_workspace" ]]; then
        target_workspace="$default_workspace"
    fi

    aerospace move-node-to-workspace --fail-if-noop --window-id "$window_id" "$target_workspace" >/dev/null 2>&1
    if [[ $? -eq 0 ]]; then
        echo "    -> Successfully moved to workspace: $target_workspace"
    else
        echo "    -> Failed to move to workspace: $target_workspace"
    fi
done
