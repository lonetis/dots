# Helpers shared by the OmniWM scripts that Karabiner runs. Source it, don't run it;
# scripts that work across displays source displays.sh after it.
#
# Karabiner calls omniwmctl directly for single commands and these scripts for anything
# that needs state. Workspaces are addressed by their key (a-z, ä, ö, ü, 0-9), which
# OmniWM shows as the upper-case display name of a numbered workspace. Every setting is an
# OMNIWM_* environment variable with its default below.

apps_json="${OMNIWM_APPS_JSON:-$HOME/.config/karabiner-config/src/apps.json}"  # apps with their workspace key and Karabiner key
settings_toml="${OMNIWM_SETTINGS:-$HOME/.config/omniwm/settings.toml}"         # OmniWM settings, read for the routing grid
state_dir="${OMNIWM_HELPER_STATE_DIR:-$HOME/.local/state/omniwm-helper}"       # short-lived pull state
fallback_key="${OMNIWM_FALLBACK_WORKSPACE:-q}"                                 # workspace for apps missing from apps.json
pull_restore_seconds="${OMNIWM_PULL_RESTORE_SECONDS:-5}"                       # a repeated pull within this time sends the last pulled window back
warp_pointer="${OMNIWM_WARP_POINTER:-false}"                                   # true: move-workspace.sh moves the pointer along to the workspace's new display

shopt -s inherit_errexit

die() {
  printf '%s: %s\n' "${0##*/}" "$*" >&2
  exit 1
}

# --- omniwmctl -------------------------------------------------------------------

# Runs omniwmctl with JSON output and prints the response. A request that changes
# nothing (e.g. moving a window to its own workspace) is fine; `--ok <code>` before the
# arguments accepts further error codes.
ctl() {
  local ok_codes=(no_change) response code status=0
  while [[ ${1-} == --ok ]]; do
    ok_codes+=("$2")
    shift 2
  done
  response=$(omniwmctl "$@" --format json) || status=$?
  if ((status != 0)); then
    code=$(jq -r '.code // empty' <<<"$response" 2>/dev/null) || code=
    [[ -n $code && " ${ok_codes[*]} " == *" $code "* ]] || die "omniwmctl $*: ${code:-exit $status}"
  fi
  printf '%s\n' "$response"
}

query() {
  ctl query "$@" | jq -c '.result.payload'
}

displays() {
  query displays --fields id,name,uuid,is-main,is-current,frame,active-workspace | jq -c '.displays'
}

workspaces() {
  query workspaces --fields id,raw-name,display-name,number,display,is-visible,is-current | jq -c '.workspaces'
}

windows() {
  query windows "$@" --fields id,window-id,app,workspace,display,is-focused,is-scratchpad,focus-rank | jq -c '.windows'
}

# Prints the JSON list of windows of the apps with the given bundle IDs.
app_windows() {
  local all_windows
  all_windows=$(windows)
  jq -c 'map(select(.app.bundleId | IN($ARGS.positional[])))' --args "$@" <<<"$all_windows"
}

# Prints nothing when no managed window has focus.
focused_window() {
  ctl --ok not_found --ok no_focused_window query focused-window | jq -c '.result.payload.window // empty'
}

require_focused_window() {
  local window
  window=$(focused_window)
  [[ -n $window ]] || die "no focused managed window"
  printf '%s\n' "$window"
}

# --- workspaces and apps ---------------------------------------------------------

# Prints the workspace with key $1 from the JSON list of workspaces $2.
workspace_for_key() {
  local label=${1^^} workspace
  workspace=$(jq -c --arg label "$label" 'first(.[] | select((.displayName // .rawName) == $label)) // empty' <<<"$2")
  [[ -n $workspace ]] || die "no workspace with display name '$label'; run the Karabiner build to regenerate them"
  printf '%s\n' "$workspace"
}

# Prints the current workspace from the JSON list of workspaces $1.
current_workspace() {
  local workspace
  workspace=$(jq -c 'first(.[] | select(.isCurrent)) // empty' <<<"$1")
  [[ -n $workspace ]] || die "no current workspace"
  printf '%s\n' "$workspace"
}

# Prints the workspace key apps.json assigns the bundle id $1 to, or the fallback key.
default_key() {
  jq -r --arg bundle_id "$1" --arg fallback "$fallback_key" \
    'first(.[] | select(.bundleId == $bundle_id) | .workspace) // $fallback' "$apps_json" \
    || die "cannot read $apps_json"
}

quit_app() {
  osascript -e "tell application id \"$1\" to quit" >/dev/null
}

# Reads --quit-if-last-window, the only option of the close scripts, and prints true or false.
parse_quit_option() {
  case $* in
    "") echo false ;;
    --quit-if-last-window) echo true ;;
    *) die "usage: ${0##*/} [--quit-if-last-window]" ;;
  esac
}
