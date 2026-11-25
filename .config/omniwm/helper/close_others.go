package main

import "fmt"

// closeOthers closes every other window on the focused window's workspace.
func closeOthers(e *env, args []string) error {
	if len(args) != 0 {
		return errUsage
	}
	focused, err := e.wm.requireFocusedWindow()
	if err != nil {
		return err
	}
	all, err := e.wm.windows(nil)
	if err != nil {
		return err
	}
	failures := 0
	for _, w := range all {
		if w.Workspace.RawName != focused.Workspace.RawName || w.ID == focused.ID {
			continue
		}
		if err := e.wm.closeWindow(w.ID); err != nil {
			warn("%v", err)
			failures++
		}
	}
	if failures > 0 {
		return fmt.Errorf("%d windows could not be closed", failures)
	}
	return nil
}
