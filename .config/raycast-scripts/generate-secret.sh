#!/usr/bin/env bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Generate Secret
# @raycast.mode silent

# Optional parameters:
# @raycast.icon icons/key.svg
# @raycast.packageName me.louisjannett.raycast.generate-secret

# Documentation:
# @raycast.description Generate a random secret from the chosen character classes and copy it to the clipboard, hidden from clipboard history. Every chosen class appears at least once.
# @raycast.author Louis Jannett

# @raycast.argument1 { "type": "text", "placeholder": "Length", "optional": true }
# @raycast.argument2 { "type": "dropdown", "placeholder": "Characters", "data": [ { "title": "Aa1#  letters, digits, symbols", "value": "ulds" }, { "title": "Aa1  letters, digits", "value": "uld" }, { "title": "a1  lowercase, digits", "value": "ld" }, { "title": "A1  uppercase, digits", "value": "ud" }, { "title": "hex  0-9 a-f", "value": "h" }, { "title": "1  digits", "value": "d" }, { "title": "Aa  letters", "value": "ul" }, { "title": "a  lowercase", "value": "l" }, { "title": "A  uppercase", "value": "u" }, { "title": "Aa#  letters, symbols", "value": "uls" }, { "title": "a1#  lowercase, digits, symbols", "value": "lds" }, { "title": "A1#  uppercase, digits, symbols", "value": "uds" }, { "title": "a#  lowercase, symbols", "value": "ls" }, { "title": "A#  uppercase, symbols", "value": "us" }, { "title": "1#  digits, symbols", "value": "ds" }, { "title": "#  symbols", "value": "s" } ], "optional": true }
# @raycast.argument3 { "type": "text", "placeholder": "Exclude chars", "optional": true }

set -euo pipefail

default_length="${SECRET_LENGTH:-32}"                      # length used when the Length argument is empty
symbols="${SECRET_SYMBOLS:-!#%&()*+,-./:;<=>?@[]^_{|\}~}"  # symbol class; the default omits ' " ` \ $, which break quoting in shells, .env files and JSON
conceal="${SECRET_CONCEAL:-1}"                             # 1 = mark the clipboard entry as concealed so clipboard managers (e.g. Raycast's history) skip it

length="${1:-$default_length}"
spec="${2:-ulds}"
exclude="${3:-}"

for cmd in od awk osascript; do
    command -v "$cmd" >/dev/null 2>&1 || { echo "Missing required command: $cmd" >&2; exit 1; }
done

[[ "$length" =~ ^[0-9]+$ ]] && (( 10#$length > 0 )) || { echo "Length must be a positive integer (got '$length')" >&2; exit 1; }
length=$(( 10#$length ))

# Each letter of the dropdown value selects one character class.
class_names=()
class_chars=()
for (( i = 0; i < ${#spec}; i++ )); do
    case "${spec:i:1}" in
        u) class_names+=("uppercase"); class_chars+=("ABCDEFGHIJKLMNOPQRSTUVWXYZ") ;;
        l) class_names+=("lowercase"); class_chars+=("abcdefghijklmnopqrstuvwxyz") ;;
        d) class_names+=("digit");     class_chars+=("0123456789") ;;
        s) class_names+=("symbol");    class_chars+=("$symbols") ;;
        h) class_names+=("hex");       class_chars+=("0123456789abcdef") ;;
        *) echo "Unknown character class '${spec:i:1}' in '$spec'" >&2; exit 1 ;;
    esac
done

# The quoted pattern makes each excluded character match literally, even glob characters like * or [.
for (( i = 0; i < ${#exclude}; i++ )); do
    char="${exclude:i:1}"
    for j in "${!class_chars[@]}"; do
        class_chars[j]="${class_chars[j]//"$char"/}"
    done
done

pool=""
for j in "${!class_chars[@]}"; do
    [[ -n "${class_chars[j]}" ]] || { echo "Excluding '$exclude' leaves no ${class_names[j]} characters" >&2; exit 1; }
    pool+="${class_chars[j]}"
done

(( ${#pool} <= 256 )) || { echo "Character pool is too large (${#pool} > 256), shorten SECRET_SYMBOLS" >&2; exit 1; }
(( length >= ${#class_chars[@]} )) || { echo "Length $length is too short to include all ${#class_chars[@]} selected classes" >&2; exit 1; }

random_string() {
    local pool="$1" length="$2"
    local size=${#pool}
    # Bytes at or above the largest multiple of the pool size are rejected, so every character is equally likely (no modulo bias).
    local limit=$(( 256 - 256 % size ))
    local out="" byte
    while (( ${#out} < length )); do
        for byte in $(od -An -tu1 -N "$length" /dev/urandom); do
            (( byte < limit )) || continue
            out+="${pool:byte % size:1}"
            (( ${#out} < length )) || break
        done
    done
    printf '%s' "$out"
}

contains_any() {
    local string="$1" chars="$2" i
    for (( i = 0; i < ${#chars}; i++ )); do
        [[ "$string" == *"${chars:i:1}"* ]] && return 0
    done
    return 1
}

# Redrawing the whole secret until every class is present keeps the result uniform among valid secrets,
# unlike patching in characters afterwards.
while true; do
    secret=$(random_string "$pool" "$length")
    complete=1
    for chars in "${class_chars[@]}"; do
        contains_any "$secret" "$chars" || { complete=0; break; }
    done
    (( complete )) && break
done

# Writes through NSPasteboard rather than pbcopy, because only that can add the nspasteboard.org
# concealed marker. The secret goes in on stdin so it never shows up in the process list.
printf '%s' "$secret" | osascript -l JavaScript -e '
ObjC.import("AppKit");
function run(argv) {
    const data = $.NSFileHandle.fileHandleWithStandardInput.readDataToEndOfFile;
    const secret = $.NSString.alloc.initWithDataEncoding(data, $.NSUTF8StringEncoding);
    const pasteboard = $.NSPasteboard.generalPasteboard;
    pasteboard.clearContents;
    if (!pasteboard.setStringForType(secret, $.NSPasteboardTypeString)) throw new Error("Writing to the clipboard failed");
    if (argv[0] === "1") pasteboard.setStringForType("", "org.nspasteboard.ConcealedType");
}' "$conceal"

bits=$(awk -v size="${#pool}" -v len="$length" 'BEGIN { printf "%d", len * log(size) / log(2) }')
echo "🔑 Copied ${length}-char secret (~${bits} bits)"
