#!/usr/bin/env bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title WireGuard Keys
# @raycast.mode fullOutput

# Optional parameters:
# @raycast.icon icons/wireguard.svg
# @raycast.packageName me.louisjannett.raycast.wireguard-keys

# Documentation:
# @raycast.description Generate a WireGuard key pair, optionally with a preshared key, or derive the public key of an existing private key. Shows the keys in wg config syntax and copies them to the clipboard, hidden from clipboard history when they include a secret.
# @raycast.author Louis Jannett

# @raycast.argument1 { "type": "dropdown", "placeholder": "Preshared key", "data": [ { "title": "Without preshared key", "value": "no" }, { "title": "With preshared key", "value": "yes" } ], "optional": true }
# @raycast.argument2 { "type": "password", "placeholder": "Private key (derive public key)", "optional": true }

set -euo pipefail

conceal="${WG_KEYS_CONCEAL:-1}"  # 1 = mark the clipboard entry as concealed so clipboard managers (e.g. Raycast's history) skip it

with_psk="${1:-no}"
private_key="${2:-}"
# Pasted keys often carry stray spaces or line breaks.
private_key="${private_key//[[:space:]]/}"

[[ "$with_psk" == "yes" || "$with_psk" == "no" ]] || { echo "Unknown preshared key option '$with_psk'" >&2; exit 1; }

for cmd in wg osascript; do
    command -v "$cmd" >/dev/null 2>&1 || { echo "Missing required command: $cmd" >&2; exit 1; }
done

lines=()
contains_secret=0

if [[ -z "$private_key" ]]; then
    private_key=$(wg genkey)
    lines+=("PrivateKey = $private_key")
    contains_secret=1
fi

# wg rejects malformed keys itself ("Key is not the correct length or format").
public_key=$(wg pubkey <<< "$private_key")
lines+=("PublicKey = $public_key")

if [[ "$with_psk" == "yes" ]]; then
    preshared_key=$(wg genpsk)
    lines+=("PresharedKey = $preshared_key")
    contains_secret=1
fi

# A derived public key on its own isn't secret, so it may stay in the clipboard history.
concealed=0
if [[ "$conceal" == "1" ]] && (( contains_secret )); then
    concealed=1
fi

printf '%s\n' "${lines[@]}"

# Writes through NSPasteboard rather than pbcopy, because only that can add the nspasteboard.org
# concealed marker. The keys go in on stdin so they never show up in the process list.
printf '%s\n' "${lines[@]}" | osascript -l JavaScript -e '
ObjC.import("AppKit");
function run(argv) {
    const data = $.NSFileHandle.fileHandleWithStandardInput.readDataToEndOfFile;
    const keys = $.NSString.alloc.initWithDataEncoding(data, $.NSUTF8StringEncoding);
    const pasteboard = $.NSPasteboard.generalPasteboard;
    pasteboard.clearContents;
    if (!pasteboard.setStringForType(keys, $.NSPasteboardTypeString)) throw new Error("Writing to the clipboard failed");
    if (argv[0] === "1") pasteboard.setStringForType("", "org.nspasteboard.ConcealedType");
}' "$concealed"

echo
if (( concealed )); then
    echo "📋 Copied to clipboard (hidden from clipboard history)"
else
    echo "📋 Copied to clipboard"
fi
