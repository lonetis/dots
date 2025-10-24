#!/usr/bin/env bash

THRESHOLD=5

if [[ -z "$1" ]]; then
    echo "Usage: $0 <bundle-id>"
    exit 1
fi

bundle_id=$1
echo "Bundle id: $bundle_id"

windows_json=$(aerospace list-windows --format "%{window-id} %{workspace}" --app-bundle-id "$bundle_id" --monitor all --json)
if [[ $(echo "$windows_json" | jq "length") -eq 0 ]]; then
    echo "No open windows for bundle id: $bundle_id"
    exit 1
fi
echo "Windows: $windows_json"

focused_window=$(aerospace list-windows --focused --format "%{window-id}")
echo "Focused window: $focused_window"

previous_window_info=$(echo $windows_json | jq -r --argjson focused $focused_window '
    sort_by(.workspace, .["window-id"]) as $sorted |
    ($sorted | map({id: ."window-id", ws: .workspace})) as $infos |
    if ($infos | map(.id) | index($focused) | not) then
        $infos[-1]
    else
        $infos[($infos | map(.id) | index($focused) - 1 + length) % length]
    end')

previous_window=$(echo $previous_window_info | jq -r .id)
previous_workspace=$(echo $previous_window_info | jq -r .ws)

echo "Previous window: $previous_window"
echo "Previous workspace: $previous_workspace"

if [[ ! -f /Volumes/ramdisk/active_workspaces_time.txt ]]; then
    echo "Active workspaces time file not found. Not restoring them."
    bash ~/.config/aerospace/store_active_workspaces.bash

    echo "Focusing previous window $previous_window on workspace $previous_workspace"
    aerospace focus --window-id "$previous_window"
    exit 0
fi

current_time=$(date +%s)
stored_time=$(cat /Volumes/ramdisk/active_workspaces_time.txt)
if (( current_time - stored_time > $THRESHOLD )); then
    echo "Active workspaces stored more than $THRESHOLD seconds ago. Not restoring them."
    bash ~/.config/aerospace/store_active_workspaces.bash

    echo "Focusing previous window $previous_window on workspace $previous_workspace"
    aerospace focus --window-id "$previous_window"
    exit 0
fi

echo "Active workspaces stored less than $THRESHOLD seconds ago. Restoring them."
bash ~/.config/aerospace/restore_active_workspaces.bash

echo "Focusing previous window $previous_window on workspace $previous_workspace"
aerospace focus --window-id "$previous_window"
