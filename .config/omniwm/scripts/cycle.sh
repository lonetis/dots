#!/usr/bin/env bash
# Focuses the previous window (by workspace, then window id) of the apps with the given
# bundle IDs. Exits 1 when they have no windows, so Karabiner can launch one instead.
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

(($# >= 1)) || die "usage: ${0##*/} <bundle-id>..."

windows_of_apps=$(app_windows "$@")
target=$(jq -r 'sort_by([.workspace.number, .windowId])
  | (map(.isFocused) | index(true)) as $focused
  | if length == 0 then empty elif $focused == null then .[-1].id else .[$focused - 1].id end' <<<"$windows_of_apps")
[[ -n $target ]] || die "no windows for $*"
ctl window navigate "$target" >/dev/null
