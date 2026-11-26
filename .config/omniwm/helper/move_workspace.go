package main

// moveWorkspace moves the current workspace to the next or previous display, wrapping
// around.
func moveWorkspace(e *env, args []string) error {
	step, err := parseStep(args)
	if err != nil {
		return err
	}
	displays, err := e.wm.displays()
	if err != nil {
		return err
	}
	workspaces, err := e.wm.workspaces()
	if err != nil {
		return err
	}
	ws, err := currentWorkspace(workspaces)
	if err != nil {
		return err
	}
	return e.moveToNextDisplay(ws, step, displays)
}
