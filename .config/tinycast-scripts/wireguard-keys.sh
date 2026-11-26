#!/usr/bin/env bash
# @raycast.schemaVersion 1
# @raycast.title WireGuard Keys
# @raycast.mode fullOutput
# @raycast.description Generate a WireGuard key pair, optionally with a preshared key, or derive the public key of an existing private key. Shows the keys in wg config syntax and copies them to the clipboard, hidden from clipboard history when they include a secret.
# @raycast.argument1 { "type": "text", "placeholder": "Preshared key: no · yes", "optional": true }
# @raycast.argument2 { "type": "password", "placeholder": "Private key (derive public key)", "optional": true }

set -euo pipefail

# Tinycast has no dropdowns, so a choice is typed: the whole value or any unique prefix of
# it, in any case. Prints the matching choice.
choose() {
    local label="$1" typed="$2" input choice matches=()
    input="$(printf '%s' "$typed" | tr '[:upper:]' '[:lower:]')"
    shift 2
    for choice in "$@"; do
        [[ "$choice" == "$input" ]] && { echo "$choice"; return 0; }
        [[ -n "$input" && "$choice" == "$input"* ]] && matches+=("$choice")
    done
    if (( ${#matches[@]} == 1 )); then echo "${matches[0]}"; return 0; fi
    if (( ${#matches[@]} > 1 )); then
        echo "$label '$typed' could be ${matches[*]}; type more of it" >&2
    else
        echo "Unknown $label '$typed' (use $*)" >&2
    fi
    return 1
}

conceal="${WG_KEYS_CONCEAL:-1}"  # 1 = mark the clipboard entry as concealed so clipboard managers (e.g. Tinycast's history) skip it

with_psk="$(choose "preshared key option" "${1:-no}" no yes)"
private_key="${2:-}"
# Pasted keys often carry stray spaces or line breaks.
private_key="${private_key//[[:space:]]/}"

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
