#!/usr/bin/env bash
# Moves the focused window to the workspace with the key $1 and follows it.
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

(($# == 1)) || die "usage: ${0##*/} <workspace-key>"

window=$(require_focused_window)
all_workspaces=$(workspaces)
target=$(workspace_for_key "$1" "$all_workspaces" | jq -r .rawName)
window_id=$(jq -r .id <<<"$window")
ctl window move-to-workspace "$window_id" "$target" >/dev/null
ctl window navigate "$window_id" >/dev/null
