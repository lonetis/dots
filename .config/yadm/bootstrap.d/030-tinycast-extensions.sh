#!/usr/bin/env bash
set -euo pipefail

# Custom Raycast extensions, built from source and installed into Tinycast, which runs Raycast
# extensions. Each repo gets its own checkout managed by this script (separate from any dev
# clone under ~/repos), so an update never builds or disturbs work in progress.

extensions=(
  "git@github.com:lonetis/reponizer.git"
)

checkouts_dir="${XDG_DATA_HOME:-$HOME/.local/share}/tinycast-extensions"
tinycast_extensions_dir="$HOME/Library/Application Support/com.abueammar.tinycast/extensions"

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
  local checkout name dir_name build_dir

  checkout="$checkouts_dir/$(basename "$url" .git)"
  echo "Updating Tinycast extension from $url..."

  if ! sync_checkout "$url" "$checkout"; then
    echo "Error: could not fetch $url" >&2
    echo "Private repos need the 1Password SSH agent: unlock 1Password, enable Settings → Developer → SSH agent, then re-run 'yadm bootstrap'." >&2
    return 1
  fi

  # Tinycast keeps an extension in a folder named after its manifest name, with "/" turned
  # into "-" (what its own "Add from folder" does), and loads package.json, the built
  # <command>.js files, assets/ and a bundled node_modules/ from it: the layout of `ray build`.
  name="$(node -p 'require(process.argv[1]).name' "$checkout/package.json")"
  dir_name="${name//\//-}"
  build_dir="$staging_dir/$dir_name"

  (
    cd "$checkout"
    npm ci --no-audit --no-fund
    ./node_modules/.bin/ray build --non-interactive -e dist -o "$build_dir"
  )

  rm -rf "${tinycast_extensions_dir:?}/${dir_name:?}"
  mv "$build_dir" "$tinycast_extensions_dir/$dir_name"
}

mkdir -p "$checkouts_dir" "$tinycast_extensions_dir"

for url in "${extensions[@]}"; do
  install_extension "$url"
done

# Tinycast scans its extensions folder at launch and when Settings → Extensions opens.
if pgrep -xq Tinycast; then
  echo "Restart Tinycast or open Settings → Extensions to load the updated extensions."
fi
