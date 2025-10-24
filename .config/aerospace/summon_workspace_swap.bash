#!/usr/bin/env bash

if [[ -z "$1" ]]; then
    echo "Usage: $0 <workspace>"
    exit 1
fi

target_workspace=$1
# target_monitor=$(aerospace list-monitors --focused --format "%{monitor-id}")
target_monitor=$(aerospace list-monitors --mouse --format "%{monitor-id}")
echo "Moving workspace $target_workspace to monitor $target_monitor"

focused_workspace_on_target_monitor=$(aerospace list-workspaces --monitor "$target_monitor" --visible --format "%{workspace}")
echo "Focused workspace on monitor $target_monitor: $focused_workspace_on_target_monitor"

all_monitors=$(aerospace list-monitors --format "%{monitor-id}")
for monitor in $all_monitors; do
    focused_workspace_on_monitor=$(aerospace list-workspaces --monitor "$monitor" --visible --format "%{workspace}")
    echo "Focused workspace on monitor $monitor: $focused_workspace_on_monitor"

    if [[ "$monitor" == "$target_monitor" && "$focused_workspace_on_monitor" == "$target_workspace" ]]; then
        echo "Workspace $target_workspace is already on monitor $monitor"
        exit 0
    fi

    # TODO: add check if workspace is already on target monitor, and if so, just focus workspace instead of summon

    if [[ "$monitor" != "$target_monitor" && "$focused_workspace_on_monitor" == "$target_workspace" ]]; then
        echo "Swapping workspace $focused_workspace_on_monitor on monitor $monitor with workspace $focused_workspace_on_target_monitor on monitor $target_monitor"
        aerospace summon-workspace 0
        aerospace focus-monitor "$monitor"
        aerospace summon-workspace "$focused_workspace_on_target_monitor"
        aerospace focus-monitor "$target_monitor"
        aerospace summon-workspace "$target_workspace"
        exit 0
    fi
done

echo "Summon workspace $target_workspace to monitor $target_monitor"
aerospace summon-workspace "$target_workspace"
