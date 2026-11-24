#!/usr/bin/env bash
# Opens a new window of the focused app (apps that ignore `open -n` just get focused).
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

window=$(require_focused_window)
bundle_id=$(jq -r '.app.bundleId // empty' <<<"$window")
[[ -n $bundle_id ]] || die "the focused window has no bundle id"
open -n -b "$bundle_id"
