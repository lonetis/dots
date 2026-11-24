#!/usr/bin/env bash
# Focuses the app's previous window (by workspace, then window id). Exits 1 when the app
# has no windows, so Karabiner can launch it instead.
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

(($# == 1)) || die "usage: ${0##*/} <bundle-id>"
bundle_id=$1

app_windows=$(windows --bundle-id "$bundle_id")
target=$(jq -r 'sort_by([.workspace.number, .windowId])
  | (map(.isFocused) | index(true)) as $focused
  | if length == 0 then empty elif $focused == null then .[-1].id else .[$focused - 1].id end' <<<"$app_windows")
[[ -n $target ]] || die "no windows for $bundle_id"
ctl window navigate "$target" >/dev/null
