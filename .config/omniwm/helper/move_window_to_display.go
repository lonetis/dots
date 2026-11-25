package main

// moveWindowToDisplay moves the focused window to the next or previous display, wrapping
// around, and follows it.
func moveWindowToDisplay(e *env, args []string) error {
	step, err := parseStep(args)
	if err != nil {
		return err
	}
	displays, err := e.wm.displays()
	if err != nil {
		return err
	}
	w, err := e.wm.requireFocusedWindow()
	if err != nil {
		return err
	}
	grid, err := e.grid(displays)
	if err != nil {
		return err
	}
	target, err := cycleDisplay(w.Display.ID, step, displays, grid)
	if err != nil {
		return err
	}
	if err := e.wm.moveWindow(w.ID, target.ActiveWorkspace.RawName); err != nil {
		return err
	}
	return e.wm.navigate(w.ID)
}
