package main

import (
	"encoding/json"
	"errors"
	"fmt"
	"strconv"
)

// The data OmniWM's queries return. Frames use AppKit coordinates: the origin is the
// bottom-left corner of the main display and y grows upwards.

type workspaceRef struct {
	RawName string `json:"rawName"`
	Number  int    `json:"number"`
}

type displayRef struct {
	ID string `json:"id"`
}

type window struct {
	ID       string `json:"id"`
	WindowID *int   `json:"windowId"`
	App      struct {
		BundleID string `json:"bundleId"`
	} `json:"app"`
	Workspace    workspaceRef `json:"workspace"`
	Display      displayRef   `json:"display"`
	IsFocused    bool         `json:"isFocused"`
	IsScratchpad bool         `json:"isScratchpad"`
	FocusRank    *int         `json:"focusRank"` // 0 = focused most recently; nil = never focused
}

type workspace struct {
	RawName     string     `json:"rawName"`
	DisplayName string     `json:"displayName"`
	Display     displayRef `json:"display"`
	IsVisible   bool       `json:"isVisible"`
	IsCurrent   bool       `json:"isCurrent"`
}

type frame struct {
	X      float64 `json:"x"`
	Y      float64 `json:"y"`
	Width  float64 `json:"width"`
	Height float64 `json:"height"`
}

type display struct {
	ID              string       `json:"id"`
	Name            string       `json:"name"`
	UUID            string       `json:"uuid"`
	IsMain          bool         `json:"isMain"`
	IsCurrent       bool         `json:"isCurrent"`
	Frame           frame        `json:"frame"`
	ActiveWorkspace workspaceRef `json:"activeWorkspace"`
}

func (f frame) center() (x, y float64) {
	return f.X + f.Width/2, f.Y + f.Height/2
}

func (f frame) contains(x, y float64) bool {
	return f.X <= x && x < f.X+f.Width && f.Y <= y && y < f.Y+f.Height
}

var (
	windowFields    = []string{"id", "window-id", "app", "workspace", "display", "is-focused", "is-scratchpad", "focus-rank"}
	workspaceFields = []string{"raw-name", "display-name", "display", "is-visible", "is-current"}
	displayFields   = []string{"id", "name", "uuid", "is-main", "is-current", "frame", "active-workspace"}
)

// --- queries ---------------------------------------------------------------------

func (c *client) query(name string, fields []string, selectors map[string]any, into any, okCodes ...string) error {
	payload, err := c.request("query", name, map[string]any{"fields": fields, "selectors": selectors}, okCodes...)
	if err != nil || len(payload) == 0 {
		return err
	}
	if err := json.Unmarshal(payload, into); err != nil {
		return fmt.Errorf("query %s: unreadable result: %w", name, err)
	}
	return nil
}

// windows returns the windows matching the selectors, e.g. {"bundleId": …}; nil means all.
func (c *client) windows(selectors map[string]any) ([]window, error) {
	var result struct {
		Windows []window `json:"windows"`
	}
	if selectors == nil {
		selectors = map[string]any{}
	}
	err := c.query("windows", windowFields, selectors, &result)
	return result.Windows, err
}

// focusedWindow returns nil when no managed window has focus.
func (c *client) focusedWindow() (*window, error) {
	var result struct {
		Window *window `json:"window"`
	}
	err := c.query("focused-window", []string{}, map[string]any{}, &result, "not_found", "no_focused_window")
	return result.Window, err
}

func (c *client) requireFocusedWindow() (window, error) {
	w, err := c.focusedWindow()
	if err != nil {
		return window{}, err
	}
	if w == nil {
		return window{}, errors.New("no focused managed window")
	}
	return *w, nil
}

func (c *client) workspaces() ([]workspace, error) {
	var result struct {
		Workspaces []workspace `json:"workspaces"`
	}
	err := c.query("workspaces", workspaceFields, map[string]any{}, &result)
	return result.Workspaces, err
}

func (c *client) displays() ([]display, error) {
	var result struct {
		Displays []display `json:"displays"`
	}
	err := c.query("displays", displayFields, map[string]any{}, &result)
	return result.Displays, err
}

// --- actions; workspaces are given by their raw name --------------------------------

func (c *client) navigate(windowID string) error {
	_, err := c.request("window", "navigate", map[string]any{"windowId": windowID})
	return err
}

func (c *client) closeWindow(windowID string) error {
	_, err := c.request("window", "close", map[string]any{"windowId": windowID})
	return err
}

// moveWindow moves a window by id and leaves focus where it is.
func (c *client) moveWindow(windowID, workspace string) error {
	_, err := c.request("window", "move-to-workspace", map[string]any{"windowId": windowID, "workspaceTarget": rawID(workspace)})
	return err
}

// moveFocusedWindow moves the focused window; focus stays on its workspace, where OmniWM
// focuses the next window.
func (c *client) moveFocusedWindow(workspace string) error {
	return c.workspaceCommand("move-to-workspace", workspace)
}

func (c *client) switchWorkspace(workspace string) error {
	return c.workspaceCommand("switch-workspace", workspace)
}

// moveWorkspaceToMonitor moves a workspace to the adjacent monitor in direction. The move
// is a runtime override that a settings reload clears.
func (c *client) moveWorkspaceToMonitor(workspace, direction string) error {
	_, err := c.request("workspace", "move-to-monitor", map[string]any{"workspaceTarget": rawID(workspace), "direction": direction, "force": true})
	return err
}

func (c *client) workspaceCommand(name, workspace string) error {
	// OmniWM names workspaces with positive integers, so the raw name is the number.
	number, err := strconv.Atoi(workspace)
	if err != nil {
		return fmt.Errorf("workspace %q has no number", workspace)
	}
	_, err = c.request("command", name, map[string]any{"arguments": map[string]any{"workspaceNumber": number}})
	return err
}

func rawID(workspace string) map[string]any {
	return map[string]any{"kind": "raw-id", "value": workspace}
}
