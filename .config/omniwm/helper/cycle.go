package main

import (
	"cmp"
	"fmt"
	"slices"
	"strings"
)

// cycle focuses a window of the apps with the given bundle IDs. When none of them has
// focus, it returns to the one focused last; when one has, it steps to the previous window
// by workspace, then window id. It fails when the apps have no windows, so Karabiner
// launches one instead.
func cycle(e *env, bundleIDs []string) error {
	if len(bundleIDs) == 0 {
		return errUsage
	}
	all, err := e.wm.windows(nil)
	if err != nil {
		return err
	}
	windows := windowsOf(all, bundleIDs)
	if len(windows) == 0 {
		return fmt.Errorf("no windows for %s", strings.Join(bundleIDs, " "))
	}
	slices.SortStableFunc(windows, func(a, b window) int {
		return cmp.Or(cmp.Compare(a.Workspace.Number, b.Workspace.Number), compareWindowIDs(a, b))
	})
	target := previousOrLast(windows, focusedLast)
	return e.wm.navigate(target.ID)
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
