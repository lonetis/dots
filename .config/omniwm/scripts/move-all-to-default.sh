#!/usr/bin/env bash
# Sends every window to its app's workspace (apps missing from apps.json go to the
# fallback one).
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

all_workspaces=$(workspaces)
all_windows=$(windows)
# Bundle id last: read drops an empty field only at the end of the line.
lines=$(jq -r '.[] | select(.isScratchpad | not) | "\(.id) \(.workspace.rawName) \(.app.bundleId // "")"' <<<"$all_windows")

failures=0
while read -r window_id current bundle_id; do
  [[ -n $window_id ]] || continue
  key=$(default_key "$bundle_id")
  target=$(workspace_for_key "$key" "$all_workspaces" | jq -r .rawName)
  if [[ $current == "$target" ]]; then
    continue
  fi
  (ctl window move-to-workspace "$window_id" "$target" >/dev/null) || failures=$((failures + 1))
done <<<"$lines"
((failures == 0)) || die "$failures windows could not be moved"
