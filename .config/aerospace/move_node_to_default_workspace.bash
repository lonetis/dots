#!/usr/bin/env bash

default_workspace="q"
echo "Default workspace: $default_workspace"

current_workspace=$(aerospace list-workspaces --focused)
echo "Current workspace: $current_workspace"

focused_app=$(aerospace list-windows --focused --format '%{app-bundle-id}')
echo "Focused app: $focused_app"

target_workspace=$(bash ~/.config/aerospace/map_bundle_id_to_default_workspace.bash "$focused_app")
if [[ "$current_workspace" == "$target_workspace" ]]; then
    target_workspace="$default_workspace"
fi
echo "Target workspace: $target_workspace"

aerospace move-node-to-workspace "$target_workspace"
