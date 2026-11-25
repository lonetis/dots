// omniwm-helper runs the OmniWM actions that Karabiner binds and that need state or more
// than one OmniWM request. It talks to OmniWM's IPC socket itself, the way omniwmctl does,
// because starting omniwmctl costs about 5 ms per request.
package main

import (
	"errors"
	"fmt"
	"maps"
	"os"
	"slices"
	"strings"
)

// errUsage makes run print the action's usage line instead of the error.
var errUsage = errors.New("usage")

type action struct {
	args string
	run  func(e *env, args []string) error
}

var actions = map[string]action{
	"close-others":           {"", closeOthers},
	"cycle":                  {"<bundle-id>...", cycle},
	"move-all-to-default":    {"", moveAllToDefault},
	"move-window-to-display": {"next|prev", moveWindowToDisplay},
	"move-workspace":         {"next|prev", moveWorkspace},
	"pull":                   {"<bundle-id>...", pull},
	"send-window":            {"<workspace-key>|default", sendWindow},
	"summon":                 {"<workspace-key>", summon},
	"toggle":                 {"<bundle-id>", toggle},
}

// env is what every action works with: the configuration and a client for OmniWM.
type env struct {
	config config
	wm     *client
}

func main() {
	if err := run(os.Args[1:]); err != nil {
		fmt.Fprintf(os.Stderr, "omniwm-helper: %v\n", err)
		os.Exit(1)
	}
}

func run(args []string) error {
	if len(args) == 0 {
		return errors.New(usage())
	}
	name, args := args[0], args[1:]
	a, ok := actions[name]
	if !ok {
		return fmt.Errorf("unknown action %q\n%s", name, usage())
	}
	cfg, err := loadConfig()
	if err != nil {
		return err
	}
	wm, err := newClient(cfg.socket)
	if err != nil {
		return err
	}
	if err := a.run(&env{config: cfg, wm: wm}, args); err != nil {
		if errors.Is(err, errUsage) {
			return fmt.Errorf("usage: omniwm-helper %s", strings.TrimSpace(name+" "+a.args))
		}
		return fmt.Errorf("%s: %w", name, err)
	}
	return nil
}

func usage() string {
	lines := []string{"usage: omniwm-helper <action> [arguments]", "actions:"}
	for _, name := range slices.Sorted(maps.Keys(actions)) {
		lines = append(lines, "  "+strings.TrimSpace(name+" "+actions[name].args))
	}
	return strings.Join(lines, "\n")
}

func oneArg(args []string) (string, error) {
	if len(args) != 1 {
		return "", errUsage
	}
	return args[0], nil
}

// parseStep turns next and prev into the step through the display order.
func parseStep(args []string) (int, error) {
	arg, err := oneArg(args)
	if err != nil {
		return 0, err
	}
	switch arg {
	case "next":
		return 1, nil
	case "prev":
		return -1, nil
	}
	return 0, errUsage
}

// warn reports a problem that doesn't stop the action.
func warn(format string, args ...any) {
	fmt.Fprintf(os.Stderr, "omniwm-helper: "+format+"\n", args...)
}
