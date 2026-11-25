#!/usr/bin/env bash
# Moves the current workspace to the next or previous display (wrapping around). With
# OMNIWM_WARP_POINTER=true it also puts the pointer there.
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
source "$(dirname "${BASH_SOURCE[0]}")/displays.sh"

step=$(parse_step "$@")
case $warp_pointer in
  true | false) ;;
  *) die "OMNIWM_WARP_POINTER must be true or false: $warp_pointer" ;;
esac

all_displays=$(displays)
all_workspaces=$(workspaces)
workspace=$(current_workspace "$all_workspaces")
target=$(move_to_next_display "$workspace" "$step" "$all_displays")
if [[ $warp_pointer == true ]]; then
  warp_pointer_to "$target" "$all_displays"
fi
