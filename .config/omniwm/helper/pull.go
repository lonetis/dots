package main

import (
	"fmt"
	"slices"
	"strings"
)

// pull moves the previous window of the apps with the given bundle IDs to the workspace
// under the pointer and focuses it. Pulling the same apps again within
// OMNIWM_PULL_RESTORE_SECONDS sends the last pulled window back first, so repeated presses
// step through the apps' windows; pulling other apps leaves it where it is.
func pull(e *env, bundleIDs []string) error {
	if len(bundleIDs) == 0 {
		return errUsage
	}
	apps := slices.Sorted(slices.Values(bundleIDs))
	displays, err := e.wm.displays()
	if err != nil {
		return err
	}
	target, err := displayUnderPointer(displays)
	if err != nil {
		return err
	}
	all, err := e.wm.windows(nil)
	if err != nil {
		return err
	}
	windows := windowsOf(all, bundleIDs)
	if len(windows) == 0 {
		return fmt.Errorf("no windows for %s", strings.Join(bundleIDs, " "))
	}
	slices.SortStableFunc(windows, compareWindowIDs)
	w := previousOrLast(windows, last)

	statePath := e.statePath("pull.json")
	var previous pullState
	if found, err := readState(statePath, &previous); err != nil {
		warn("ignoring %v", err)
	} else if found && slices.Equal(previous.Apps, apps) && now()-previous.Time < e.config.pullRestoreSeconds {
		// The window may have been closed in the meantime.
		if err := e.wm.moveWindow(previous.Window, previous.Workspace); err != nil {
			warn("cannot send back the last pulled window: %v", err)
		}
	}

	if err := e.wm.moveWindow(w.ID, target.ActiveWorkspace.RawName); err != nil {
		return err
	}
	if err := e.wm.navigate(w.ID); err != nil {
		return err
	}
	return writeState(statePath, pullState{Time: now(), Apps: apps, Window: w.ID, Workspace: w.Workspace.RawName})
}
