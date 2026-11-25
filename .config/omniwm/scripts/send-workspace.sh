#!/usr/bin/env bash
# Moves the workspace with the key $1 to the next display (wrapping around) and focuses
# it there.
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
source "$(dirname "${BASH_SOURCE[0]}")/displays.sh"

(($# == 1)) || die "usage: ${0##*/} <workspace-key>"

all_displays=$(displays)
all_workspaces=$(workspaces)
workspace=$(workspace_for_key "$1" "$all_workspaces")
move_to_next_display "$workspace" 1 "$all_displays" >/dev/null
