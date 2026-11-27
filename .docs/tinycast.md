# Tinycast

[Tinycast](https://tinycast.dev) (`cask "tinycast"`, bundle ID `com.abueammar.tinycast`) is the launcher. It runs Raycast extensions and imports Raycast script commands.

## Files

| Path | Tracked | Managed by | Purpose |
|---|---|---|---|
| `.config/tinycast/settings.json` | yes | app | Tinycast's "Sync settings file": preferences, aliases of apps, commands and system actions, window management |
| `.config/tinycast-scripts/*.sh` | yes | manual | Script commands, one self-contained file per command |
| `.config/yadm/bootstrap.d/030-tinycast-extensions.sh` | yes | manual | Builds and installs custom extensions |
| `~/Library/Application Support/com.abueammar.tinycast/` | no | app | Installed extensions, snippets, quicklinks, notes, clipboard history |
| Tinycast's preferences (`defaults read com.abueammar.tinycast`) | no | app | Imported script commands and other custom commands, in `customCommands` |
| `~/.local/share/tinycast-extensions/` | no | bootstrap | Checkouts of the custom extensions |
| `~/.cache/burp-chrome/`, `~/.local/share/burp-chrome/profiles/` | no | app | `burp-chrome.sh`: Burp's CA, and the persistent Chrome profiles |
| `/tmp/pk-passkeys-tools-cache/`, `/tmp/pk-*` | no | app | `passkeys-tools.sh`: the Chrome for Testing download, and each run's profile, wiped when its browser closes |

## How it works

- `settings.json` is turned on in Settings → Backup → Settings File. Tinycast rewrites it whenever a setting changes, and applies edits to it at once. It can't turn on features that need consent (Extensions, Snippets, Calendar, …).
- Deeplinks: `tinycast://` opens the launcher (a second link doesn't close it, unlike a hotkey), `tinycast://command/<id>` runs a built-in command and `tinycast://extensions/<author>/<extension>/<command>` an extension command. "Copy Deeplink" (⇧⌘C) in the launcher shows any row's link. Karabiner opens them with `open -g` ([karabiner.md](karabiner.md)). Tinycast asks once before it runs a link that carries text (`fallbackText`), and it also claims `raycast://` links.
- Shortcuts are Karabiner bindings that open deeplinks: `rules/tinycast.ts` for those with modifiers, the `r` simlayer for the rest ([karabiner.md](karabiner.md)). The launcher is the exception, because only a hotkey also closes it: Tinycast's Show Launcher (Settings → General) is ⌃⌥⇧⌘F19, a combo no keyboard has, and Karabiner sends it for left ⌘Space. Tinycast binds no other hotkeys.
- Store extensions are installed in Settings → Extensions, which searches the Raycast Store. Custom extensions live in their own repos; bootstrap step `030` builds each with `ray build` into `~/Library/Application Support/com.abueammar.tinycast/extensions/<manifest name>`. Tinycast loads extensions at launch and when Settings → Extensions opens.
- Script commands: Tinycast doesn't watch the folder. Settings → Commands → Import Raycast Scripts turns each script into a custom command that runs `/usr/bin/env bash '<absolute path>'`, so moving or renaming a script breaks its command. Importing again adds only titles it doesn't have yet. Tinycast reads only `title`, `mode` (`compact` and `fullOutput` show the output), `needsConfirmation`, `currentDirectoryPath` and `argument1`–`argument3` (the placeholder names the field); dropdown and password arguments become plain text fields.
- Tinycast keeps the commands in its preferences, not in `settings.json`: `customCommands` holds a JSON array with each command's id, name, command line, arguments (name and `isOptional`) and output and confirmation flags. A command runs its script file, so a change to the script's code applies on the next run. The metadata is copied at import, so a changed title, mode or argument needs the command edited in Settings → Commands, or its entry in `customCommands` rewritten while Tinycast is quit. Deleting and importing it again gives it a new id, which drops its hotkey.
- Commands run with launchd's PATH, which [bootstrap](bootstrap.md) step `002` sets to include Homebrew (bash 5, `http`, `wg`, `node`).

## Changing it

- Change preferences in Tinycast; review and stage the rewritten `settings.json`.
- Bind shortcuts in Karabiner, never in Tinycast: copy the row's deeplink and add it to `rules/tinycast.ts` or the `r` simlayer.
- To add a custom extension, append its SSH URL to `extensions` in `030-tinycast-extensions.sh`.
- New script commands follow the existing ones:
  - A metadata header right after the shebang: `@raycast.schemaVersion 1`, `title`, `mode`, `description` and `argumentN` JSON. Other Raycast fields (icon, packageName, author) are ignored by Tinycast, so leave them out.
  - `set -euo pipefail`, required commands checked up front, clear errors on stderr.
  - Configuration **only** from environment variables, each with an inline default and a short comment, e.g. `proxy="${BURP_PROXY:-127.0.0.1:8080}"  # Burp proxy listener`. Caches go to `~/.cache/<name>`, persistent data to `~/.local/share/<name>`, never into this folder. A large download that is cheap to fetch again may go to `/tmp`, which macOS clears at reboot, like the ~170 MB Chrome for Testing of `passkeys-tools.sh`.
  - Tinycast has no dropdowns: write a choice as a text argument whose placeholder lists the values (`Browser: chrome · canary · dev · beta`), and resolve it with the script's own `choose` function, which takes any unique prefix in any case.
  - Stay executable.
  - One self-contained script per command: no shared libraries or helper files; embedded helper code (JavaScript, …) stays in a heredoc.

## Per-machine setup

- Turn on the settings file (Settings → Backup → Settings File). With the file already present, Tinycast asks whether to import or replace it: import.
- Turn on Extensions, Snippets, Calendar and the other consent-gated features.
- Import the script commands once (Settings → Commands → Import Raycast Scripts).
