#!/usr/bin/env bash
set -euo pipefail

# Custom Raycast extensions, built from source. Each repo gets its own checkout
# managed by this script (separate from any dev clone under ~/repos), so an
# update never builds or disturbs work in progress.

extensions=(
  "git@github.com:lonetis/reponizer.git"
  "git@github.com:lonetis/raycast-extension-pull-window.git"
)

checkouts_dir="${XDG_DATA_HOME:-$HOME/.local/share}/raycast-extensions"
raycast_extensions_dir="$HOME/.config/raycast/extensions"

# On a fresh machine this is the first SSH connection to github.com; accept its
# host key instead of stopping at a prompt (a changed key is still refused).
export GIT_SSH_COMMAND="ssh -o StrictHostKeyChecking=accept-new"

staging_dir="$(mktemp -d)"
trap 'rm -rf "$staging_dir"' EXIT

sync_checkout() {
  local url="$1" checkout="$2"

  if [[ -d "$checkout/.git" ]]; then
    git -C "$checkout" remote set-url origin "$url" &&
      git -C "$checkout" pull --ff-only
  else
    git clone "$url" "$checkout"
  fi
}

install_extension() {
  local url="$1"
  local checkout name build_dir

  checkout="$checkouts_dir/$(basename "$url" .git)"
  echo "Updating Raycast extension from $url..."

  if ! sync_checkout "$url" "$checkout"; then
    echo "Error: could not fetch $url" >&2
    echo "Private repos need the 1Password SSH agent: unlock 1Password, enable Settings → Developer → SSH agent, then re-run 'yadm bootstrap'." >&2
    return 1
  fi

  # Raycast keys local extensions by their manifest name, which is also the
  # directory name it expects inside its extensions folder.
  name="$(node -p 'require(process.argv[1]).name' "$checkout/package.json")"
  build_dir="$staging_dir/$name"

  (
    cd "$checkout"
    npm ci --no-audit --no-fund
    ./node_modules/.bin/ray build --non-interactive -e dist -o "$build_dir"
  )

  rm -rf "${raycast_extensions_dir:?}/${name:?}"
  mv "$build_dir" "$raycast_extensions_dir/$name"
}

mkdir -p "$checkouts_dir" "$raycast_extensions_dir"

for url in "${extensions[@]}"; do
  install_extension "$url"
done
