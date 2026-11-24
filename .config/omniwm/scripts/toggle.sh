#!/usr/bin/env bash
# Closes the app's window if it has focus on the current workspace, otherwise brings one
# of its windows here and focuses it (or launches the app).
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

(($# == 1)) || die "usage: ${0##*/} <bundle-id>"
bundle_id=$1

all_workspaces=$(workspaces)
current=$(current_workspace "$all_workspaces" | jq -r .rawName)
focused=$(focused_window)
if [[ -n $focused ]] && jq -e --arg bundle_id "$bundle_id" --arg current "$current" \
  '.app.bundleId == $bundle_id and .workspace.rawName == $current' <<<"$focused" >/dev/null; then
  focused_id=$(jq -r .id <<<"$focused")
  ctl window close "$focused_id" >/dev/null
  exit
fi

app_windows=$(windows --bundle-id "$bundle_id")
window_id=$(jq -r '.[0].id // empty' <<<"$app_windows")
if [[ -z $window_id ]]; then
  open -b "$bundle_id"
  exit
fi
ctl window move-to-workspace "$window_id" "$current" >/dev/null
ctl window navigate "$window_id" >/dev/null
