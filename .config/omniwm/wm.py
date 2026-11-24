#!/usr/bin/env python3
"""Window-management actions that Karabiner runs on top of omniwmctl.

OmniWM has no shortcuts of its own (general.hotkeysEnabled = false). Karabiner calls
omniwmctl directly for single commands and this helper for anything that needs state.
Workspaces are addressed by their key (a-z, ä, ö, ü, 0-9), which OmniWM shows as the
upper-case display name of a numbered workspace.
"""

import argparse
import ctypes
import json
import os
import subprocess
import sys
import time
import tomllib
from collections import deque
from pathlib import Path

APPS_JSON = Path(os.environ.get("OMNIWM_APPS_JSON", "~/.config/karabiner-config/src/apps.json")).expanduser()  # workspace key -> bundle id
SETTINGS_TOML = Path(os.environ.get("OMNIWM_SETTINGS", "~/.config/omniwm/settings.toml")).expanduser()  # OmniWM settings, read for the routing grid
STATE_DIR = Path(os.environ.get("OMNIWM_HELPER_STATE_DIR", "~/.local/state/omniwm-helper")).expanduser()  # short-lived pull state
FALLBACK_KEY = os.environ.get("OMNIWM_FALLBACK_WORKSPACE", "q")  # workspace for apps missing from apps.json
PULL_RESTORE_SECONDS = float(os.environ.get("OMNIWM_PULL_RESTORE_SECONDS", "5"))  # a repeated pull within this time sends the last pulled window back

DIRECTIONS = ("left", "right", "up", "down")


class WMError(Exception):
    def __init__(self, message: str, code: str | None = None):
        super().__init__(message)
        self.code = code


# --- omniwmctl -------------------------------------------------------------------


def ctl(*args: str) -> dict:
    result = subprocess.run(["omniwmctl", *args, "--format", "json"], capture_output=True, text=True)
    try:
        response = json.loads(result.stdout) if result.stdout.strip() else {}
    except json.JSONDecodeError:
        response = {}
    # A request that changes nothing (e.g. moving a window to its own workspace) is fine.
    if result.returncode == 0 or response.get("code") == "no_change":
        return response
    code = response.get("code")
    detail = code or result.stderr.strip() or result.stdout.strip() or f"exit {result.returncode}"
    raise WMError(f"omniwmctl {' '.join(args)}: {detail}", code)


def query(name: str, *args: str) -> dict:
    return ctl("query", name, *args)["result"]["payload"]


def displays() -> list[dict]:
    return query("displays", "--fields", "id,name,uuid,is-main,is-current,frame,active-workspace")["displays"]


def workspaces() -> list[dict]:
    return query("workspaces", "--fields", "id,raw-name,display-name,number,display,is-visible,is-current")["workspaces"]


def windows(*selectors: str) -> list[dict]:
    return query("windows", *selectors, "--fields", "id,window-id,app,workspace,display,is-focused,is-scratchpad")["windows"]


def focused_window() -> dict | None:
    try:
        return query("focused-window").get("window")
    except WMError as error:
        if error.code in ("not_found", "no_focused_window"):
            return None
        raise


def require_focused_window() -> dict:
    window = focused_window()
    if window is None:
        raise WMError("no focused managed window")
    return window


# --- workspaces and apps ---------------------------------------------------------


def workspace_for_key(key: str, all_workspaces: list[dict]) -> dict:
    label = key.upper()
    for workspace in all_workspaces:
        if workspace.get("displayName", workspace["rawName"]) == label:
            return workspace
    raise WMError(f"no workspace with display name {label!r}; run the Karabiner build to regenerate them")


def default_key(bundle_id: str | None) -> str:
    try:
        apps = json.loads(APPS_JSON.read_text())
    except (OSError, json.JSONDecodeError) as error:
        raise WMError(f"cannot read {APPS_JSON}: {error}") from error
    return next((key for key, app in apps.items() if app == bundle_id), FALLBACK_KEY)


def raw_name(window: dict) -> str:
    return window["workspace"]["rawName"]


def bundle_id(window: dict) -> str | None:
    return window.get("app", {}).get("bundleId")


def quit_app(app_bundle_id: str) -> None:
    subprocess.run(["osascript", "-e", f'tell application id "{app_bundle_id}" to quit'], check=True, capture_output=True)


# --- displays and routing --------------------------------------------------------


def center(display: dict) -> tuple[float, float]:
    frame = display["frame"]
    return frame["x"] + frame["width"] / 2, frame["y"] + frame["height"] / 2


def routing_grid(all_displays: list[dict]) -> dict[str, tuple[int, int]] | None:
    """Grid cell (column, row) per display id, chosen the way OmniWM picks a saved arrangement."""
    try:
        routing = tomllib.loads(SETTINGS_TOML.read_text()).get("routing", {})
    except (OSError, tomllib.TOMLDecodeError) as error:
        raise WMError(f"cannot read {SETTINGS_TOML}: {error}") from error
    if routing.get("mode") != "custom":
        return None

    candidates = []
    for arrangement in routing.get("arrangements", []):
        rows = arrangement.get("monitors", [])
        cells = {}
        for display in all_displays:
            row = next((r for r in rows if r.get("monitorDisplayUUID") == display.get("uuid")), None) or next(
                (r for r in rows if "monitorDisplayUUID" not in r and r.get("monitorName") == display["name"]), None
            )
            if row is None:
                break
            cells[display["id"]] = (row["gridColumn"], row["gridRow"])
        if len(cells) == len(all_displays) and len(set(cells.values())) == len(cells):
            candidates.append((len(rows) != len(all_displays), len(rows), cells))
    if not candidates:
        return None
    return min(candidates, key=lambda candidate: candidate[:2])[2]


def neighbor(origin: dict, direction: str, all_displays: list[dict], grid: dict | None) -> dict | None:
    """The display OmniWM moves to from `origin` in `direction` (no wrap-around)."""
    others = [display for display in all_displays if display["id"] != origin["id"]]
    if grid is not None:
        col, row = grid[origin["id"]]

        def offset(display: dict) -> int | None:
            other_col, other_row = grid[display["id"]]
            if direction in ("left", "right") and other_row == row:
                return other_col - col if direction == "right" else col - other_col
            if direction in ("up", "down") and other_col == col:
                return row - other_row if direction == "up" else other_row - row
            return None

        ahead = [(offset(display), display) for display in others if (offset(display) or 0) > 0]
        return min(ahead, key=lambda entry: entry[0])[1] if ahead else None

    # macOS arrangement: frame centres in AppKit coordinates, y grows upwards.
    origin_x, origin_y = center(origin)
    candidates = []
    for display in others:
        x, y = center(display)
        dx, dy = x - origin_x, y - origin_y
        horizontal = abs(dx) >= abs(dy)
        vertical = abs(dy) >= abs(dx)
        if (direction == "left" and dx < 0 and horizontal) or (direction == "right" and dx > 0 and horizontal):
            candidates.append(((abs(dx), abs(dy), dx * dx + dy * dy), display))
        elif (direction == "up" and dy > 0 and vertical) or (direction == "down" and dy < 0 and vertical):
            candidates.append(((abs(dy), abs(dx), dx * dx + dy * dy), display))
    return min(candidates, key=lambda entry: entry[0])[1] if candidates else None


def route(source: dict, target: dict, all_displays: list[dict], grid: dict | None) -> list[str]:
    """Directions that lead from `source` to `target`, one per adjacent-monitor hop."""
    paths = {source["id"]: []}
    queue = deque([source])
    while queue:
        display = queue.popleft()
        if display["id"] == target["id"]:
            return paths[display["id"]]
        for direction in DIRECTIONS:
            nxt = neighbor(display, direction, all_displays, grid)
            if nxt is not None and nxt["id"] not in paths:
                paths[nxt["id"]] = paths[display["id"]] + [direction]
                queue.append(nxt)
    raise WMError(f"no monitor route from {source['name']} to {target['name']}")


def ordered_displays(all_displays: list[dict], grid: dict | None) -> list[dict]:
    if grid is not None:
        return sorted(all_displays, key=lambda display: (grid[display["id"]][1], grid[display["id"]][0]))
    return sorted(all_displays, key=lambda display: (center(display)[0], -center(display)[1]))


def cycle_display(origin_id: str, step: int, all_displays: list[dict]) -> dict:
    ordered = ordered_displays(all_displays, routing_grid(all_displays))
    index = next(i for i, display in enumerate(ordered) if display["id"] == origin_id)
    return ordered[(index + step) % len(ordered)]


def display_by_id(display_id: str, all_displays: list[dict]) -> dict:
    return next(display for display in all_displays if display["id"] == display_id)


def move_workspace(workspace: dict, target: dict, all_displays: list[dict]) -> None:
    source = display_by_id(workspace["display"]["id"], all_displays)
    for direction in route(source, target, all_displays, routing_grid(all_displays)):
        ctl("workspace", "move-to-monitor", workspace["rawName"], direction, "--force")


def show(plan: dict[str, str], focus_display_id: str) -> None:
    """Make each display in `plan` show its workspace, then focus `focus_display_id`.

    Moving a workspace across several monitors changes what the monitors in between
    show, so every caller passes the full picture it wants to end up with.
    """
    active = {display["id"]: display["activeWorkspace"]["rawName"] for display in displays()}
    for display_id, workspace in plan.items():
        if display_id != focus_display_id and active.get(display_id) != workspace:
            ctl("command", "switch-workspace", workspace)
    ctl("command", "switch-workspace", plan[focus_display_id])


def visible_plan(all_displays: list[dict]) -> dict[str, str]:
    return {display["id"]: display["activeWorkspace"]["rawName"] for display in all_displays}


# --- pointer (CoreGraphics uses top-left origin coordinates, OmniWM AppKit's bottom-left) ---


class CGPoint(ctypes.Structure):
    _fields_ = [("x", ctypes.c_double), ("y", ctypes.c_double)]


def core_graphics() -> ctypes.CDLL:
    cg = ctypes.CDLL("/System/Library/Frameworks/CoreGraphics.framework/CoreGraphics")
    cg.CGEventCreate.restype = ctypes.c_void_p
    cg.CGEventCreate.argtypes = [ctypes.c_void_p]
    cg.CGEventGetLocation.restype = CGPoint
    cg.CGEventGetLocation.argtypes = [ctypes.c_void_p]
    cg.CFRelease.argtypes = [ctypes.c_void_p]
    cg.CGWarpMouseCursorPosition.restype = ctypes.c_int32
    cg.CGWarpMouseCursorPosition.argtypes = [CGPoint]
    cg.CGAssociateMouseAndMouseCursorPosition.restype = ctypes.c_int32
    cg.CGAssociateMouseAndMouseCursorPosition.argtypes = [ctypes.c_bool]
    return cg


def main_height(all_displays: list[dict]) -> float:
    return next(display for display in all_displays if display.get("isMain"))["frame"]["height"]


def display_under_pointer(all_displays: list[dict]) -> dict:
    cg = core_graphics()
    event = cg.CGEventCreate(None)
    if not event:
        raise WMError("cannot read the pointer location")
    point = cg.CGEventGetLocation(event)
    cg.CFRelease(event)
    x, y = point.x, main_height(all_displays) - point.y
    for display in all_displays:
        frame = display["frame"]
        if frame["x"] <= x < frame["x"] + frame["width"] and frame["y"] <= y < frame["y"] + frame["height"]:
            return display
    return next(display for display in all_displays if display.get("isCurrent"))


def warp_pointer_to(display: dict, all_displays: list[dict]) -> None:
    cg = core_graphics()
    x, y = center(display)
    if cg.CGWarpMouseCursorPosition(CGPoint(x, main_height(all_displays) - y)) != 0:
        raise WMError(f"cannot move the pointer to {display['name']}")
    # Without this, macOS ignores pointer movement for a moment after the warp.
    cg.CGAssociateMouseAndMouseCursorPosition(True)


# --- actions -----------------------------------------------------------------------


def cycle(app_bundle_id: str) -> None:
    """Focus the app's previous window (by workspace, then window id); exit 1 when it has none."""
    app_windows = sorted(windows("--bundle-id", app_bundle_id), key=lambda w: (w["workspace"]["number"], w["windowId"]))
    if not app_windows:
        raise WMError(f"no windows for {app_bundle_id}")
    focused = next((i for i, window in enumerate(app_windows) if window.get("isFocused")), None)
    target = app_windows[focused - 1] if focused is not None else app_windows[-1]
    ctl("window", "navigate", target["id"])


def pull(app_bundle_id: str) -> None:
    """Move the app's previous window to the workspace under the pointer and focus it.

    Pulling again within PULL_RESTORE_SECONDS sends the last pulled window back first,
    so repeated presses step through the app's windows.
    """
    target_workspace = display_under_pointer(displays())["activeWorkspace"]["rawName"]
    app_windows = sorted(windows("--bundle-id", app_bundle_id), key=lambda w: w["windowId"])
    if not app_windows:
        raise WMError(f"no windows for {app_bundle_id}")
    focused = next((i for i, window in enumerate(app_windows) if window.get("isFocused")), None)
    window = app_windows[focused - 1] if focused is not None else app_windows[-1]

    state_file = STATE_DIR / "pull.json"
    try:
        state = json.loads(state_file.read_text())
    except FileNotFoundError:
        state = None
    except (OSError, json.JSONDecodeError) as error:
        print(f"ignoring unreadable {state_file}: {error}", file=sys.stderr)
        state = None
    if state and time.time() - state["time"] < PULL_RESTORE_SECONDS:
        try:
            ctl("window", "move-to-workspace", state["window"], state["workspace"])
        except WMError as error:  # the window may have been closed in the meantime
            print(f"cannot send back the last pulled window: {error}", file=sys.stderr)

    ctl("window", "move-to-workspace", window["id"], target_workspace)
    ctl("window", "navigate", window["id"])
    STATE_DIR.mkdir(parents=True, exist_ok=True)
    state_file.write_text(json.dumps({"time": time.time(), "window": window["id"], "workspace": raw_name(window)}))


def toggle(app_bundle_id: str) -> None:
    """Close the app's window if it is focused here, otherwise bring it here (or launch the app)."""
    current = next(workspace for workspace in workspaces() if workspace.get("isCurrent"))["rawName"]
    focused = focused_window()
    if focused and bundle_id(focused) == app_bundle_id and raw_name(focused) == current:
        ctl("window", "close", focused["id"])
        return
    app_windows = windows("--bundle-id", app_bundle_id)
    if not app_windows:
        subprocess.run(["open", "-b", app_bundle_id], check=True)
        return
    ctl("window", "move-to-workspace", app_windows[0]["id"], current)
    ctl("window", "navigate", app_windows[0]["id"])


def focus(key: str) -> None:
    ctl("command", "switch-workspace", workspace_for_key(key, workspaces())["rawName"])


def summon(key: str) -> None:
    """Show the workspace on the display under the pointer.

    A workspace already visible on another display swaps places with the one shown
    under the pointer.
    """
    all_displays = displays()
    workspace = workspace_for_key(key, workspaces())
    target = display_under_pointer(all_displays)
    source_id = workspace["display"]["id"]
    if source_id == target["id"]:
        ctl("command", "switch-workspace", workspace["rawName"])
        return

    plan = visible_plan(all_displays)
    if workspace["isVisible"]:
        displaced = next(w for w in workspaces() if w["rawName"] == plan[target["id"]])
        move_workspace(workspace, target, all_displays)
        move_workspace(displaced, display_by_id(source_id, all_displays), displays())
        plan[source_id] = displaced["rawName"]
    else:
        move_workspace(workspace, target, all_displays)
    plan[target["id"]] = workspace["rawName"]
    show(plan, target["id"])


def move_window(key: str) -> None:
    """Move the focused window to the workspace and follow it."""
    window = require_focused_window()
    ctl("window", "move-to-workspace", window["id"], workspace_for_key(key, workspaces())["rawName"])
    ctl("window", "navigate", window["id"])


def send_workspace(key: str) -> None:
    """Move the workspace to the next display (wrapping around) and focus it there."""
    all_displays = displays()
    workspace = workspace_for_key(key, workspaces())
    move_to_next_display(workspace, 1, all_displays)


def move_current_workspace(step: int) -> None:
    """Move the current workspace to the next or previous display and put the pointer there."""
    all_displays = displays()
    workspace = next(w for w in workspaces() if w.get("isCurrent"))
    target = move_to_next_display(workspace, step, all_displays)
    warp_pointer_to(target, all_displays)


def move_to_next_display(workspace: dict, step: int, all_displays: list[dict]) -> dict:
    source_id = workspace["display"]["id"]
    target = cycle_display(source_id, step, all_displays)
    if target["id"] == source_id:
        raise WMError("only one display connected")
    plan = visible_plan(all_displays)
    move_workspace(workspace, target, all_displays)
    # The source display picks another workspace by itself.
    del plan[source_id]
    plan[target["id"]] = workspace["rawName"]
    show(plan, target["id"])
    return target


def move_window_to_display(step: int) -> None:
    """Move the focused window to the next or previous display (wrapping around) and follow it."""
    all_displays = displays()
    window = require_focused_window()
    target = cycle_display(window["display"]["id"], step, all_displays)
    ctl("window", "move-to-workspace", window["id"], target["activeWorkspace"]["rawName"])
    ctl("window", "navigate", window["id"])


def move_to_default() -> None:
    """Send the focused window to its app's workspace, or to the fallback one if it is already there."""
    window = require_focused_window()
    all_workspaces = workspaces()
    target = workspace_for_key(default_key(bundle_id(window)), all_workspaces)["rawName"]
    if raw_name(window) == target:
        target = workspace_for_key(FALLBACK_KEY, all_workspaces)["rawName"]
    ctl("window", "move-to-workspace", window["id"], target)


def move_all_to_default() -> None:
    """Send every window to its app's workspace (apps missing from apps.json go to the fallback)."""
    all_workspaces = workspaces()
    failures = []
    for window in windows():
        if window.get("isScratchpad"):
            continue
        target = workspace_for_key(default_key(bundle_id(window)), all_workspaces)["rawName"]
        if raw_name(window) == target:
            continue
        try:
            ctl("window", "move-to-workspace", window["id"], target)
        except WMError as error:
            failures.append(str(error))
    if failures:
        raise WMError("; ".join(failures))


def close(quit_if_last_window: bool) -> None:
    window = require_focused_window()
    app = bundle_id(window)
    if quit_if_last_window and app and len(windows("--bundle-id", app)) <= 1:
        quit_app(app)
    else:
        ctl("window", "close", window["id"])


def close_others(quit_if_last_window: bool) -> None:
    """Close every other window on the focused window's workspace.

    With quit_if_last_window, apps whose windows would all be closed are quit instead.
    """
    window = require_focused_window()
    others = [w for w in windows("--workspace", raw_name(window)) if w["id"] != window["id"]]
    to_quit = set()
    if quit_if_last_window:
        all_windows = windows()
        for app in {bundle_id(w) for w in others if bundle_id(w)}:
            if sum(bundle_id(w) == app for w in others) == sum(bundle_id(w) == app for w in all_windows):
                to_quit.add(app)
    for app in to_quit:
        quit_app(app)
    for other in others:
        if bundle_id(other) not in to_quit:
            ctl("window", "close", other["id"])


def new_window() -> None:
    """Open a new window of the focused app (apps that ignore `open -n` just get focused)."""
    app = bundle_id(require_focused_window())
    if not app:
        raise WMError("the focused window has no bundle id")
    subprocess.run(["open", "-n", "-b", app], check=True)


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    commands = parser.add_subparsers(dest="command", required=True)
    for name in ("cycle", "pull", "toggle"):
        commands.add_parser(name).add_argument("bundle_id")
    for name in ("focus", "summon", "move-window", "send-workspace"):
        commands.add_parser(name).add_argument("key")
    for name in ("move-workspace", "move-window-to-display"):
        commands.add_parser(name).add_argument("step", choices=("next", "prev"))
    for name in ("close", "close-others"):
        commands.add_parser(name).add_argument("--quit-if-last-window", action="store_true")
    for name in ("move-to-default", "move-all-to-default", "new-window"):
        commands.add_parser(name)
    args = parser.parse_args()

    step = {"next": 1, "prev": -1}.get(getattr(args, "step", ""), 0)
    actions = {
        "cycle": lambda: cycle(args.bundle_id),
        "pull": lambda: pull(args.bundle_id),
        "toggle": lambda: toggle(args.bundle_id),
        "focus": lambda: focus(args.key),
        "summon": lambda: summon(args.key),
        "move-window": lambda: move_window(args.key),
        "send-workspace": lambda: send_workspace(args.key),
        "move-workspace": lambda: move_current_workspace(step),
        "move-window-to-display": lambda: move_window_to_display(step),
        "move-to-default": move_to_default,
        "move-all-to-default": move_all_to_default,
        "close": lambda: close(args.quit_if_last_window),
        "close-others": lambda: close_others(args.quit_if_last_window),
        "new-window": new_window,
    }
    try:
        actions[args.command]()
    except WMError as error:
        print(f"wm.py {args.command}: {error}", file=sys.stderr)
        sys.exit(1)
    except subprocess.CalledProcessError as error:
        print(f"wm.py {args.command}: {error}", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
