#!/usr/bin/env bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Burp Chrome
# @raycast.mode fullOutput

# Optional parameters:
# @raycast.icon icons/burp.svg
# @raycast.packageName me.louisjannett.raycast.burp-chrome

# Documentation:
# @raycast.description Launch a real Google Chrome (Stable/Canary/Dev/Beta) pre-wired for Burp Suite — routes through Burp's proxy, trusts Burp's CA, and opens Burp. Uses your existing Chrome profiles by default, or an isolated fresh/persistent one.
# @raycast.author Louis Jannett

# @raycast.argument1 { "type": "dropdown", "placeholder": "Browser", "data": [ { "title": "Google Chrome", "value": "chrome" }, { "title": "Chrome Canary", "value": "canary" }, { "title": "Chrome Dev", "value": "dev" }, { "title": "Chrome Beta", "value": "beta" } ], "optional": false }
# @raycast.argument2 { "type": "dropdown", "placeholder": "Profile", "data": [ { "title": "My existing profiles (normal Chrome data)", "value": "existing" }, { "title": "Fresh profile (/tmp, wiped on close)", "value": "fresh" }, { "title": "Persistent profile (reused)", "value": "persistent" } ], "optional": false }

set -euo pipefail

channel="$1"
profile_mode="$2"

# ── Configuration (environment only) ────────────────────────────────────────
burp_app="${BURP_APP:-Burp Suite}"                       # Burp app name or path for `open -a`
proxy="${BURP_PROXY:-127.0.0.1:8080}"                    # Burp proxy listener (host:port)
trust="${BURP_CHROME_TRUST:-spki}"                       # how Chrome trusts Burp's CA: spki (this Chrome only) | keychain (modifies the OS) | none
fallback="${BURP_CHROME_FALLBACK:-blanket}"              # if the exact CA isn't available yet: blanket (this Chrome ignores all cert errors) | none (open with no bypass)
start_url="${BURP_CHROME_URL:-http://burp}"              # first tab; http://burp confirms interception works
wait_secs="${BURP_CHROME_WAIT:-8}"                       # seconds to wait for Burp's proxy /cert before opening Chrome anyway (cache makes repeat runs instant)
proxy_localhost="${BURP_PROXY_LOCALHOST:-1}"             # 1 = also send loopback traffic through Burp (like Burp's browser)
win_pos="${BURP_CHROME_WINDOW_POS:-80,80}"              # Chrome --window-position
win_size="${BURP_CHROME_WINDOW_SIZE:-1280,900}"        # Chrome --window-size
keychain="${BURP_KEYCHAIN:-$HOME/Library/Keychains/login.keychain-db}"  # keychain to trust the CA in
ca_cache="${BURP_CA_CACHE:-$HOME/.cache/burp-chrome/cacert.pem}"        # cached Burp CA (PEM), reused across runs
ca_file="${BURP_CA_FILE:-}"                              # optional: use this CA PEM/DER instead of fetching
refresh="${BURP_CA_REFRESH:-0}"                          # 1 = re-fetch the CA even if cached
profile_root="${BURP_CHROME_PROFILE_ROOT:-$HOME/.config/raycast-scripts/burp-chrome-profiles}"  # persistent profiles live here
chrome_app_override="${BURP_CHROME_APP:-}"               # optional: open this .app bundle instead of the channel default

# ── Preconditions ───────────────────────────────────────────────────────────
for cmd in curl openssl mktemp open pgrep; do
    command -v "$cmd" >/dev/null 2>&1 || { echo "Missing required command: $cmd" >&2; exit 1; }
done

case "$trust" in keychain|spki|none) ;; *) echo "BURP_CHROME_TRUST must be keychain|spki|none (got '$trust')" >&2; exit 1 ;; esac
case "$fallback" in blanket|none) ;; *) echo "BURP_CHROME_FALLBACK must be blanket|none (got '$fallback')" >&2; exit 1 ;; esac

# Accept BURP_PROXY as host:port; tolerate an accidental scheme prefix.
proxy="${proxy#http://}"; proxy="${proxy#https://}"; proxy="${proxy%/}"

# Resolve the Chrome app bundle for the chosen channel. Google ships each channel
# as a separate .app.
declare -A app_name=(
    [chrome]="Google Chrome"
    [canary]="Google Chrome Canary"
    [dev]="Google Chrome Dev"
    [beta]="Google Chrome Beta"
)
name="${app_name[$channel]:-}"
[[ -n "$name" ]] || { echo "Unknown browser '$channel' (use chrome|canary|dev|beta)" >&2; exit 1; }

chrome_app="${chrome_app_override:-/Applications/$name.app}"
[[ -d "$chrome_app" ]] || { echo "$name not found: $chrome_app" >&2; exit 1; }

# ── Profile directory ───────────────────────────────────────────────────────
# existing: no --user-data-dir, so Chrome uses its normal profile store and your
# existing profiles are available. fresh: a random /tmp dir, wiped when the browser
# closes. persistent: a stable per-channel dir so cookies/logins survive between runs.
wipe_profile=0
isolated=1                 # 1 = launch with our own --user-data-dir; 0 = use the channel's normal profiles
case "$profile_mode" in
    existing)
        profile=""
        isolated=0
        # The proxy + CA flags only take effect when Chrome starts fresh with this data
        # dir. If the channel is already running, macOS would hand the launch to it and
        # drop our flags — so refuse up front, before opening Burp or a window, rather
        # than spawning an un-proxied window. SingletonLock is a symlink to
        # "<host>-<pid>"; verify that pid is alive so a stale lock (after a crash) doesn't
        # block us.
        lock="$HOME/Library/Application Support/Google/${name#Google }/SingletonLock"
        if [[ -L "$lock" ]]; then
            lock_pid="$(readlink "$lock")"; lock_pid="${lock_pid##*-}"
            if [[ "$lock_pid" =~ ^[0-9]+$ ]] && kill -0 "$lock_pid" 2>/dev/null; then
                echo "$name is already running — its profile is locked, so this launch can't apply the" >&2
                echo "Burp proxy + CA flags (macOS would just open a window in the running $name)." >&2
                echo "Quit $name first, or choose a Fresh/Persistent profile, or a channel you don't have open." >&2
                exit 1
            fi
        fi
        ;;
    fresh)
        profile="$(mktemp -d "/tmp/burp-chrome-${channel}-XXXXXXXX")"
        wipe_profile=1
        ;;
    persistent)
        profile="$profile_root/$channel"
        mkdir -p "$profile"
        ;;
    *) echo "Unknown profile mode '$profile_mode' (use existing|fresh|persistent)" >&2; exit 1 ;;
esac

# ── Open Burp ───────────────────────────────────────────────────────────────
# Launch (or focus) Burp first so its proxy is coming up while we fetch the CA.
echo "Opening Burp Suite ($burp_app)…"
open -a "$burp_app" || { echo "Could not open '$burp_app' — set BURP_APP to its name or path." >&2; exit 1; }

# ── Obtain Burp's CA (best-effort — never blocks the browser from opening) ────
# Burp serves its per-installation CA at http://burp/cert (DER) through the proxy.
# We normalise it to PEM and cache it so repeat launches are instant and precise.
fetch_cert_to() {
    local out="$1" tmp; tmp="$(mktemp)"
    # Preferred: through the proxy to Burp's magic host. Fallback: straight at the listener.
    if curl -fsS --max-time 5 -x "http://$proxy" http://burp/cert -o "$tmp" 2>/dev/null \
        || curl -fsS --max-time 5 "http://$proxy/cert" -o "$tmp" 2>/dev/null; then
        # Burp returns DER; accept PEM too in case a listener is configured oddly.
        if openssl x509 -inform DER -in "$tmp" -out "$out" 2>/dev/null \
            || openssl x509 -inform PEM -in "$tmp" -out "$out" 2>/dev/null; then
            rm -f "$tmp"; return 0
        fi
    fi
    rm -f "$tmp"; return 1
}

# Keep polling for the CA after we've already opened Chrome, so the NEXT launch can
# pin the exact CA even if Burp's proxy wasn't ready in time for this one.
warm_cache_bg() {
    nohup bash -c '
        cache="$1"; proxy="$2"; secs="$3"; end=$(( SECONDS + secs ))
        while (( SECONDS < end )); do
            tmp="$(mktemp)"
            if curl -fsS --max-time 5 -x "http://$proxy" http://burp/cert -o "$tmp" 2>/dev/null \
                || curl -fsS --max-time 5 "http://$proxy/cert" -o "$tmp" 2>/dev/null; then
                if openssl x509 -inform DER -in "$tmp" -out "$cache" 2>/dev/null \
                    || openssl x509 -inform PEM -in "$tmp" -out "$cache" 2>/dev/null; then
                    rm -f "$tmp"; exit 0
                fi
            fi
            rm -f "$tmp"; sleep 3
        done
    ' _ "$1" "$2" "$3" >/dev/null 2>&1 &
    disown
}

ca_pem=""
if [[ "$trust" != "none" ]]; then
    if [[ -n "$ca_file" ]]; then
        # Explicit override — accept PEM or DER.
        ca_pem="$(mktemp)"
        openssl x509 -in "$ca_file" -out "$ca_pem" 2>/dev/null \
            || openssl x509 -inform DER -in "$ca_file" -out "$ca_pem" 2>/dev/null \
            || { echo "BURP_CA_FILE is not a valid certificate: $ca_file" >&2; exit 1; }
        echo "Using CA from BURP_CA_FILE."
    elif [[ "$refresh" != "1" && -s "$ca_cache" ]] && openssl x509 -in "$ca_cache" -noout -checkend 0 >/dev/null 2>&1; then
        ca_pem="$ca_cache"
        echo "Using cached Burp CA: $ca_cache"
    else
        mkdir -p "$(dirname "$ca_cache")"
        echo "Fetching Burp CA from http://$proxy (up to ${wait_secs}s)…"
        deadline=$(( SECONDS + wait_secs ))
        while :; do
            if fetch_cert_to "$ca_cache"; then ca_pem="$ca_cache"; echo "Got Burp CA → $ca_cache"; break; fi
            (( SECONDS >= deadline )) && break
            sleep 2
        done
        # Not fatal: open Chrome now with fallback trust; keep polling for the real CA.
        if [[ -z "$ca_pem" ]]; then
            echo "Burp's proxy didn't answer in ${wait_secs}s — opening Chrome now; caching the exact CA in the background for next time."
            warm_cache_bg "$ca_cache" "$proxy" 180
        fi
    fi
fi

# ── Build Chrome flags, incl. how THIS instance trusts Burp ───────────────────
chrome_args=()
# Own data dir only for isolated (fresh/persistent) profiles; omit it for "existing"
# so Chrome uses your normal profile store.
[[ "$isolated" == "1" ]] && chrome_args+=(--user-data-dir="$profile")
chrome_args+=(
    --proxy-server="http://$proxy"
    --no-first-run --no-default-browser-check
    --new-window
    --window-position="$win_pos" --window-size="$win_size"
)
# Mock keychain + basic password store keep isolated profiles from touching or
# prompting for the macOS keychain. Skip for "existing" so your saved passwords and
# normal keychain behaviour are preserved.
[[ "$isolated" == "1" ]] && chrome_args+=(--use-mock-keychain --password-store=basic)
# "<-loopback>" means "do NOT bypass loopback", i.e. proxy localhost too, so Burp
# can intercept apps running on the machine. Toggle off with BURP_PROXY_LOCALHOST=0.
[[ "$proxy_localhost" == "1" ]] && chrome_args+=(--proxy-bypass-list="<-loopback>")

# Fallback used whenever the exact CA isn't available (Burp not up yet, etc.) so the
# browser still opens and works. blanket = this Chrome ignores all cert errors (still
# keychain-free, still scoped to this one instance); none = open with no bypass.
trust_note=""
apply_fallback() {
    if [[ "$fallback" == "blanket" ]]; then
        chrome_args+=(--ignore-certificate-errors --test-type)
        trust_note="⚠️  exact CA not available yet — this Chrome ignores ALL cert errors (keychain untouched, this instance only). Re-run once Burp's proxy is up to pin only Burp's CA."
    else
        trust_note="⚠️  exact CA not available and fallback disabled — HTTPS will show warnings. Re-run once Burp's proxy is up."
    fi
}

case "$trust" in
    spki)
        # Pin Burp's CA in THIS Chrome instance only. Nothing is written to the macOS
        # keychain — the trust lives and dies with this browser process. Same mechanism
        # Burp's own pre-wired browser uses. --test-type suppresses the warning ribbon.
        spki="$([[ -n "$ca_pem" ]] && openssl x509 -in "$ca_pem" -noout -pubkey | openssl pkey -pubin -outform DER 2>/dev/null | openssl dgst -sha256 -binary | openssl base64)" || spki=""
        if [[ -n "$spki" ]]; then
            chrome_args+=(--ignore-certificate-errors-spki-list="$spki" --test-type)
            trust_note="Burp CA pinned in this Chrome instance only (SPKI) — keychain untouched."
        else
            apply_fallback
        fi
        ;;
    keychain)
        # OPT-IN: the ONLY mode that modifies the OS. macOS Chrome honours user-installed
        # roots from the login keychain (shown in chrome://certificate-manager under
        # local/OS certs). SSL-only; skip if already present. Affects every browser, not
        # just this one. Non-fatal: if it can't be added, fall back so Chrome still opens.
        if [[ -n "$ca_pem" ]]; then
            fp="$(openssl x509 -in "$ca_pem" -noout -fingerprint -sha1 | sed 's/.*=//; s/://g')"
            [[ -f "$keychain" ]] || keychain="login.keychain"
            if security find-certificate -a -Z "$keychain" 2>/dev/null | grep -qi "$fp"; then
                trust_note="Burp CA already trusted in $(basename "$keychain")."
            elif echo "Adding Burp CA to $(basename "$keychain") — authorize the prompt…" \
                 && security add-trusted-cert -r trustRoot -p ssl -k "$keychain" "$ca_pem"; then
                trust_note="Burp CA trusted (SSL) in $(basename "$keychain")."
            else
                echo "Keychain trust failed or was cancelled."
                apply_fallback
            fi
        else
            apply_fallback
        fi
        ;;
    none)
        trust_note="No CA trust (BURP_CHROME_TRUST=none) — expect certificate warnings."
        ;;
esac

# ── Launch Chrome, pre-wired for Burp ───────────────────────────────────────
if [[ "$isolated" == "1" ]]; then echo "Launching $name → profile: $profile"; else echo "Launching $name → your existing $name profiles"; fi
# `open -n` forces a SEPARATE Chrome instance even when Chrome is already running.
# Launching the binary directly (or `open` without -n) would just focus the running
# Chrome and drop our flags. The unique --user-data-dir keeps this instance isolated.
open -na "$chrome_app" --args "${chrome_args[@]}" "$start_url"

if [[ "$wipe_profile" == "1" ]]; then
    # `open` returns immediately, so we can't wait on the browser PID. Instead watch
    # for the instance by its unique data dir and wipe the profile once it closes.
    # Detached so Raycast can return right away.
    nohup bash -c '
        prof="$1"
        for _ in $(seq 1 60); do pgrep -f -- "--user-data-dir=$prof" >/dev/null 2>&1 && break; sleep 0.5; done
        while pgrep -f -- "--user-data-dir=$prof" >/dev/null 2>&1; do sleep 2; done
        rm -rf "$prof"
    ' _ "$profile" >/dev/null 2>&1 &
    disown
fi

echo
echo "✅ $name is wired to Burp on $proxy."
[[ -n "$trust_note" ]] && echo "   $trust_note"
[[ "$wipe_profile" == "1" ]] && echo "   Ephemeral profile — wiped when you close this browser."

# Drop the CA only when it was a throwaway temp (BURP_CA_FILE path); never the cache.
[[ -n "$ca_pem" && "$ca_pem" != "$ca_cache" ]] && rm -f "$ca_pem"

exit 0
