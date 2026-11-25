# Karabiner-Elements

Every keybinding lives here, including all of OmniWM's ([omniwm.md](omniwm.md)). The config is TypeScript written with [karabiner.ts](https://karabiner.ts.evanliu.dev/) for a German Mac keyboard; a build turns it into Karabiner's JSON and into the generated parts of OmniWM's settings.

## Files

| Path | Tracked | Managed by | Purpose |
|---|---|---|---|
| `.config/karabiner-config/src/` | yes | manual | The sources, see below |
| `.config/karabiner-config/package.json`, `package-lock.json`, `tsconfig.json` | yes | manual | Build setup; `npm run update` rewrites the lock file |
| `.config/karabiner-config/node_modules/` | no | npm | Dependencies |
| `.config/karabiner/karabiner.json` | yes | hybrid | The build writes the rules of "Default profile"; Karabiner's Settings window writes devices, function keys and global settings |
| `.config/karabiner/automatic_backups/` | no | app | Karabiner's backups |
| `/Library/Application Support/org.pqrs/config/karabiner_environment` | no | build | PATH for shell commands, written by [bootstrap](bootstrap.md) step `002` |

| Source | Purpose |
|---|---|
| `src/index.ts` | Entry point: builds, checks, then writes both outputs |
| `src/rules/` | Bindings with modifiers, one file per area (system, omniwm, apps, workspaces, scratchpads, windows, displays, utm); the order in `rules/index.ts` is their priority |
| `src/layers/` | Simlayers, one file per trigger key, registered in `layers/index.ts` |
| `src/keys.ts` | `deKey()` (German key labels → US key codes) and the modifier constants (`hyper`, `lCmdHyper`, `rCmd`, …) |
| `src/commands.ts` | Builders for the shell commands bindings run: `omniwm()`, `omniwmHelper()`, `tinycast()`, `tinycastExtension()`, `systemSettings()`, `notify()`, … |
| `src/apps.json`, `apps.ts`, `workspaces.ts` | Workspace keys, and each app's workspace and key, see [omniwm.md](omniwm.md#workspaces-and-apps) |
| `src/conflicts.ts` | Fails the build when two bindings share a trigger and conditions |
| `src/karabiner-json.ts` | Writes the rules into `karabiner.json` |
| `src/omniwm-settings.ts`, `src/toml.ts` | Write `[[workspaces]]` and the generated `[[appRules]]` into OmniWM's `settings.toml` |
| `src/config.ts` | Output paths, overridable with `KARABINER_JSON`, `KARABINER_PROFILE`, `OMNIWM_SETTINGS` |

## How it works

- Hyper is Caps Lock, mapped to right ⌘⌥⌃⇧. Rules tell left and right modifiers apart, so a left modifier on top of Hyper gives a separate set of bindings. Karabiner applies the first matching rule.
- Simlayers: hold one key and press another. Each trigger key has exactly one simlayer: `a` OmniWM, `k` Karabiner, `s` symbols, `o` Ollama, `r` Tinycast, space (navigation and programming symbols), `,` System Settings, `.` emoji.
- Shell commands run with `/bin/sh` and the PATH from `karabiner_environment`. Tinycast deeplinks open with `open -g`, so the app in front keeps focus.
- The build (`npm run build`) type-checks with `tsc`, builds the OmniWM helper with Go (`npm run helper`, see [omniwm.md](omniwm.md#helper)), then runs `node src/index.ts`. Node runs the TypeScript natively, so local imports carry their `.ts` extension and only erasable syntax is allowed (`tsconfig.json` enforces both). It stops before writing anything when type checking fails, the helper doesn't build, `apps.json` is invalid or two bindings conflict, and it writes each output only when it changed. karabiner.ts's own `writeToProfile()` can't be used: its ES module build calls `require()`.
- TypeScript stays on 6 because the `typescript-lsp` plugin needs `tsserver` ([claude-code.md](claude-code.md)).

## Changing it

- Wrap every key in `deKey()`, reuse the modifier constants and the command builders, and add bindings to the file of their area. To use a simlayer trigger that's taken, add to its file in `src/layers/`.
- Build with `npm run build` in `~/.config/karabiner-config`, then stage the sources and both outputs together. Never edit the rules in `karabiner.json` or the generated parts of `settings.toml` by hand.
- Test build without touching the live configs: point `KARABINER_JSON` and `OMNIWM_SETTINGS` at copies.
- `npm run update` updates packages within their ranges and rewrites `package-lock.json`; a new major version needs `npm install <package>@latest`. The `k` simlayer's `r` updates and rebuilds; its output is lost, so run the build in a terminal to see why one failed.

## Per-machine setup

- Grant Accessibility to `/Library/Application Support/org.pqrs/Karabiner-Elements/Karabiner-Console-User-Server.app`, which runs the shell commands. Without it `toPaste()` (the symbols and emoji layers, `t` and `c` in the space layer) fails with `osascript is not allowed to send keystrokes (1002)` in `~/.local/share/karabiner/log/console_user_server.log`. A grant for the older `bin/karabiner_console_user_server` path is stale.
- The usual Karabiner-Elements driver and Input Monitoring approvals.
