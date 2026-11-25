#!/usr/bin/env bash
# Shows the workspace with the key $1 on the display under the pointer. A workspace
# already visible on another display swaps places with the one shown under the pointer.
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
source "$(dirname "${BASH_SOURCE[0]}")/displays.sh"

(($# == 1)) || die "usage: ${0##*/} <workspace-key>"

all_displays=$(displays)
all_workspaces=$(workspaces)
workspace=$(workspace_for_key "$1" "$all_workspaces")
target=$(display_under_pointer "$all_displays")
raw_name=$(jq -r .rawName <<<"$workspace")
source_id=$(jq -r .display.id <<<"$workspace")
target_id=$(jq -r .id <<<"$target")

if [[ $source_id == "$target_id" ]]; then
  ctl command switch-workspace "$raw_name" >/dev/null
  exit
fi

plan=$(visible_plan "$all_displays")
is_visible=$(jq -r .isVisible <<<"$workspace")
if [[ $is_visible == true ]]; then
  displaced_name=$(jq -r --arg id "$target_id" '.[$id]' <<<"$plan")
  displaced=$(jq -c --arg name "$displaced_name" 'first(.[] | select(.rawName == $name))' <<<"$all_workspaces")
  source_display=$(jq -c --arg id "$source_id" 'first(.[] | select(.id == $id))' <<<"$all_displays")
  move_workspace "$workspace" "$target" "$all_displays"
  moved_displays=$(displays)
  move_workspace "$displaced" "$source_display" "$moved_displays"
  plan=$(jq -c --arg id "$source_id" --arg name "$displaced_name" '.[$id] = $name' <<<"$plan")
else
  move_workspace "$workspace" "$target" "$all_displays"
fi
plan=$(jq -c --arg id "$target_id" --arg name "$raw_name" '.[$id] = $name' <<<"$plan")
show "$plan" "$target_id"
