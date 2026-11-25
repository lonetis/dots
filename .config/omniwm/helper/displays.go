package main

import (
	"cmp"
	"errors"
	"fmt"
	"math"
	"slices"
)

var directions = []string{"left", "right", "up", "down"}

func displayByID(id string, displays []display) (display, error) {
	for _, d := range displays {
		if d.ID == id {
			return d, nil
		}
	}
	return display{}, fmt.Errorf("no display %s", id)
}

func mainDisplay(displays []display) (display, error) {
	for _, d := range displays {
		if d.IsMain {
			return d, nil
		}
	}
	return display{}, errors.New("no main display")
}

// displayUnderPointer returns the display under the pointer, or else the current one.
func displayUnderPointer(displays []display) (display, error) {
	x, y, err := pointerLocation(displays)
	if err != nil {
		return display{}, err
	}
	for _, d := range displays {
		if d.Frame.contains(x, y) {
			return d, nil
		}
	}
	for _, d := range displays {
		if d.IsCurrent {
			return d, nil
		}
	}
	return display{}, errors.New("no display under the pointer and no current display")
}

// --- the order and adjacency of displays -------------------------------------------

// neighbor returns the display OmniWM moves to from origin in direction, without
// wrapping around.
func neighbor(origin display, direction string, displays []display, grid map[string]cell) (display, bool) {
	var best display
	var bestRank []float64
	for _, d := range displays {
		if d.ID == origin.ID {
			continue
		}
		if rank, ok := neighborRank(origin, d, direction, grid); ok && (bestRank == nil || slices.Compare(rank, bestRank) < 0) {
			best, bestRank = d, rank
		}
	}
	return best, bestRank != nil
}

// neighborRank ranks d as origin's neighbor in direction, lower being closer: by grid
// distance along the row or column, or without a grid by the distance between centers,
// preferring displays straight in that direction.
func neighborRank(origin, d display, direction string, grid map[string]cell) ([]float64, bool) {
	if grid != nil {
		from, to := grid[origin.ID], grid[d.ID]
		var offset int
		switch {
		case direction == "right" && to.row == from.row:
			offset = to.column - from.column
		case direction == "left" && to.row == from.row:
			offset = from.column - to.column
		case direction == "up" && to.column == from.column:
			offset = from.row - to.row
		case direction == "down" && to.column == from.column:
			offset = to.row - from.row
		default:
			return nil, false
		}
		return []float64{float64(offset)}, offset > 0
	}

	ox, oy := origin.Frame.center()
	x, y := d.Frame.center()
	dx, dy := x-ox, y-oy
	adx, ady := math.Abs(dx), math.Abs(dy)
	distance := dx*dx + dy*dy
	switch {
	case (direction == "left" && dx < 0 || direction == "right" && dx > 0) && adx >= ady:
		return []float64{adx, ady, distance}, true
	case (direction == "up" && dy > 0 || direction == "down" && dy < 0) && ady >= adx:
		return []float64{ady, adx, distance}, true
	}
	return nil, false
}

// route returns the directions that lead from source to target, one per hop to an
// adjacent monitor, or false when target can't be reached.
func route(source, target display, displays []display, grid map[string]cell) ([]string, bool) {
	paths := map[string][]string{source.ID: {}}
	queue := []display{source}
	for len(queue) > 0 {
		current := queue[0]
		queue = queue[1:]
		if current.ID == target.ID {
			return paths[current.ID], true
		}
		for _, direction := range directions {
			next, ok := neighbor(current, direction, displays, grid)
			if _, seen := paths[next.ID]; ok && !seen {
				paths[next.ID] = append(slices.Clone(paths[current.ID]), direction)
				queue = append(queue, next)
			}
		}
	}
	return nil, false
}

// cycleDisplay returns the display step places after the one with originID, wrapping
// around. Next and previous go along the grid rows, or from left to right without a grid.
func cycleDisplay(originID string, step int, displays []display, grid map[string]cell) (display, error) {
	ordered := slices.Clone(displays)
	slices.SortStableFunc(ordered, func(a, b display) int {
		if grid != nil {
			return cmp.Or(cmp.Compare(grid[a.ID].row, grid[b.ID].row), cmp.Compare(grid[a.ID].column, grid[b.ID].column))
		}
		ax, ay := a.Frame.center()
		bx, by := b.Frame.center()
		return cmp.Or(cmp.Compare(ax, bx), cmp.Compare(by, ay))
	})
	i := slices.IndexFunc(ordered, func(d display) bool { return d.ID == originID })
	if i < 0 {
		return display{}, fmt.Errorf("no display %s", originID)
	}
	n := len(ordered)
	return ordered[((i+step)%n+n)%n], nil
}

// --- moving workspaces between displays ----------------------------------------------

func (e *env) grid(displays []display) (map[string]cell, error) {
	r, err := readRouting(e.config.settingsTOML)
	if err != nil {
		return nil, err
	}
	return gridCells(r, displays), nil
}

// visiblePlan maps each display id to the raw name of the workspace it shows.
func visiblePlan(displays []display) map[string]string {
	plan := map[string]string{}
	for _, d := range displays {
		plan[d.ID] = d.ActiveWorkspace.RawName
	}
	return plan
}

// moveWorkspaceTo moves the workspace to target, hopping along the route over adjacent
// monitors.
func (e *env) moveWorkspaceTo(ws workspace, target display, displays []display, grid map[string]cell) error {
	source, err := displayByID(ws.Display.ID, displays)
	if err != nil {
		return err
	}
	hops, ok := route(source, target, displays, grid)
	if !ok {
		return fmt.Errorf("no monitor route to %s", target.Name)
	}
	for _, direction := range hops {
		if err := e.wm.moveWorkspaceToMonitor(ws.RawName, direction); err != nil {
			return err
		}
	}
	return nil
}

// show makes each display in plan (display id → raw workspace name) show its workspace,
// then focuses the display focusID. Moving a workspace across several monitors changes
// what the monitors in between show, so callers pass the whole picture they want.
func (e *env) show(plan map[string]string, focusID string) error {
	current, err := e.wm.displays()
	if err != nil {
		return err
	}
	active := visiblePlan(current)
	for _, d := range current {
		if name, ok := plan[d.ID]; ok && d.ID != focusID && active[d.ID] != name {
			if err := e.wm.switchWorkspace(name); err != nil {
				return err
			}
		}
	}
	return e.wm.switchWorkspace(plan[focusID])
}

// moveToNextDisplay moves the workspace to the display step places further, wrapping
// around, focuses it there and returns that display.
func (e *env) moveToNextDisplay(ws workspace, step int, displays []display, grid map[string]cell) (display, error) {
	target, err := cycleDisplay(ws.Display.ID, step, displays, grid)
	if err != nil {
		return display{}, err
	}
	if target.ID == ws.Display.ID {
		return display{}, errors.New("only one display connected")
	}
	plan := visiblePlan(displays)
	if err := e.moveWorkspaceTo(ws, target, displays, grid); err != nil {
		return display{}, err
	}
	// The source display picks another workspace by itself.
	delete(plan, ws.Display.ID)
	plan[target.ID] = ws.RawName
	return target, e.show(plan, target.ID)
}
