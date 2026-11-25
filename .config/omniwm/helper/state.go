package main

import (
	"encoding/json"
	"errors"
	"fmt"
	"io/fs"
	"os"
	"path/filepath"
	"time"
)

// Short-lived state in OMNIWM_HELPER_STATE_DIR that lets a repeated press undo or extend
// the one before it. Times are Unix seconds.

type pullState struct {
	Time      float64 `json:"time"`
	Window    string  `json:"window"`
	Workspace string  `json:"workspace"` // where the window came from
}

type sendState struct {
	Time   float64 `json:"time"`
	Window string  `json:"window"`
	Key    string  `json:"key"`
}

func now() float64 {
	return float64(time.Now().UnixNano()) / 1e9
}

func (e *env) statePath(name string) string {
	return filepath.Join(e.config.stateDir, name)
}

// readState reads the state file into v and reports whether it exists.
func readState(path string, v any) (bool, error) {
	data, err := os.ReadFile(path)
	if errors.Is(err, fs.ErrNotExist) {
		return false, nil
	}
	if err != nil {
		return false, err
	}
	if err := json.Unmarshal(data, v); err != nil {
		return true, fmt.Errorf("unreadable %s: %w", path, err)
	}
	return true, nil
}

func writeState(path string, v any) error {
	if err := os.MkdirAll(filepath.Dir(path), 0o700); err != nil {
		return err
	}
	data, err := json.Marshal(v)
	if err != nil {
		return err
	}
	return os.WriteFile(path, data, 0o600)
}

// lock makes presses take turns: a quick second press starts while the first one still
// runs. A lock still held after 2 s belongs to a process that died, so it is taken over.
// The returned function releases the lock.
func lock(path string) (func(), error) {
	if err := os.MkdirAll(filepath.Dir(path), 0o700); err != nil {
		return nil, err
	}
	release := func() {
		if err := os.Remove(path); err != nil && !errors.Is(err, fs.ErrNotExist) {
			warn("cannot release %s: %v", path, err)
		}
	}
	for range 100 {
		err := os.Mkdir(path, 0o700)
		if err == nil {
			return release, nil
		}
		if !errors.Is(err, fs.ErrExist) {
			return nil, err
		}
		time.Sleep(20 * time.Millisecond)
	}
	return release, nil
}
