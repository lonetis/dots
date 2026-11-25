# Display helpers for the OmniWM scripts that move windows and workspaces between displays
# or follow the pointer. Source it after lib.sh, don't run it.
#
# OmniWM moves a workspace only to an adjacent monitor, so these helpers find a route over
# the monitor grid (displays.jq) and hop along it.

display_jq=$(<"${BASH_SOURCE[0]%/*}/displays.jq")

# --- routing ---------------------------------------------------------------------

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
