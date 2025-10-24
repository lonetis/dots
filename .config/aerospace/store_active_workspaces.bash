#!/usr/bin/env bash

bash ~/.config/aerospace/init_ramdisk.bash

active_workspaces=$(aerospace list-workspaces --monitor all --visible)
echo $active_workspaces > /Volumes/ramdisk/active_workspaces.txt
echo "Active workspaces: $active_workspaces"

current_time=$(date +%s)
echo $current_time > /Volumes/ramdisk/active_workspaces_time.txt
echo "Current time: $current_time"
