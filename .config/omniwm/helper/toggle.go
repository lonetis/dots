package main

// toggle closes the app's window if it has focus on the current workspace, otherwise
// brings one of its windows here and focuses it, or launches the app.
func toggle(e *env, args []string) error {
	bundleID, err := oneArg(args)
	if err != nil {
		return err
	}
	workspaces, err := e.wm.workspaces()
	if err != nil {
		return err
	}
	current, err := currentWorkspace(workspaces)
	if err != nil {
		return err
	}
	focused, err := e.wm.focusedWindow()
	if err != nil {
		return err
	}
	if focused != nil && focused.App.BundleID == bundleID && focused.Workspace.RawName == current.RawName {
		return e.wm.closeWindow(focused.ID)
	}

	windows, err := e.wm.windows(map[string]any{"bundleId": bundleID})
	if err != nil {
		return err
	}
	if len(windows) == 0 {
		return launch(bundleID)
	}
	if err := e.wm.moveWindow(windows[0].ID, current.RawName); err != nil {
		return err
	}
	return e.wm.navigate(windows[0].ID)
}
