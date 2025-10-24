#!/usr/bin/env bash

THRESHOLD=5

if [[ -z "$1" ]]; then
    echo "Usage: $0 <bundle-id>"
    exit 1
fi

bundle_id=$1
echo "Bundle id: $bundle_id"

target_workspace=$(aerospace list-workspaces --monitor mouse --visible)
echo "Target workspace: $target_workspace"

windows_json=$(aerospace list-windows --format "%{window-id} %{workspace}" --app-bundle-id "$bundle_id" --monitor all --json)
if [[ $(echo "$windows_json" | jq "length") -eq 0 ]]; then
    echo "No open windows for bundle id: $bundle_id"
    exit 1
fi
echo "Windows: $windows_json"

focused_window=$(aerospace list-windows --focused --format "%{window-id}")
echo "Focused window: $focused_window"

if [[ -z "$focused_window" ]]; then
    pull_window_info=$(echo $windows_json | jq -r '.[-1] | {id: ."window-id", ws: .workspace}')
else
    pull_window_info=$(echo $windows_json | jq -r --argjson focused $focused_window '
        sort_by(.["window-id"]) as $sorted |
        ($sorted | map({id: ."window-id", ws: .workspace})) as $infos |
        if ($infos | map(.id) | index($focused) | not) then
            $infos[-1]
        else
            $infos[($infos | map(.id) | index($focused) - 1 + length) % length]
        end')
fi

pull_window=$(echo $pull_window_info | jq -r .id)
pull_workspace=$(echo $pull_window_info | jq -r .ws)

echo "Pull window: $pull_window"
echo "Pull workspace: $pull_workspace"

bash ~/.config/aerospace/init_ramdisk.bash

if [[ -f /Volumes/ramdisk/pulled_time.txt && -f /Volumes/ramdisk/pulled_window.txt && -f /Volumes/ramdisk/pulled_workspace.txt ]]; then
    pulled_time=$(cat /Volumes/ramdisk/pulled_time.txt)
    pulled_window=$(cat /Volumes/ramdisk/pulled_window.txt)
    pulled_workspace=$(cat /Volumes/ramdisk/pulled_workspace.txt)

    if (( $(date +%s) - pulled_time < $THRESHOLD )); then
        echo "Pulled less than $THRESHOLD seconds ago..."

        echo "Moving window $pulled_window back to workspace $pulled_workspace"
        aerospace move-node-to-workspace --window-id "$pulled_window" "$pulled_workspace"

        echo "Pulling window $pull_window to workspace $target_workspace"
        aerospace move-node-to-workspace --focus-follows-window --window-id "$pull_window" "$target_workspace"

        echo $(date +%s) > /Volumes/ramdisk/pulled_time.txt
        echo $pull_window > /Volumes/ramdisk/pulled_window.txt
        echo $pull_workspace > /Volumes/ramdisk/pulled_workspace.txt
    else
        echo "Pulled more than $THRESHOLD seconds ago..."

        echo "Pulling window $pull_window to workspace $target_workspace"
        aerospace move-node-to-workspace --focus-follows-window --window-id "$pull_window" "$target_workspace"

        echo $(date +%s) > /Volumes/ramdisk/pulled_time.txt
        echo $pull_window > /Volumes/ramdisk/pulled_window.txt
        echo $pull_workspace > /Volumes/ramdisk/pulled_workspace.txt
    fi
else
    echo "Pulled not found..."

    echo "Pulling window $pull_window to workspace $target_workspace"
    aerospace move-node-to-workspace --focus-follows-window --window-id "$pull_window" "$target_workspace"
    echo $pull_window > /Volumes/ramdisk/pulled_window.txt
    echo $pull_workspace > /Volumes/ramdisk/pulled_workspace.txt
    echo $(date +%s) > /Volumes/ramdisk/pulled_time.txt
fi
