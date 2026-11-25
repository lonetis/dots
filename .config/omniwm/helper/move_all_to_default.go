package main

import "fmt"

// moveAllToDefault sends every window to its app's workspace; apps missing from apps.json
// go to the fallback one.
func moveAllToDefault(e *env, args []string) error {
	if len(args) != 0 {
		return errUsage
	}
	workspaces, err := e.wm.workspaces()
	if err != nil {
		return err
	}
	all, err := e.wm.windows(nil)
	if err != nil {
		return err
	}
	apps, err := loadApps(e.config.appsJSON)
	if err != nil {
		return err
	}
	failures := 0
	for _, w := range all {
		if w.IsScratchpad {
			continue
		}
		target, err := workspaceForKey(defaultKey(apps, w.App.BundleID, e.config.fallbackKey), workspaces)
		if err != nil {
			return err
		}
		if w.Workspace.RawName == target.RawName {
			continue
		}
		if err := e.wm.moveWindow(w.ID, target.RawName); err != nil {
			warn("%v", err)
			failures++
		}
	}
	if failures > 0 {
		return fmt.Errorf("%d windows could not be moved", failures)
	}
	return nil
}
