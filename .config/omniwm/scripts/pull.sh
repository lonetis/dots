#!/usr/bin/env bash
# Moves the previous window of the apps with the given bundle IDs to the workspace under
# the pointer and focuses it. Pulling again within OMNIWM_PULL_RESTORE_SECONDS sends the
# last pulled window back first, so repeated presses step through the apps' windows.
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
source "$(dirname "${BASH_SOURCE[0]}")/displays.sh"

(($# >= 1)) || die "usage: ${0##*/} <bundle-id>..."
state_file=$state_dir/pull.json
[[ $pull_restore_seconds =~ ^[0-9]+([.][0-9]+)?$ ]] || die "OMNIWM_PULL_RESTORE_SECONDS is not a number: $pull_restore_seconds"

all_displays=$(displays)
target_display=$(display_under_pointer "$all_displays")
target_workspace=$(jq -r .activeWorkspace.rawName <<<"$target_display")
windows_of_apps=$(app_windows "$@")
window=$(jq -c 'sort_by(.windowId)
  | (map(.isFocused) | index(true)) as $focused
  | if length == 0 then empty elif $focused == null then .[-1] else .[$focused - 1] end' <<<"$windows_of_apps")
[[ -n $window ]] || die "no windows for $*"
window_id=$(jq -r .id <<<"$window")
source_workspace=$(jq -r .workspace.rawName <<<"$window")

if [[ -f $state_file ]]; then
  if last=$(jq -r --argjson limit "$pull_restore_seconds" 'select(now - .time < $limit) | "\(.window) \(.workspace)"' "$state_file"); then
    if [[ -n $last ]]; then
      read -r last_window last_workspace <<<"$last"
      # The window may have been closed in the meantime.
      (ctl window move-to-workspace "$last_window" "$last_workspace" >/dev/null) \
        || echo "${0##*/}: cannot send back the last pulled window" >&2
    fi
  else
    echo "${0##*/}: ignoring unreadable $state_file" >&2
  fi
fi

ctl window move-to-workspace "$window_id" "$target_workspace" >/dev/null
ctl window navigate "$window_id" >/dev/null
mkdir -p "$state_dir"
jq -nc --arg window "$window_id" --arg workspace "$source_workspace" \
  '{time: now, window: $window, workspace: $workspace}' >"$state_file"
