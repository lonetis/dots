#!/usr/bin/env bash
# Sends the focused window to its app's workspace, or to the fallback one if it is
# already there.
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

window=$(require_focused_window)
all_workspaces=$(workspaces)
window_id=$(jq -r .id <<<"$window")
bundle_id=$(jq -r '.app.bundleId // empty' <<<"$window")
current=$(jq -r .workspace.rawName <<<"$window")
key=$(default_key "$bundle_id")
target=$(workspace_for_key "$key" "$all_workspaces" | jq -r .rawName)
if [[ $current == "$target" ]]; then
  target=$(workspace_for_key "$fallback_key" "$all_workspaces" | jq -r .rawName)
fi
ctl window move-to-workspace "$window_id" "$target" >/dev/null
