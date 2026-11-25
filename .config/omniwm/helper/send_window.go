package main

import (
	"errors"
	"io/fs"
	"os"
)

// sendWindow sends the focused window to the workspace with the key, without following it;
// OmniWM then focuses the next window on the source workspace. With "default" instead of a
// key, the window goes to its app's workspace, or to the fallback one if it is already
// there. Pressing the same key again within OMNIWM_FOLLOW_SECONDS follows the window
// instead.
func sendWindow(e *env, args []string) error {
	key, err := oneArg(args)
	if err != nil {
		return err
	}
	pressed := now()
	release, err := lock(e.statePath("send.lock"))
	if err != nil {
		return err
	}
	defer release()

	statePath := e.statePath("send.json")
	var previous sendState
	found, err := readState(statePath, &previous)
	if err != nil {
		warn("ignoring %v", err)
	}
	if found {
		if err := os.Remove(statePath); err != nil && !errors.Is(err, fs.ErrNotExist) {
			return err
		}
	}
	if err == nil && found && previous.Key == key && pressed-previous.Time < e.config.followSeconds {
		return e.wm.navigate(previous.Window)
	}

	w, err := e.wm.requireFocusedWindow()
	if err != nil {
		return err
	}
	workspaces, err := e.wm.workspaces()
	if err != nil {
		return err
	}
	target, err := e.sendTarget(key, w, workspaces)
	if err != nil {
		return err
	}
	if err := e.wm.moveFocusedWindow(target.RawName); err != nil {
		return err
	}
	return writeState(statePath, sendState{Time: pressed, Window: w.ID, Key: key})
}

func (e *env) sendTarget(key string, w window, workspaces []workspace) (workspace, error) {
	if key != "default" {
		return workspaceForKey(key, workspaces)
	}
	apps, err := loadApps(e.config.appsJSON)
	if err != nil {
		return workspace{}, err
	}
	target, err := workspaceForKey(defaultKey(apps, w.App.BundleID, e.config.fallbackKey), workspaces)
	if err != nil {
		return workspace{}, err
	}
	if target.RawName == w.Workspace.RawName {
		return workspaceForKey(e.config.fallbackKey, workspaces)
	}
	return target, nil
}
