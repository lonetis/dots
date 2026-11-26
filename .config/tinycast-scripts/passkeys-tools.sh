#!/usr/bin/env bash
# @raycast.schemaVersion 1
# @raycast.title Passkeys.Tools Browser
# @raycast.mode compact
# @raycast.description Ephemeral Chrome for Testing preconfigured with the Passkeys.Tools Interceptor — attacker (red), victim (yellow), default, or both. Fresh random profile each run, wiped on close.
# @raycast.argument1 { "type": "text", "placeholder": "Setup: attacker · victim · default · dual" }

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

setup="$(choose setup "${1:-}" attacker victim default dual)"
ext_id="${PK_EXT_ID:-jeocfgcignclemjmlnmmhlcnalfioflg}"        # Chrome Web Store extension ID
channel="${PK_CHANNEL:-Stable}"                                # Chrome for Testing channel
cache_dir="${PK_CACHE_DIR:-/tmp/pk-passkeys-tools-cache}"      # cached browser download (reused across runs)
start_url="${PK_START_URL:-https://passkeys.tools}"            # landing page (default role)
frontend_url="${PK_FRONTEND_URL:-https://passkeys.tools}"      # passkeys.tools frontend; its /settings page is auto-configured for attacker/victim
storage_backend="${PK_STORAGE_BACKEND:-https://db.passkeys.tools}"  # remote storage server URL
chrome_bin_override="${PK_CHROME_BIN:-}"                        # optional: use this Chromium/CfT binary instead of downloading

# Shared 16-hex remote-storage secret. The same value is used for attacker and
# victim so both browsers share one storage bucket (cross-browser credential swap).
storage_secret="${PK_STORAGE_SECRET:-$(od -An -tx1 -N8 /dev/urandom | tr -d ' \n')}"

# Fixed manifest key -> deterministic unpacked extension ID, so the toolbar pin
# (extensions.pinned_extensions) can reference a stable ID across runs. Only the
# public key is needed; unpacked extensions are not signed.
ext_key="MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAjRnlzVEvgkvNwSjyVH74EcaxRkJ9hb+DcycYcIM+GvlDMVL16IQHKRInDnBZdKTzIgGhoBDwsWPPkT4XVvBtc+V607/XdngfFdg/nJld0rgJ9+i2SiHhLTf/l3kp3+RMtik4dVoP8txJrY2U+xG35NonbQRnjuPe5JMFjgI/t6AkR3gqEYgBFbEcFx7qZ6Z/p9EC4QJEQVrO0fd9IhSNJEWU3oQ7+M+xoyOwAG6wA/+50W5A2NY0IzOqjjOwkfi44oXIS/HyGaCLSJn7CH4qWm2Pf7usZ0wPU9ISkIMe6yE1xs7w7f1hpqoppeA0N7VXWeQh7ygXLtkLGj/1uHVi8wIDAQAB"
ext_pin_id="knoaiofeihcfamclcfejehgdfceeahfi"

for cmd in curl unzip jq od tail head uname mktemp; do
    command -v "$cmd" >/dev/null 2>&1 || { echo "Missing required command: $cmd" >&2; exit 1; }
done

# Only the dual setup configures remote storage — it drives the browser over CDP with Node.
case "$setup" in
    dual) command -v node >/dev/null 2>&1 || { echo "Missing required command: node (needed to configure remote storage)" >&2; exit 1; } ;;
esac

# Chrome 137+ dropped --load-extension from branded Chrome, so use Chrome for
# Testing (same engine, still honours it). Downloaded once from the official
# availability API and cached; profiles + extensions are always rebuilt fresh.
case "$(uname -s)-$(uname -m)" in
    Darwin-arm64)  plat="mac-arm64"; subbin="chrome-mac-arm64/Google Chrome for Testing.app/Contents/MacOS/Google Chrome for Testing" ;;
    Darwin-x86_64) plat="mac-x64";   subbin="chrome-mac-x64/Google Chrome for Testing.app/Contents/MacOS/Google Chrome for Testing" ;;
    Linux-x86_64)  plat="linux64";   subbin="chrome-linux64/chrome" ;;
    *) echo "Unsupported platform: $(uname -s)-$(uname -m)" >&2; exit 1 ;;
esac

if [[ -n "$chrome_bin_override" ]]; then
    chrome_bin="$chrome_bin_override"
    [[ -x "$chrome_bin" ]] || { echo "PK_CHROME_BIN not executable: $chrome_bin" >&2; exit 1; }
else
    cft_dir="$cache_dir/cft-$channel-$plat"
    chrome_bin="$cft_dir/$subbin"
    if [[ ! -x "$chrome_bin" ]]; then
        echo "Fetching Chrome for Testing ($channel, $plat, ~170MB, cached)"
        meta="$(curl -fsSL 'https://googlechromelabs.github.io/chrome-for-testing/last-known-good-versions-with-downloads.json')"
        url="$(jq -r --arg ch "$channel" --arg p "$plat" '.channels[$ch].downloads.chrome[] | select(.platform==$p) | .url' <<<"$meta")"
        [[ -n "$url" && "$url" != "null" ]] || { echo "Could not resolve Chrome for Testing download URL" >&2; exit 1; }
        rm -rf "$cft_dir"; mkdir -p "$cft_dir"
        curl -fsSL -o "$cft_dir/cft.zip" "$url"
        unzip -qq -o "$cft_dir/cft.zip" -d "$cft_dir"
        rm -f "$cft_dir/cft.zip"
        xattr -dr com.apple.quarantine "$cft_dir" 2>/dev/null || true
    fi
fi

# Download + unpack the extension once into a template that each browser copies.
staging="$(mktemp -d "/tmp/pk-staging-XXXXXXXX")"
trap 'rm -rf "$staging"' EXIT
template="$staging/extension"
mkdir -p "$template"

chrome_version="$("$chrome_bin" --version 2>/dev/null | grep -oE '[0-9]+(\.[0-9]+)+' | head -1)"
crx="$staging/ext.crx"
echo "Downloading extension ${ext_id}"
curl -fsSL -o "$crx" \
    "https://clients2.google.com/service/update2/crx?response=redirect&prodversion=${chrome_version:-9999}&acceptformat=crx2,crx3&x=id%3D${ext_id}%26installsource%3Dondemand%26uc"

# A CRX3 is "Cr24" | version(4) | headerLen(4) | header | ZIP — strip the header, then it's a ZIP.
if [[ "$(head -c4 "$crx")" == "Cr24" ]]; then
    header_len="$(od -An -tu4 -j8 -N4 "$crx" | tr -d ' ')"
    tail -c "+$(( 12 + header_len + 1 ))" "$crx" > "$staging/ext.zip"
else
    cp "$crx" "$staging/ext.zip"
fi
unzip -qq -o "$staging/ext.zip" -d "$template"
rm -rf "$template/_metadata"           # Web Store signing metadata is irrelevant for an unpacked load

# Inject a background service worker that preselects the operation mode and inline
# popup, plus the fixed key. onInstalled always fires on the fresh profile; the
# get/set fallback closes the first-load race without clobbering a manual change.
write_seed() {
    local ext="$1" mode="$2"
    cat > "$ext/pk-seed.js" <<EOF
const PK_CONFIG = { interceptorMode: "${mode}", extensionEnabled: true, popupMode: "inline" };
chrome.runtime.onInstalled.addListener(() => chrome.storage.local.set(PK_CONFIG));
chrome.storage.local.get("interceptorMode", ({ interceptorMode }) => {
    if (interceptorMode === undefined) chrome.storage.local.set(PK_CONFIG);
});
EOF
    jq --arg k "$ext_key" '.background = {service_worker: "pk-seed.js"} | .key = $k' "$ext/manifest.json" > "$ext/manifest.tmp"
    mv "$ext/manifest.tmp" "$ext/manifest.json"
}

# Emit an unpacked theme extension; loaded alongside the interceptor it tints the
# window. Soft, muted tones in the spirit of Chrome's default profile swatches.
write_theme() {
    local dir="$1" color="$2"
    local frame frame_inactive toolbar text bg
    if [[ "$color" == "red" ]]; then
        # red — soft muted rose
        frame="[231, 178, 184]"; frame_inactive="[223, 197, 200]"; toolbar="[242, 214, 218]"
        text="[74, 40, 46]";     bg="[242, 214, 218]"
    else
        # yellow — soft muted citrus
        frame="[240, 223, 150]"; frame_inactive="[231, 223, 185]"; toolbar="[247, 238, 192]"
        text="[72, 62, 16]";     bg="[247, 238, 192]"
    fi
    cat > "$dir/manifest.json" <<EOF
{
    "manifest_version": 3,
    "name": "PK ${color} tint",
    "version": "1.0",
    "theme": {
        "colors": {
            "frame": ${frame},
            "frame_inactive": ${frame_inactive},
            "toolbar": ${toolbar},
            "tab_text": ${text},
            "tab_background_text": ${text},
            "bookmark_text": ${text},
            "ntp_background": ${bg},
            "ntp_text": ${text}
        }
    }
}
EOF
}

# Write a small Node CDP helper that sets the remote-storage config straight into
# the page's localStorage — reliable, and idempotent: an existing remote config is
# left untouched. (Driving the settings UI proved flaky: the page ignores
# isolated-world clicks and its remote client warms up seconds after load.)
write_cdp_helper() {
    cat > "$1/cdp-setstorage.js" <<'CDPEOF'
const fs = require('fs');
const [, , profileDir, secret, backend] = process.argv;
const sleep = ms => new Promise(r => setTimeout(r, ms));

// Chrome writes the chosen DevTools port here when launched with --remote-debugging-port=0.
async function readPort() {
    for (let i = 0; i < 200; i++) {
        try { const p = fs.readFileSync(profileDir + '/DevToolsActivePort', 'utf8').split('\n')[0].trim(); if (p) return p; } catch (e) {}
        await sleep(150);
    }
    throw new Error('no DevToolsActivePort');
}
async function findPage(port) {
    for (let i = 0; i < 200; i++) {
        try {
            const pages = await (await fetch('http://127.0.0.1:' + port + '/json')).json();
            const pg = pages.find(x => x.type === 'page' && /passkeys/i.test(x.url) && x.webSocketDebuggerUrl);
            if (pg) return pg;
        } catch (e) {}
        await sleep(150);
    }
    throw new Error('no page target');
}
// One Runtime.evaluate round-trip over the page's DevTools WebSocket.
function evaluate(wsUrl, expr, timeoutMs) {
    return new Promise((resolve, reject) => {
        const ws = new WebSocket(wsUrl);
        const timer = setTimeout(() => { ws.close(); reject(new Error('cdp timeout')); }, timeoutMs || 20000);
        ws.onopen = () => ws.send(JSON.stringify({ id: 1, method: 'Runtime.evaluate', params: { expression: expr, awaitPromise: true, returnByValue: true } }));
        ws.onmessage = ({ data }) => {
            const msg = JSON.parse(data);
            if (msg.id === 1) { clearTimeout(timer); ws.close(); resolve(msg); }
        };
        ws.onerror = () => { clearTimeout(timer); reject(new Error('cdp connection failed')); };
    });
}
(async () => {
    try {
        const port = await readPort();
        const page = await findPage(port);
        const ws = page.webSocketDebuggerUrl;
        const cfg = JSON.stringify({ mode: 'remote', url: backend, secret: secret, e2ee: true });
        // Idempotent: skip if remote storage is already configured; otherwise set it.
        // Chrome reports the target URL before the document commits its origin, so
        // localStorage access is briefly denied ("wait") — retry until it succeeds.
        const setExpr = '(function(){try{var c=JSON.parse(localStorage.getItem("storageConfig")||"null");if(c&&c.mode==="remote"&&c.secret){return "skip";}localStorage.setItem("storageConfig",' + JSON.stringify(cfg) + ');return "set";}catch(e){return "wait";}})()';
        let outcome = 'wait';
        for (let i = 0; i < 60 && outcome === 'wait'; i++) {
            try { const m = await evaluate(ws, setExpr, 5000); outcome = (m && m.result && m.result.result && m.result.result.value) || 'wait'; } catch (e) {}
            if (outcome === 'wait') await sleep(400);
        }
        // Reload so the app re-reads the config. The reload tears down the context,
        // so the response is lost — cap the wait; the value is already persisted.
        if (outcome === 'set') { try { await evaluate(ws, 'location.reload()', 2500); } catch (e) {} }
    } catch (e) { /* best-effort; leave the browser usable regardless */ }
})();
CDPEOF
}

# Build an isolated ephemeral instance (random profile + own extension copy),
# launch it detached, and wipe the instance dir when that browser closes.
launch_instance() {
    local role="$1" mode="$2" tint="$3" pos="$4" size="$5" secret="${6:-}"
    local inst; inst="$(mktemp -d "/tmp/pk-${role}-XXXXXXXX")"   # fresh, random profile name every run
    mkdir -p "$inst/profile/Default" "$inst/extension"
    cp -R "$template/." "$inst/extension/"
    write_seed "$inst/extension" "$mode"

    # When a shared secret is given (the dual setup only), preconfigure remote
    # storage via CDP (below) and land on the settings page for confirmation.
    # Single attacker/victim/default keep local storage and the normal page.
    local url="$start_url"
    if [[ -n "$secret" ]]; then
        write_cdp_helper "$inst"
        url="${frontend_url%/}/settings"
    fi

    # Pre-seed profile prefs: pin the extension icon to the toolbar, turn off the
    # "offer to translate" prompt (so English pages are never offered German), and
    # always show the full URL in the address bar (no scheme/www elision).
    cat > "$inst/profile/Default/Preferences" <<EOF
{
    "extensions": { "pinned_extensions": ["${ext_pin_id}"] },
    "translate": { "enabled": false },
    "omnibox": { "prevent_url_elisions": true }
}
EOF

    local load="$inst/extension"
    if [[ -n "$tint" ]]; then
        mkdir -p "$inst/theme"
        write_theme "$inst/theme" "$tint"
        load="$inst/extension,$inst/theme"
    fi

    # --use-mock-keychain + --password-store=basic give Chrome a working mock
    # encryption key instead of the macOS Keychain, so there is no keychain prompt
    # and no "restart to keep data encrypted" infobar. When a secret is set, a
    # DevTools port (0 = auto) lets the CDP helper write the storage config.
    nohup bash -c '
        chrome="$1"; profile="$2"; load="$3"; url="$4"; inst="$5"; pos="$6"; size="$7"; secret="$8"; backend="$9"
        dbg=""; [ -n "$secret" ] && dbg="--remote-debugging-port=0"
        "$chrome" \
            --user-data-dir="$profile" \
            --disable-extensions-except="$load" \
            --load-extension="$load" \
            --use-mock-keychain --password-store=basic $dbg \
            --no-first-run --no-default-browser-check \
            --new-window --window-position="$pos" --window-size="$size" \
            "$url" >/dev/null 2>&1 &
        cpid=$!
        [ -n "$secret" ] && node "$inst/cdp-setstorage.js" "$profile" "$secret" "$backend" >/dev/null 2>&1
        wait "$cpid"
        rm -rf "$inst"
    ' _ "$chrome_bin" "$inst/profile" "$load" "$url" "$inst" "$pos" "$size" "$secret" "$storage_backend" >/dev/null 2>&1 &
    disown
    echo "launched ${role} → $(basename "$inst")"
}

case "$setup" in
    attacker) launch_instance attacker profile1 red    "60,80"  "1200,900" ;;
    victim)   launch_instance victim   profile2 yellow "60,80"  "1200,900" ;;
    default)  launch_instance default  default  ""     "60,80"  "1200,900" ;;
    dual)
        launch_instance attacker profile1 red    "40,60"   "940,900" "$storage_secret"
        launch_instance victim   profile2 yellow "1000,60" "940,900" "$storage_secret"
        ;;
    *) echo "Unknown setup '$setup' (use attacker|victim|default|dual)" >&2; exit 1 ;;
esac

case "$setup" in
    dual) echo "remote storage secret: ${storage_secret}" ;;
esac

echo "✅ ${setup} ready — ephemeral profile(s), wiped on close."
