package main

import (
	"cmp"
	"slices"
)

// cycle steps through the apps with the given bundle IDs as one list, in apps.json order:
// each app's windows by workspace, then window id, and an app without windows as one stop
// that launches it. While one of their windows has focus, it goes to the next stop,
// wrapping around. Otherwise it returns to the window of theirs focused last, or launches
// the first app when none of them has a window.
func cycle(e *env, bundleIDs []string) error {
	if len(bundleIDs) == 0 {
		return errUsage
	}
	all, err := e.wm.windows(nil)
	if err != nil {
		return err
	}
	target, app := cycleStep(all, bundleIDs)
	if app != "" {
		return launch(app)
	}
	return e.wm.navigate(target.ID)
}

// cycleStop is a window to focus, or the bundle ID of an app without windows to launch.
type cycleStop struct {
	window window
	launch string
}

// cycleStep returns the window cycle focuses, or the bundle ID of the app it launches.
func cycleStep(all []window, bundleIDs []string) (window, string) {
	var stops []cycleStop
	var windows []window
	for _, bundleID := range bundleIDs {
		own := windowsOf(all, []string{bundleID})
		if len(own) == 0 {
			stops = append(stops, cycleStop{launch: bundleID})
			continue
		}
		slices.SortStableFunc(own, func(a, b window) int {
			return cmp.Or(cmp.Compare(a.Workspace.Number, b.Workspace.Number), compareWindowIDs(a, b))
		})
		for _, w := range own {
			stops = append(stops, cycleStop{window: w})
		}
		windows = append(windows, own...)
	}

	if f := slices.IndexFunc(stops, func(s cycleStop) bool { return s.launch == "" && s.window.IsFocused }); f >= 0 {
		next := stops[(f+1)%len(stops)]
		return next.window, next.launch
	}
	if len(windows) > 0 {
		return focusedLast(windows), ""
	}
	return window{}, bundleIDs[0]
}

// focusedLast returns the window OmniWM saw focused most recently, or the last one when it
// saw none of them focused.
func focusedLast(windows []window) window {
	var best *window
	for i, w := range windows {
		if w.FocusRank != nil && (best == nil || *w.FocusRank < *best.FocusRank) {
			best = &windows[i]
		}
	}
	if best == nil {
		return last(windows)
	}
	return *best
}
