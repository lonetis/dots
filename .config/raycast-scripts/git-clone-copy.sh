#!/usr/bin/env bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Git Clone Copy
# @raycast.mode fullOutput

# Optional parameters:
# @raycast.icon icons/git.svg
# @raycast.packageName me.louisjannett.raycast.git-clone-copy

# Documentation:
# @raycast.description Shallow-clones a git repo and copies its contents (without .git) to a destination, overwriting if it exists.
# @raycast.author Louis Jannett

# @raycast.argument1 { "type": "text", "placeholder": "repo-url" }
# @raycast.argument2 { "type": "text", "placeholder": "destination-dir" }
# @raycast.argument3 { "type": "text", "placeholder": "branch / tag (optional)", "optional": true }

set -euo pipefail

repo="$1"
# Expand a leading ~ and strip a trailing slash so the safety checks below are reliable.
dest="${2/#\~/$HOME}"
dest="${dest%/}"
branch="${3:-}"

# Guard against catastrophic overwrites — never wipe an empty path, the FS root, or $HOME.
case "$dest" in
    "" | "/" | "$HOME") echo "Refusing to overwrite '$dest'" >&2; exit 1 ;;
esac

# Clone into a sibling temp dir so the final move is an atomic rename on the same filesystem,
# rather than a slow cp that leaves the destination missing for its entire duration.
parent=$(dirname "$dest")
mkdir -p "$parent"
tmp=$(mktemp -d "$parent/.git-clone-copy.XXXXXX")
trap 'rm -rf "$tmp"' EXIT

# Shallow clone: the history is discarded anyway, so skip fetching it.
clone_args=(--depth 1)
[[ -n "$branch" ]] && clone_args+=(--branch "$branch")
git clone "${clone_args[@]}" "$repo" "$tmp/repo"
rm -rf "$tmp/repo/.git"

rm -rf "$dest"
mv "$tmp/repo" "$dest"

count=$(find "$dest" -type f | wc -l | tr -d ' ')
echo "Done: $repo → $dest ($count files)"
