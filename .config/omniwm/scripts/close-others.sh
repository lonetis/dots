#!/usr/bin/env bash
# Closes every other window on the focused window's workspace.
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

(($# == 0)) || die "usage: ${0##*/}"

window=$(require_focused_window)
window_id=$(jq -r .id <<<"$window")
workspace=$(jq -r .workspace.rawName <<<"$window")
all_windows=$(windows)
others=$(jq -r --arg id "$window_id" --arg workspace "$workspace" \
  '.[] | select(.workspace.rawName == $workspace and .id != $id) | .id' <<<"$all_windows")
for other in $others; do
  ctl window close "$other" >/dev/null
done
