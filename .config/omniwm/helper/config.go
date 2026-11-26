package main

import (
	"fmt"
	"os"
	"path/filepath"
	"strconv"
)

// config holds the OMNIWM_* environment variables; loadConfig has their defaults.
type config struct {
	appsJSON           string  // apps with their workspace and Karabiner key
	socket             string  // OmniWM's IPC socket; omniwmctl reads the same variable
	stateDir           string  // short-lived pull and send state
	fallbackKey        string  // workspace for apps missing from apps.json
	pullRestoreSeconds float64 // a repeated pull within this time sends the last pulled window back
	followSeconds      float64 // pressing a send key again within this time follows the window
}

func loadConfig() (config, error) {
	home, err := os.UserHomeDir()
	if err != nil {
		return config{}, err
	}
	cfg := config{
		appsJSON:    envOr("OMNIWM_APPS_JSON", filepath.Join(home, ".config/karabiner-config/src/apps.json")),
		socket:      envOr("OMNIWM_SOCKET", filepath.Join(home, "Library/Application Support/com.barut.OmniWM/ipc.sock")),
		stateDir:    envOr("OMNIWM_HELPER_STATE_DIR", filepath.Join(home, ".local/state/omniwm-helper")),
		fallbackKey: envOr("OMNIWM_FALLBACK_WORKSPACE", "q"),
	}
	if cfg.pullRestoreSeconds, err = envSeconds("OMNIWM_PULL_RESTORE_SECONDS", 5); err != nil {
		return config{}, err
	}
	if cfg.followSeconds, err = envSeconds("OMNIWM_FOLLOW_SECONDS", 0.5); err != nil {
		return config{}, err
	}
	return cfg, nil
}

func envOr(name, fallback string) string {
	if value := os.Getenv(name); value != "" {
		return value
	}
	return fallback
}

func envSeconds(name string, fallback float64) (float64, error) {
	value := os.Getenv(name)
	if value == "" {
		return fallback, nil
	}
	seconds, err := strconv.ParseFloat(value, 64)
	if err != nil || seconds < 0 {
		return 0, fmt.Errorf("%s is not a number of seconds: %q", name, value)
	}
	return seconds, nil
}
