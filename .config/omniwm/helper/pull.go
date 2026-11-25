package main

import (
	"fmt"
	"slices"
	"strings"
)

// pull moves the previous window of the apps with the given bundle IDs to the workspace
// under the pointer and focuses it. Pulling again within OMNIWM_PULL_RESTORE_SECONDS sends
// the last pulled window back first, so repeated presses step through the apps' windows.
func pull(e *env, bundleIDs []string) error {
	if len(bundleIDs) == 0 {
		return errUsage
	}
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
	} else if found && now()-previous.Time < e.config.pullRestoreSeconds {
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
	return writeState(statePath, pullState{Time: now(), Window: w.ID, Workspace: w.Workspace.RawName})
}
