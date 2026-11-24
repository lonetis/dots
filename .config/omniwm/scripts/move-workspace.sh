#!/usr/bin/env bash
# Moves the current workspace to the next or previous display (wrapping around) and
# puts the pointer there.
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

step=$(parse_step "$@")

all_displays=$(displays)
all_workspaces=$(workspaces)
workspace=$(current_workspace "$all_workspaces")
target=$(move_to_next_display "$workspace" "$step" "$all_displays")
warp_pointer_to "$target" "$all_displays"
