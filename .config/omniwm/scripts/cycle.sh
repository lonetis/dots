#!/usr/bin/env bash
# Focuses a window of the apps with the given bundle IDs. When none of them has focus, it
# returns to the one focused last (OmniWM's focus rank, 0 = most recent); when one has,
# it steps to the previous window by workspace, then window id. Exits 1 when the apps
# have no windows, so Karabiner can launch one instead.
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

(($# >= 1)) || die "usage: ${0##*/} <bundle-id>..."

windows_of_apps=$(app_windows "$@")
# Windows OmniWM never saw focused have no rank; without any rank, take the last one.
target=$(jq -r 'sort_by([.workspace.number, .windowId])
  | (map(.isFocused) | index(true)) as $focused
  | if length == 0 then empty
    elif $focused != null then .[$focused - 1].id
    else ((map(select(.focusRank != null)) | min_by(.focusRank)) // .[-1]).id
    end' <<<"$windows_of_apps")
[[ -n $target ]] || die "no windows for $*"
ctl window navigate "$target" >/dev/null
