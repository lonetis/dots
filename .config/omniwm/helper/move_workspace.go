package main

// moveWorkspace moves the current workspace to the next or previous display, wrapping
// around. With OMNIWM_WARP_POINTER=true it also puts the pointer there.
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
	grid, err := e.grid(displays)
	if err != nil {
		return err
	}
	target, err := e.moveToNextDisplay(ws, step, displays, grid)
	if err != nil {
		return err
	}
	if e.config.warpPointer {
		return warpPointer(target, displays)
	}
	return nil
}
