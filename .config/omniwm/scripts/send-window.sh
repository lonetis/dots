#!/usr/bin/env bash
# Sends the focused window to the workspace with the key $1 without following it; OmniWM
# then focuses the next window on the source workspace. With `default` instead of a key,
# the window goes to its app's workspace, or to the fallback one if it is already there.
# Pressing the same key again within OMNIWM_FOLLOW_SECONDS follows the window instead.
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

(($# == 1)) || die "usage: ${0##*/} <workspace-key>|default"
[[ $follow_seconds =~ ^[0-9]+([.][0-9]+)?$ ]] || die "OMNIWM_FOLLOW_SECONDS is not a number: $follow_seconds"
pressed=$(jq -n now)
state_file=$state_dir/send.json
lock_dir=$state_dir/send.lock

# A quick second press starts while the first one still runs, so presses take turns. A
# lock still held after 2 s belongs to a script that died, so this one takes it over.
mkdir -p "$state_dir"
for _ in {1..100}; do
  mkdir "$lock_dir" 2>/dev/null && break
  sleep 0.02
done
trap 'rmdir "$lock_dir" 2>/dev/null || true' EXIT

if [[ -f $state_file ]]; then
  last=$(jq -r --arg key "$1" --argjson pressed "$pressed" --argjson limit "$follow_seconds" \
    'select(.key == $key and $pressed - .time < $limit) | .window' "$state_file") \
    || { echo "${0##*/}: ignoring unreadable $state_file" >&2; last=; }
  rm -f "$state_file"
  if [[ -n $last ]]; then
    ctl window navigate "$last" >/dev/null
    exit
  fi
fi

window=$(require_focused_window)
window_id=$(jq -r .id <<<"$window")
all_workspaces=$(workspaces)
if [[ $1 == default ]]; then
  bundle_id=$(jq -r '.app.bundleId // empty' <<<"$window")
  current=$(jq -r .workspace.rawName <<<"$window")
  target=$(workspace_for_key "$(default_key "$bundle_id")" "$all_workspaces" | jq -r .rawName)
  if [[ $current == "$target" ]]; then
    target=$(workspace_for_key "$fallback_key" "$all_workspaces" | jq -r .rawName)
  fi
else
  target=$(workspace_for_key "$1" "$all_workspaces" | jq -r .rawName)
fi
# The native command moves the focused window and leaves focus on the source workspace.
ctl command move-to-workspace "$target" >/dev/null
jq -nc --arg window "$window_id" --arg key "$1" --argjson time "$pressed" \
  '{time: $time, window: $window, key: $key}' >"$state_file"
