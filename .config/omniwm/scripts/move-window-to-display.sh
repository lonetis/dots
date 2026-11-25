#!/usr/bin/env bash
# Moves the focused window to the next or previous display (wrapping around) and
# follows it.
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
source "$(dirname "${BASH_SOURCE[0]}")/displays.sh"

step=$(parse_step "$@")

all_displays=$(displays)
window=$(require_focused_window)
window_id=$(jq -r .id <<<"$window")
window_display_id=$(jq -r .display.id <<<"$window")
target=$(cycle_display "$window_display_id" "$step" "$all_displays")
target_workspace=$(jq -r .activeWorkspace.rawName <<<"$target")
ctl window move-to-workspace "$window_id" "$target_workspace" >/dev/null
ctl window navigate "$window_id" >/dev/null
