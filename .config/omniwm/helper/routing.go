package main

import (
	"bufio"
	"fmt"
	"os"
	"slices"
	"strconv"
	"strings"
)

// The monitor grid from OmniWM's Monitor Setup ([routing] in settings.toml). OmniWM only
// moves a workspace to an adjacent monitor, so longer moves hop along a route over it.

type cell struct {
	column, row int
}

type monitorEntry struct {
	uuid    string
	hasUUID bool
	name    string
	cell    cell
}

type routing struct {
	mode         string
	arrangements [][]monitorEntry
}

// readRouting reads [routing] from settings.toml. OmniWM writes the file in canonical form,
// one key per line and a header per table, which is all this scanner handles; a TOML
// parser would read all 2,000 lines on every display move.
func readRouting(path string) (routing, error) {
	file, err := os.Open(path)
	if err != nil {
		return routing{}, fmt.Errorf("cannot read %s: %w", path, err)
	}
	defer file.Close()

	var r routing
	section := ""
	scanner := bufio.NewScanner(file)
	for scanner.Scan() {
		line := scanner.Text()
		if strings.HasPrefix(line, "[") {
			section = line
			switch section {
			case "[[routing.arrangements]]":
				r.arrangements = append(r.arrangements, nil)
			case "[[routing.arrangements.monitors]]":
				if len(r.arrangements) == 0 {
					return routing{}, fmt.Errorf("%s: monitors outside an arrangement", path)
				}
				r.arrangements[len(r.arrangements)-1] = append(r.arrangements[len(r.arrangements)-1], monitorEntry{})
			}
			continue
		}
		key, value, ok := strings.Cut(line, " = ")
		if !ok {
			continue
		}
		var err error
		switch section {
		case "[routing]":
			if key == "mode" {
				r.mode, err = strconv.Unquote(value)
			}
		case "[[routing.arrangements.monitors]]":
			monitors := r.arrangements[len(r.arrangements)-1]
			m := &monitors[len(monitors)-1]
			switch key {
			case "gridColumn":
				m.cell.column, err = strconv.Atoi(value)
			case "gridRow":
				m.cell.row, err = strconv.Atoi(value)
			case "monitorDisplayUUID":
				m.uuid, err = strconv.Unquote(value)
				m.hasUUID = true
			case "monitorName":
				m.name, err = strconv.Unquote(value)
			}
		}
		if err != nil {
			return routing{}, fmt.Errorf("%s: cannot read %q: %w", path, line, err)
		}
	}
	if err := scanner.Err(); err != nil {
		return routing{}, fmt.Errorf("cannot read %s: %w", path, err)
	}
	return r, nil
}

// gridCells returns each display's cell in the saved arrangement OmniWM picks for these
// displays (preferring one with exactly these monitors, then the smallest), or nil when
// routing follows the macOS arrangement.
func gridCells(r routing, displays []display) map[string]cell {
	if r.mode != "custom" {
		return nil
	}
	var best map[string]cell
	var bestRank []int
	for _, monitors := range r.arrangements {
		cells := matchArrangement(monitors, displays)
		if cells == nil {
			continue
		}
		extraMonitors := 0
		if len(monitors) != len(displays) {
			extraMonitors = 1
		}
		rank := []int{extraMonitors, len(monitors)}
		if best == nil || slices.Compare(rank, bestRank) < 0 {
			best, bestRank = cells, rank
		}
	}
	return best
}

// matchArrangement maps every display to its cell, matching by UUID or else by name, or
// returns nil when a display is missing or two share a cell.
func matchArrangement(monitors []monitorEntry, displays []display) map[string]cell {
	cells := map[string]cell{}
	taken := map[cell]bool{}
	for _, d := range displays {
		i := slices.IndexFunc(monitors, func(m monitorEntry) bool { return m.hasUUID && m.uuid == d.UUID })
		if i < 0 {
			i = slices.IndexFunc(monitors, func(m monitorEntry) bool { return !m.hasUUID && m.name == d.Name })
		}
		if i < 0 || taken[monitors[i].cell] {
			return nil
		}
		cells[d.ID] = monitors[i].cell
		taken[monitors[i].cell] = true
	}
	return cells
}
