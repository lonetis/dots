package main

// summon shows the workspace with the key on the display under the pointer. A workspace
// already visible on another display swaps places with the one shown under the pointer.
func summon(e *env, args []string) error {
	key, err := oneArg(args)
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
	ws, err := workspaceForKey(key, workspaces)
	if err != nil {
		return err
	}
	target, err := displayUnderPointer(displays)
	if err != nil {
		return err
	}
	if ws.Display.ID == target.ID {
		return e.wm.switchWorkspace(ws.RawName)
	}

	grid, err := e.grid(displays)
	if err != nil {
		return err
	}
	plan := visiblePlan(displays)
	if ws.IsVisible {
		displacedName := plan[target.ID]
		displaced, err := workspaceByRawName(displacedName, workspaces)
		if err != nil {
			return err
		}
		source, err := displayByID(ws.Display.ID, displays)
		if err != nil {
			return err
		}
		if err := e.moveWorkspaceTo(ws, target, displays, grid); err != nil {
			return err
		}
		moved, err := e.wm.displays()
		if err != nil {
			return err
		}
		if err := e.moveWorkspaceTo(displaced, source, moved, grid); err != nil {
			return err
		}
		plan[source.ID] = displacedName
	} else if err := e.moveWorkspaceTo(ws, target, displays, grid); err != nil {
		return err
	}
	plan[target.ID] = ws.RawName
	return e.show(plan, target.ID)
}
