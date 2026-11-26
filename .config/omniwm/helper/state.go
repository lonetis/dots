package main

import (
	"encoding/json"
	"errors"
	"fmt"
	"io/fs"
	"os"
	"path/filepath"
	"syscall"
	"time"
)

// Short-lived state in OMNIWM_HELPER_STATE_DIR that lets a repeated press undo or extend
// the one before it. Times are Unix seconds.

type pullState struct {
	Time      float64  `json:"time"`
	Apps      []string `json:"apps"` // the bundle IDs pulled from, sorted
	Window    string   `json:"window"`
	Workspace string   `json:"workspace"` // where the window came from
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
// runs. The kernel releases the lock when the process exits, even after a crash, and
// requestTimeout bounds how long a holder waits for OmniWM. The returned function
// releases the lock.
func lock(path string) (func(), error) {
	if err := os.MkdirAll(filepath.Dir(path), 0o700); err != nil {
		return nil, err
	}
	file, err := os.OpenFile(path, os.O_CREATE|os.O_RDWR, 0o600)
	if err != nil {
		return nil, err
	}
	if err := syscall.Flock(int(file.Fd()), syscall.LOCK_EX); err != nil {
		file.Close()
		return nil, fmt.Errorf("cannot lock %s: %w", path, err)
	}
	return func() {
		// Closing the file releases the lock.
		if err := file.Close(); err != nil {
			warn("cannot release %s: %v", path, err)
		}
	}, nil
}
