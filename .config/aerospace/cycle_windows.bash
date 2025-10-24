#!/usr/bin/env bash

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

previous_window=$(echo $windows_json | jq -r --argjson focused $focused_window '
    sort_by(.workspace, .["window-id"]) as $sorted |
    ($sorted | map(."window-id")) as $ids |
    if ($ids | index($focused) | not) then
        $ids[-1]
    else
        $ids[($ids | index($focused) - 1 + length) % length]
    end')

echo "Previous window: $previous_window"

aerospace focus --window-id "$previous_window"
