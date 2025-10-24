#!/usr/bin/env bash

bash ~/.config/aerospace/init_ramdisk.bash

if [[ ! -f /Volumes/ramdisk/active_workspaces.txt ]]; then
    echo "Active workspaces files not found. Exiting."
    exit 1
fi

active_workspaces=$(aerospace list-workspaces --monitor all --visible)
echo "Active workspaces: $active_workspaces"

stored_workspaces=$(cat /Volumes/ramdisk/active_workspaces.txt)
echo "Stored workspaces: $stored_workspaces"

for w in $stored_workspaces; do
    if [[ ! $active_workspaces =~ $w ]]; then
        echo "Restoring workspace: $w"
        aerospace workspace "$w"
    fi
done

current_time=$(date +%s)
echo $current_time > /Volumes/ramdisk/active_workspaces_time.txt
echo "Current time: $current_time"
