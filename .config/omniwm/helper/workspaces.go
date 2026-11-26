package main

import (
	"cmp"
	"encoding/json"
	"fmt"
	"os"
	"os/exec"
	"slices"
	"strings"
)

// Workspaces are addressed by their key (a–z, ä, ö, ü, 0–9), which OmniWM shows as the
// upper-case display name of a numbered workspace (see workspaces.ts in the Karabiner
// config).

func workspaceForKey(key string, all []workspace) (workspace, error) {
	label := strings.ToUpper(key)
	for _, w := range all {
		if cmp.Or(w.DisplayName, w.RawName) == label {
			return w, nil
		}
	}
	return workspace{}, fmt.Errorf("no workspace with display name %q; run the Karabiner build to regenerate them", label)
}

func workspaceByRawName(rawName string, all []workspace) (workspace, error) {
	for _, w := range all {
		if w.RawName == rawName {
			return w, nil
		}
	}
	return workspace{}, fmt.Errorf("no workspace %q", rawName)
}

func currentWorkspace(all []workspace) (workspace, error) {
	for _, w := range all {
		if w.IsCurrent {
			return w, nil
		}
	}
	return workspace{}, fmt.Errorf("no current workspace")
}

// windowsOf returns the windows of the apps with the given bundle IDs.
func windowsOf(all []window, bundleIDs []string) []window {
	var matching []window
	for _, w := range all {
		if slices.Contains(bundleIDs, w.App.BundleID) {
			matching = append(matching, w)
		}
	}
	return matching
}

// compareWindowIDs orders windows by macOS window id; windows without one come first.
func compareWindowIDs(a, b window) int {
	switch {
	case a.WindowID == nil && b.WindowID == nil:
		return 0
	case a.WindowID == nil:
		return -1
	case b.WindowID == nil:
		return 1
	}
	return cmp.Compare(*a.WindowID, *b.WindowID)
}

// previousOrLast returns the window before the focused one, wrapping around, or with none
// focused the result of fallback.
func previousOrLast(windows []window, fallback func([]window) window) window {
	if f := slices.IndexFunc(windows, func(w window) bool { return w.IsFocused }); f >= 0 {
		return windows[(f-1+len(windows))%len(windows)]
	}
	return fallback(windows)
}

func last(windows []window) window {
	return windows[len(windows)-1]
}

// --- apps ------------------------------------------------------------------------

// launch opens the app, or brings it to the front when it already runs.
func launch(bundleID string) error {
	if output, err := exec.Command("open", "-b", bundleID).CombinedOutput(); err != nil {
		return fmt.Errorf("cannot launch %s: %v: %s", bundleID, err, output)
	}
	return nil
}

type app struct {
	BundleID  string `json:"bundleId"`
	Workspace string `json:"workspace"`
}

func loadApps(path string) ([]app, error) {
	data, err := os.ReadFile(path)
	if err != nil {
		return nil, fmt.Errorf("cannot read %s: %w", path, err)
	}
	var apps []app
	if err := json.Unmarshal(data, &apps); err != nil {
		return nil, fmt.Errorf("unreadable %s: %w", path, err)
	}
	return apps, nil
}

// defaultKey returns the key of the workspace apps.json assigns the app to, or fallback.
func defaultKey(apps []app, bundleID, fallback string) string {
	for _, a := range apps {
		if a.BundleID == bundleID {
			return a.Workspace
		}
	}
	return fallback
}
