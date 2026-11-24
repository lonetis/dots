# Helpers shared by the OmniWM scripts that Karabiner runs. Source it, don't run it.
#
# Karabiner calls omniwmctl directly for single commands and these scripts for anything
# that needs state. Workspaces are addressed by their key (a-z, ä, ö, ü, 0-9), which
# OmniWM shows as the upper-case display name of a numbered workspace.

apps_json="${OMNIWM_APPS_JSON:-$HOME/.config/karabiner-config/src/apps.json}"  # workspace key -> bundle id or list of bundle ids
settings_toml="${OMNIWM_SETTINGS:-$HOME/.config/omniwm/settings.toml}"         # OmniWM settings, read for the routing grid
state_dir="${OMNIWM_HELPER_STATE_DIR:-$HOME/.local/state/omniwm-helper}"       # short-lived pull state
fallback_key="${OMNIWM_FALLBACK_WORKSPACE:-q}"                                 # workspace for apps missing from apps.json
pull_restore_seconds="${OMNIWM_PULL_RESTORE_SECONDS:-5}"                       # a repeated pull within this time sends the last pulled window back

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
  query windows "$@" --fields id,window-id,app,workspace,display,is-focused,is-scratchpad | jq -c '.windows'
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

# Prints the workspace key apps.json maps the bundle id $1 to, or the fallback key.
default_key() {
  jq -r --arg bundle_id "$1" --arg fallback "$fallback_key" \
    'first(to_entries[] | select([.value] | flatten | any(. == $bundle_id)) | .key) // $fallback' "$apps_json" \
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

# --- displays and routing --------------------------------------------------------

# jq definitions that work on the JSON list of displays. Frames use AppKit coordinates:
# the origin is the bottom-left corner of the main display and y grows upwards.
display_jq='
def center: [.frame.x + .frame.width / 2, .frame.y + .frame.height / 2];

def by_id($id): first(.[] | select(.id == $id));

# Grid cell [column, row] per display id, chosen the way OmniWM picks a saved
# arrangement, or null when routing follows the macOS arrangement.
def grid($routing):
  . as $displays
  | if $routing.mode != "custom" then null
    else
      [ $routing.arrangements[] as $rows
        | [ $displays[] as $display
            | ( first($rows[] | select(.monitorDisplayUUID == $display.uuid))
                // first($rows[] | select(.monitorDisplayUUID == null and .monitorName == $display.name))
                // null ) as $row
            | if $row == null then null else {key: $display.id, value: [$row.gridColumn, $row.gridRow]} end ]
        | select(all(. != null))
        | from_entries
        | select(length == ($displays | length) and ([.[]] | unique | length) == length)
        | {rank: [($rows | length) != ($displays | length), ($rows | length)], cells: .} ]
      | if length == 0 then null else min_by(.rank).cells end
    end;

# The display OmniWM moves to from $origin in $direction (no wrap-around), or null.
def neighbor($origin; $direction; $grid):
  map(select(.id != $origin.id))
  | if $grid != null then
      $grid[$origin.id] as [$col, $row]
      | map(. as $display
          | $grid[.id] as [$c, $r]
          | ( if ($direction == "left" or $direction == "right") and $r == $row then
                (if $direction == "right" then $c - $col else $col - $c end)
              elif ($direction == "up" or $direction == "down") and $c == $col then
                (if $direction == "up" then $row - $r else $r - $row end)
              else null end ) as $offset
          | select($offset != null and $offset > 0)
          | {rank: $offset, display: $display})
    else
      ($origin | center) as [$ox, $oy]
      | map(. as $display
          | center as [$x, $y]
          | ($x - $ox) as $dx | ($y - $oy) as $dy
          | ($dx | fabs) as $adx | ($dy | fabs) as $ady
          | ( if (($direction == "left" and $dx < 0) or ($direction == "right" and $dx > 0)) and $adx >= $ady then
                [$adx, $ady, $dx * $dx + $dy * $dy]
              elif (($direction == "up" and $dy > 0) or ($direction == "down" and $dy < 0)) and $ady >= $adx then
                [$ady, $adx, $dx * $dx + $dy * $dy]
              else null end ) as $rank
          | select($rank != null)
          | {rank: $rank, display: $display})
    end
  | if length == 0 then null else min_by(.rank).display end;

# Directions that lead from $source to $target, one per adjacent-monitor hop, or null.
def route($source; $target; $grid):
  . as $displays
  | def step:
      if (.queue | length) == 0 then null
      else
        .queue[0] as $id
        | .queue |= .[1:]
        | if $id == $target.id then .paths[$id]
          else
            ($displays | by_id($id)) as $display
            | reduce ("left", "right", "up", "down") as $direction (.;
                ($displays | neighbor($display; $direction; $grid)) as $next
                | if $next != null and .paths[$next.id] == null then
                    .paths[$next.id] = .paths[$id] + [$direction] | .queue += [$next.id]
                  else . end)
            | step
          end
      end;
    {queue: [$source.id], paths: {($source.id): []}} | step;

# The display $step places after the one with id $origin_id, wrapping around. Next and
# previous go along the grid rows, or from left to right without a grid.
def cycle_display($origin_id; $step; $grid):
  ( if $grid != null then sort_by([$grid[.id][1], $grid[.id][0]])
    else sort_by(center | [.[0], -.[1]]) end ) as $ordered
  | ($ordered | length) as $count
  | ($ordered | map(.id) | index($origin_id)) as $index
  | $ordered[(($index + $step) % $count + $count) % $count];
'

# Prints the [routing] mode and saved arrangements of settings.toml as JSON. OmniWM
# writes the file in canonical form (one key per line, a header per table), which is
# all this parser has to handle.
routing() {
  [[ -r $settings_toml ]] || die "cannot read $settings_toml"
  awk '
    function value() { v = $0; sub(/^[^=]*= /, "", v); return v }
    function close_monitor() {
      if (monitor != "") arrangements[count] = arrangements[count] (arrangements[count] == "" ? "" : ",") "{" monitor "}"
      monitor = ""
    }
    /^\[/ {
      close_monitor()
      section = $0
      if (section == "[[routing.arrangements]]") arrangements[++count] = ""
      next
    }
    section == "[routing]" && $1 == "mode" { mode = value() }
    section == "[[routing.arrangements.monitors]]" && $1 ~ /^(gridColumn|gridRow|monitorDisplayUUID|monitorName)$/ {
      monitor = monitor (monitor == "" ? "" : ",") "\"" $1 "\":" value()
    }
    END {
      close_monitor()
      printf "{\"mode\":%s,\"arrangements\":[", (mode == "" ? "null" : mode)
      for (i = 1; i <= count; i++) printf "%s[%s]", (i > 1 ? "," : ""), arrangements[i]
      print "]}"
    }
  ' "$settings_toml" | jq -c . || die "cannot read [routing] from $settings_toml"
}

# Prints the routing grid (null without one) for the JSON list of displays $1.
display_grid() {
  local routing
  routing=$(routing)
  jq -c --argjson routing "$routing" "$display_jq"' grid($routing)' <<<"$1"
}

# Prints the display $2 steps after the display with id $1, wrapping around; $3 is the
# JSON list of displays.
cycle_display() {
  local grid
  grid=$(display_grid "$3")
  jq -c --arg id "$1" --argjson step "$2" --argjson grid "$grid" "$display_jq"' cycle_display($id; $step; $grid)' <<<"$3"
}

# Prints 1 for next and -1 for prev.
parse_step() {
  case ${1-} in
    next) echo 1 ;;
    prev) echo -1 ;;
    *) die "usage: ${0##*/} next|prev" ;;
  esac
}

# Prints a JSON object that maps each display id in the JSON list $1 to the raw name of
# the workspace it shows.
visible_plan() {
  jq -c 'map({key: .id, value: .activeWorkspace.rawName}) | from_entries' <<<"$1"
}

# Moves the workspace $1 to the display $2; $3 is the JSON list of displays. OmniWM moves
# a workspace only to an adjacent monitor, so this hops along the route.
move_workspace() {
  local workspace=$1 target=$2 all_displays=$3 grid route raw_name directions direction
  grid=$(display_grid "$all_displays")
  route=$(jq -c --argjson workspace "$workspace" --argjson target "$target" --argjson grid "$grid" \
    "$display_jq"' route(by_id($workspace.display.id); $target; $grid)' <<<"$all_displays")
  [[ $route != null ]] || die "no monitor route to $(jq -r .name <<<"$target")"
  raw_name=$(jq -r .rawName <<<"$workspace")
  directions=$(jq -r '.[]' <<<"$route")
  for direction in $directions; do
    ctl workspace move-to-monitor "$raw_name" "$direction" --force >/dev/null
  done
}

# Makes each display in the plan $1 (display id -> raw workspace name) show its
# workspace, then focuses the display with id $2. Moving a workspace across several
# monitors changes what the monitors in between show, so every caller passes the full
# picture it wants to end up with.
show() {
  local plan=$1 focus_display_id=$2 current_displays active switches workspace focus_workspace
  current_displays=$(displays)
  active=$(visible_plan "$current_displays")
  switches=$(jq -r --argjson active "$active" --arg focus "$focus_display_id" \
    'to_entries[] | select(.key != $focus and $active[.key] != .value) | .value' <<<"$plan")
  for workspace in $switches; do
    ctl command switch-workspace "$workspace" >/dev/null
  done
  focus_workspace=$(jq -r --arg focus "$focus_display_id" '.[$focus]' <<<"$plan")
  ctl command switch-workspace "$focus_workspace" >/dev/null
}

# Moves the workspace $1 to the display $2 steps further (wrapping around), focuses it
# there and prints that display; $3 is the JSON list of displays.
move_to_next_display() {
  local workspace=$1 step=$2 all_displays=$3 source_id target target_id raw_name plan
  source_id=$(jq -r .display.id <<<"$workspace")
  target=$(cycle_display "$source_id" "$step" "$all_displays")
  target_id=$(jq -r .id <<<"$target")
  [[ $target_id != "$source_id" ]] || die "only one display connected"
  raw_name=$(jq -r .rawName <<<"$workspace")
  plan=$(visible_plan "$all_displays")
  move_workspace "$workspace" "$target" "$all_displays"
  # The source display picks another workspace by itself.
  plan=$(jq -c --arg source "$source_id" --arg target "$target_id" --arg workspace "$raw_name" \
    'del(.[$source]) | .[$target] = $workspace' <<<"$plan")
  show "$plan" "$target_id"
  printf '%s\n' "$target"
}

# --- pointer (osascript, because CoreGraphics has no command-line interface) -----

# Prints the display under the pointer, or the current one, from the JSON list of displays $1.
display_under_pointer() {
  local location x y display
  # NSEvent reports AppKit coordinates, the same as OmniWM's frames.
  location=$(osascript -l JavaScript -e 'ObjC.import("AppKit"); const p = $.NSEvent.mouseLocation; `${p.x} ${p.y}`')
  read -r x y <<<"$location"
  display=$(jq -c --argjson x "$x" --argjson y "$y" '
    first(.[] | select(.frame.x <= $x and $x < .frame.x + .frame.width and .frame.y <= $y and $y < .frame.y + .frame.height))
    // first(.[] | select(.isCurrent)) // empty' <<<"$1")
  [[ -n $display ]] || die "no display under the pointer and no current display"
  printf '%s\n' "$display"
}

# Moves the pointer to the centre of the display $1; $2 is the JSON list of displays.
warp_pointer_to() {
  local point error
  # CoreGraphics counts y from the top of the main display.
  point=$(jq -r --argjson display "$1" "$display_jq"'
    first(.[] | select(.isMain)).frame.height as $main_height
    | ($display | center) as [$x, $y]
    | "\($x) \($main_height - $y)"' <<<"$2")
  # Without re-associating the mouse, macOS ignores pointer movement for a moment after the warp.
  # shellcheck disable=SC2086 # $point is "x y"
  error=$(osascript -l JavaScript -e '
    ObjC.import("CoreGraphics")
    function run([x, y]) {
      const error = $.CGWarpMouseCursorPosition({x: Number(x), y: Number(y)})
      $.CGAssociateMouseAndMouseCursorPosition(true)
      return error
    }' $point)
  [[ $error == 0 ]] || die "cannot move the pointer to $(jq -r .name <<<"$1") (CGError $error)"
}
