# Bootstrap

Sets up a Mac from scratch, or brings an existing one up to date: Homebrew, yadm, the dotfiles, all software, macOS settings, the Dock and apps built from source.

## Files

| Path | Tracked | Managed by | Purpose |
|---|---|---|---|
| `.init.sh` | yes | manual | `curl \| bash` installer: Homebrew, yadm, git-crypt, clone, then bootstrap |
| `.config/yadm/bootstrap` | yes | manual | Asks for the admin password once, then runs `bootstrap.d/*.sh` |
| `.config/yadm/bootstrap.d/NNN-*.sh` | yes | manual | One idempotent step per file, run in sort order |

| Step | Does |
|---|---|
| `000-brew-install.sh` | Installs Homebrew if missing, before anything that needs it |
| `001-git-crypt.sh` | Unlocks git-crypt with `~/.git-crypt`; skipped when already unlocked |
| `002-path.sh` | PATH for programs started outside a shell: launchd's user PATH (apps like Tinycast) and Karabiner's `karabiner_environment` |
| `003-defaults.sh` | `defaults write`: ⌃⌘-drag moves windows, no window animations |
| `011-brew-update.sh` | `brew update` |
| `012-brew-bundle.sh` | `brew bundle install --global`, then `brew bundle cleanup --global --force`, which **uninstalls everything not in `.Brewfile`** |
| `013-brew-cleanup.sh` | `brew cleanup --prune=all`, `brew autoremove` |
| `020-dock.sh` | Rebuilds the Dock with `dockutil` |
| `030-tinycast-extensions.sh` | Builds custom Raycast extensions for Tinycast, see [tinycast.md](tinycast.md) |
| `031-omniwm-helper.sh` | Builds the OmniWM helper, which isn't tracked, see [omniwm.md](omniwm.md#helper) |

## How it works

- The README pipes `.init.sh` through curl, and `dots init` runs it again. On a fresh machine it clones over HTTPS (no SSH key yet) and switches `origin` to SSH; on an existing machine it runs `yadm pull`. Then it runs `yadm bootstrap`, so a failing step can be fixed and rerun with `dots init` without leaving `origin` on HTTPS.
- `bootstrap` asks for the admin password once and validates it. It exports a `SUDO_ASKPASS` helper and keeps the sudo timestamp fresh, because brew resets it on every call, so steps can use plain `sudo`. It puts Homebrew's directories on PATH, so the steps after `000` find a Homebrew installed there, then runs every `bootstrap.d/*.sh` in sort order and stops at the first failing step, including one that isn't executable.
- Prefix ranges: `000–009` prerequisites (Homebrew itself first) and system settings, `010–019` Homebrew packages, `020–029` Dock, `030–039` apps built from source.
- `002-path.sh` holds the one PATH for GUI contexts. launchd's user PATH (`launchctl config user path`) applies after a reboot; Karabiner reads its file at once.

## Changing it

- Add a step as `bootstrap.d/NNN-name.sh` in the matching range. Start it with `#!/usr/bin/env bash` and `set -euo pipefail`, make it idempotent (it runs again on every `dots init`) and executable (git tracks the mode), then stage it.
- `.init.sh` and everything in `.config/yadm/` run under macOS's `/bin/bash` 3.2 on a fresh machine, before Homebrew's bash exists: no associative arrays, `mapfile` or `${var,,}`.
- Never run `yadm bootstrap` or `dots init` as an agent. They prompt for the sudo password, rebuild the Dock and uninstall software.

## Per-machine setup

- The git-crypt key at `~/.git-crypt` before the first run ([yadm.md](yadm.md)).
- Sign in to the App Store before `brew bundle` installs the `mas` apps.
- Everything else that bootstrap can't do is listed in the doc of each component.
