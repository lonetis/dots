# CLAUDE.md — dots

Personal macOS dotfiles (Apple Silicon, Homebrew under `/opt/homebrew`, German keyboard layout), managed with [yadm](https://yadm.io) and published at `github.com/lonetis/dots`. **The repo is public.** Anyone can read every tracked file except the ones git-crypt encrypts.

## Version control (yadm)

yadm wraps git. The repo is at `~/.local/share/yadm/repo.git` and its work tree is `~`. There is no `~/.git`, so plain `git` in `~` doesn't see this repo (`GIT_CEILING_DIRECTORIES=$HOME` also stops git from searching upward). Use `yadm <git-subcommand>` for everything.

### Rules

- **Stage every change, and never commit.** After you create, edit, rename or delete a tracked file, stage it. Don't run `yadm commit`, `yadm push`, `dots commit`, `dots push` or `dots save`. The user reviews, commits and pushes.
- **The commit message is always exactly `update`.** If the user explicitly asks for a commit, run `dots commit` (which is `yadm commit -m "update"`). Don't add Conventional Commit prefixes, emoji, a body or any `Co-authored-by` trailer. The `code:git` skill doesn't apply to this repo.
- **Stage explicit file paths, never directories or globs.** `.gitignore` is `*`, so new files need `-f`, and `-f` also bypasses `.gitignore_global`. Running `yadm add -f` on a directory would pull in `node_modules/`, `.DS_Store`, Claude Code transcripts and similar files.
- **Never stage secrets as plaintext.** See [Secrets](#secrets-git-crypt).
- Commits are SSH-signed through 1Password (`op-ssh-sign`), and pushes use the 1Password SSH agent. Both can need the user to unlock 1Password, which is one more reason to leave them to the user.

### Commands

| Task | Command |
|---|---|
| Show status (untracked files are hidden) | `yadm status` |
| List tracked files / check if a file is tracked | `yadm list -a` / `yadm ls-files --error-unmatch <path>` |
| Review changes | `yadm diff`, `yadm diff --cached` |
| Stage a new file | `yadm add -f -- <path>` (same as `dots add <path>`) |
| Stage edits to tracked files | `yadm add -- <path>` for files directly in `~`, `yadm add -f -- <path>` for files inside a directory (`.gitignore` ignores the directory itself), or `yadm add -u` for all tracked files, deletions included |
| Rename or move | `yadm mv <old> <new>` |
| Delete a file and stage the deletion | `yadm rm <path>` |
| Stop tracking but keep the file | `yadm rm --cached <path>` |
| List encrypted files | `yadm git-crypt status -e` |

`dots` (`.bin/dots`) wraps the user's own workflow: `status`, `diff` (the interactive `hunk` TUI), `edit` (opens `~` in VS Code with the yadm repo), `add`, `commit`, `push`, `save` (`add -u`, commit `update`, push) and `init` (re-runs `.init.sh`). As an agent, use the plain `yadm` commands above. Avoid the interactive subcommands, and don't use the commit or push subcommands unless the user asks.

### Secrets (git-crypt)

Paths marked `filter=git-crypt diff=git-crypt` in `.gitattributes` are encrypted on the remote and decrypted transparently in the local checkout. The key is `~/.git-crypt`, and bootstrap step `000` unlocks it. The encrypted files are currently `.ssh/config` and `.git-repos`.

- Never copy anything from an encrypted file into a plaintext file, a commit message or this CLAUDE.md.
- To track a new sensitive file, add its path to `.gitattributes` *before* you stage the file. Then stage both and check that `yadm git-crypt status -e` lists the file. A file that was already committed as plaintext stays readable in the history. Tell the user if that happens.
- Every other file is public. Don't write tokens, API keys, private hostnames or IPs, internal URLs or private repo names into unencrypted files. Read secrets from the environment or from 1Password (`op`) at runtime instead.

## Layout

```
~
├── README.md                      # user-facing: bootstrap instructions only
├── CLAUDE.md                      # this file
├── .init.sh                       # curl|bash installer → Homebrew, yadm, git-crypt, clone, bootstrap
├── .Brewfile                      # all installed software (see Homebrew)
├── .bin/                          # personal scripts on PATH: dots, model*
├── .zprofile, .zshrc              # zsh: env + PATH / colors + integrations + aliases
├── .gitconfig, .gitignore_global
├── .gitignore                     # `*`: ignore all of $HOME; tracking is opt-in via `yadm add -f`
├── .gitattributes                 # git-crypt file list
├── .git-repos                     # 🔒 git-get dump of ~/repos (one "url branch" per line)
├── .ssh/config                    # 🔒
├── .claude/                       # Claude Code: settings.json only
├── .vscode/settings.json          # makes `code ~` usable: hides non-dot entries, watches only dotfiles
└── .config/
    ├── yadm/                      # bootstrap + bootstrap.d/NNN-*.sh
    ├── ccstatusline/settings.json # Claude Code status line layout
    ├── git/allowed_signers        # SSH keys git trusts when verifying commit signatures
    ├── karabiner-config/          # karabiner.ts sources (TypeScript)
    ├── karabiner/karabiner.json   # GENERATED from karabiner-config
    ├── omniwm/                    # OmniWM tiling WM: settings.toml (partly GENERATED) + scripts/ helpers
    └── raycast-scripts/           # Raycast script commands + icons/
```

## Bootstrap

`.init.sh` installs Homebrew, yadm and git-crypt. On a fresh machine it clones over HTTPS, switches `origin` to SSH and runs bootstrap. On an existing machine it runs `yadm pull` and `yadm bootstrap` instead. The README pipes it through curl, and `dots init` re-runs it.

`.config/yadm/bootstrap` asks for the admin password once. It exports a `SUDO_ASKPASS` helper and keeps the sudo timestamp fresh, so steps can call plain `sudo`. Then it runs every executable file in `bootstrap.d/` in sort order and stops at the first failure. It skips files whose names contain `##` or end in `~`.

| Prefix | Purpose |
|---|---|
| `000–009` | Prerequisites and system settings (git-crypt unlock, `defaults write`, Karabiner PATH) |
| `010–019` | Homebrew (install, update, bundle, cleanup) |
| `020–029` | Dock layout (`dockutil`) |
| `030–039` | Apps built from source (custom Raycast extensions) |

To add a step, create `bootstrap.d/NNN-name.sh` in the matching range. Start it with `#!/usr/bin/env bash` and `set -euo pipefail`, and make it idempotent, because it runs again on every `dots init`. Make it executable (git tracks the mode), then stage it.

- `.init.sh` and everything in `.config/yadm/` run under macOS `/bin/bash` 3.2 on a fresh machine, before Homebrew bash exists. Don't use bash 4+ features there (associative arrays, `mapfile`, `${var,,}`).
- **Don't run `yadm bootstrap` or `dots init` yourself.** They prompt for the sudo password and rebuild the Dock. `012-brew-bundle.sh` also runs `brew bundle cleanup --force`, which uninstalls everything that isn't in `.Brewfile`.

## Homebrew (`.Brewfile`)

This file is the single source of truth for installed software: taps, formulae, casks, Mac App Store apps (`mas`), VS Code extensions (`vscode`), Go binaries (`go`) and global npm packages (`npm`). Bootstrap installs it with `brew bundle install --global` and then **removes everything not listed**. Anything installed by hand has to be added here, or it disappears on the next bootstrap.

When you add entries, keep the existing format: a `# description` comment above each formula and cask, sections ordered taps, brews, tap-qualified brews, casks, mas, vscode, go, npm, and alphabetical order inside each section. Homebrew has disabled `brew bundle dump --describe`, so take each description from `brew desc <name>` (or `brew desc --cask <name>`). To find what's missing, compare a plain `brew bundle dump --file=<tmp>` with `.Brewfile`, or run `brew bundle cleanup --global` without `--force`, which only lists what bootstrap would remove.

## Keyboard and window management

Karabiner-Elements and [OmniWM](https://omniwm.app) work as one system. **Every keybinding lives in Karabiner.** OmniWM's own hotkeys are off (`general.hotkeysEnabled = false`, every binding `"Unassigned"`). Karabiner drives OmniWM through `omniwmctl` calls and the helper scripts in `.config/omniwm/scripts/`. OmniWM also replaces the former SketchyBar bar and JankyBorders borders with its own workspace bar and focus border.

### Karabiner (`.config/karabiner-config/`)

- The config is written in TypeScript with [karabiner.ts](https://karabiner.ts.evanliu.dev/). `src/index.ts` is the entry point and lists the layout. Bindings with modifiers live in `src/rules/`, one file per area (system, omniwm, apps, workspaces, windows, displays, utm). Karabiner applies the first match, so the order in `rules/index.ts` is their priority. Simlayers live in `src/layers/`, one file per trigger key, registered in `layers/index.ts`.
- `src/keys.ts` translates German key labels to US key codes, so wrap every key in `deKey()`. It also holds the modifier constants (`hyper`, `lCmdHyper`, `rCmd`, …). Reuse them, because rules tell left and right modifiers apart. `src/commands.ts` builds the shell commands that bindings run (`omniwm()`, `omniwmScript()`, `raycast()`, `systemSettings()`, `notify()`, …). Use these builders instead of writing command strings inline.
- Hyper is Caps Lock, mapped to right ⌘⌥⌃⇧. Simlayers (hold one key, press another) group related actions. Each trigger key gets exactly one simlayer, so to use a key that's already taken, add the mappings to its file in `src/layers/`.
- To build, run `npm run build` in `~/.config/karabiner-config`. It type-checks with `tsc` and then runs `node src/index.ts`. Node runs the TypeScript natively, without tsx, so local imports carry their `.ts` extension and only erasable syntax is allowed (`tsconfig.json` enforces both). TypeScript stays on 6 because the `typescript-lsp` plugin needs `tsserver`. The build stops before writing anything when type checking fails, when `apps.json` is invalid, or when two bindings share a trigger and conditions (`src/conflicts.ts`). `npm run update` updates every package within its version range and changes `package-lock.json`. A new major version needs `npm install <package>@latest`. `node_modules/` is untracked.
- For a test build, point `KARABINER_JSON`, `KARABINER_PROFILE` and `OMNIWM_SETTINGS` at copies (defaults in `src/config.ts`).
- The build writes **two tracked, generated outputs**, and each only when something changed:
  1. the "Default profile" rules in `~/.config/karabiner/karabiner.json`, which Karabiner applies immediately. `src/karabiner-json.ts` writes the file, because karabiner.ts's own `writeToProfile()` calls `require()` in its ES module build and fails under native Node.
  2. the `[[workspaces]]` array and the generated `[[appRules]]` in `~/.config/omniwm/settings.toml` (`src/omniwm-settings.ts`, which parses the file with `smol-toml`, and `src/toml.ts`, which writes OmniWM's canonical layout). It rewrites only those two arrays and leaves every other setting alone. It recognises the app rules it generated by their id, a UUID derived from the bundle ID, and keeps all other rules. Skipping unchanged writes matters here, because every write makes OmniWM reload and drop runtime workspace moves.

  Never edit the generated parts by hand. Edit the sources, build, and then stage the sources and outputs together.

### Workspaces and the app-to-workspace mapping

Workspace keys are `1–9`, `0`, `a–z` and `ä ö ü`, in that order. OmniWM only accepts positive integers as workspace names, so the key at position *i* of `workspaceKeys` in `src/workspaces.ts` becomes workspace `i + 1` with the upper-case key as its `displayName` (`1` → `1`, `0` → `10`, `a` → `11`/`A`, `ü` → `39`). Native `omniwmctl` calls in the rules get the number from `workspaceName(key)` at build time (Hyper plus a digit runs `omniwmctl command switch-workspace <number>`). The scripts take keys and look workspaces up by display name. Only append to `workspaceKeys`, because inserting a key renumbers every workspace after it, and OmniWM keeps open windows on their workspace *number* when it reloads, so after a renumbering every window shows up under a different key until it is moved back. New workspaces get the home monitor `main`, except `4–6` (`secondary`) and `7–9` (`tertiary`); a home changed later in OmniWM's Settings window survives the build.

`src/apps.json` maps workspace keys to bundle IDs and is the single source of truth. A key takes one bundle ID or a list of them (`"t": ["com.superlogical.rex", "com.mitchellh.ghostty"]`), so several apps can share a workspace. A bundle ID may appear under one key only, because that key is its default workspace; `src/apps.ts` fails the build otherwise. Three things read it:

- Karabiner: Hyper plus a key cycles through the windows of all its apps or launches the first one in the list, and ⌃+Hyper plus a key pulls one of their windows to the workspace under the pointer.
- The generated `assignToWorkspace` app rules in `settings.toml`, one per bundle ID. OmniWM applies them only while the app has no windows, so an app's first window lands on its workspace and later windows open on the active one.
- `move-to-default.sh` and `move-all-to-default.sh` in `.config/omniwm/scripts/`, at runtime. Apps that aren't mapped fall back to workspace `q`.

To change a mapping, find the bundle ID with `mdls -name kMDItemCFBundleIdentifier -r /Applications/<App>.app`, edit `apps.json`, build, and stage `apps.json`, `karabiner.json` and `settings.toml`.

### OmniWM (`.config/omniwm/`)

- `settings.toml` is OmniWM's whole configuration. OmniWM reloads it on save and rewrites it in canonical form (sorted keys, no comments) whenever something changes in its Settings window, so it often shows up as modified; review and stage it like `.claude/settings.json`. Validation is strict: a missing key, an unknown enum value or a duplicate hotkey id rejects the whole file. Change values in place and never delete keys.
- Values the Karabiner setup relies on: hotkeys off, `ipcEnabled = true` (`omniwmctl` needs it), `niri.moveWindowStacksIntoColumn = false` (the move keys swap columns and the join keys consume or expel), ⌃⌘-drag to move or resize tiled windows (like `NSWindowShouldDragOnGesture` in bootstrap `001`), `workspaceBar.hideEmptyWorkspaces = true` (39 workspaces exist), `quakeTerminal.enabled = true` with `provider = "ghostty"` (left ⌘⌥⏎ toggles OmniWM's built-in Ghostty quake terminal) and the floating-window app rules. Everything else (gaps, border, animations, gestures, default layout) is plain preference, usually changed in OmniWM's Settings window.
- The bar is OmniWM's default OmniShell style: a full-width bar over the top edge that replaces the macOS menu bar (OmniWM sets the menu bar to auto-hide and restores the previous choice when it quits). The style's own `[workspaceBar]` in `shell/default/shell.toml` overrides the matching `settings.toml` keys (position, height, full width, reserved space, labels, stats button). To change those, put `[profiles.default.workspaceBar]` in a top-level `shell/shell.toml` and track that file.
- `routing.arrangements` holds the monitor grid from OmniWM's Monitor Setup, keyed by this machine's display UUIDs.
- The rest of `shell/` (OmniWM-managed profiles, widgets and type definitions, updated with each release) is untracked. Track only files you add there. Runtime state lives in `~/.local/state/omniwm` and is untracked too.
- Bindings use a native `omniwmctl` command whenever one does the job. `scripts/` holds one bash script per action that needs state or several calls, named after the action (`cycle.sh`, `summon.sh`, `close-others.sh`, …), plus `lib.sh`, which they all source. They need bash 5 and `jq` (`/usr/bin/jq` ships with macOS). They cycle, pull and toggle app windows, summon a workspace to the display under the pointer (swapping it with the workspace shown there when it's visible elsewhere), move windows and workspaces between displays with wrap-around, send windows to their app's workspace, and close other windows. `omniwmctl command move-to-workspace` doesn't make focus follow the window, so `move-window.sh` moves it by id and then navigates to it. OmniWM moves a workspace only to an *adjacent* monitor (`omniwmctl workspace move-to-monitor --force`, a runtime override that a settings reload clears). So `lib.sh` reads the routing grid from `settings.toml` with `awk` (which relies on OmniWM's canonical layout), finds the route with jq, hops along it, and restores what the displays in between showed. The scripts read and move the pointer through `osascript -l JavaScript` (AppKit and CoreGraphics). They keep the pull state in `~/.local/state/omniwm-helper`, take their configuration from `OMNIWM_*` environment variables (defaults at the top of `lib.sh`), and report errors on stderr with exit code 1. `cycle.sh` also exits 1 when the app has no windows, so Karabiner launches it.
- Setup that isn't in the repo, per machine: grant OmniWM Accessibility and Input Monitoring, turn on Start at Login in its Settings (macOS manages that, not `settings.toml`), keep "Displays have separate Spaces" on, and run Monitor Setup when the displays change.
- Changes to `settings.toml` apply on save. The `a` simlayer opens the folder (`c`) and restarts OmniWM (`r`).

## Raycast (`.config/raycast-scripts/`)

Each `*.sh` file is a Raycast script command. Raycast's own settings aren't tracked. New scripts follow the existing ones:

- They have a Raycast metadata header: `@raycast.schemaVersion 1`, `title`, `mode`, `icon icons/<name>.svg`, `packageName me.louisjannett.raycast.<name>`, `description`, `author`, and `argumentN` JSON.
- They start with `#!/usr/bin/env bash` and `set -euo pipefail`, check required commands up front, and print clear errors to stderr.
- They take configuration **only** from environment variables, each with an inline default and a short comment, for example `proxy="${BURP_PROXY:-127.0.0.1:8080}"  # Burp proxy listener`.
- They're executable. Stage the icon SVG together with the script.

Custom Raycast extensions live in their own repos. `bootstrap.d/030-raycast-extensions.sh` builds and installs them. To add one, append its SSH URL to the `extensions` array.

## Claude Code (`.claude/`)

- Only `.claude/settings.json` is tracked. Claude Code rewrites it itself, so it often shows up as modified. Nothing else under `~/.claude` (transcripts, memory, plugins, projects) is tracked, and nothing else there may be added.
- There is no global `~/.claude/CLAUDE.md`. My coding conventions come from the skills of the `code` plugin, which Claude loads when they apply.
- Claude Code loads every `CLAUDE.md` from the session's directory upward, so it would load this file in every project below `~`. `settings.json` excludes it everywhere with `claudeMdExcludes`, and a SessionStart hook tells Claude to read it when a session starts in `~` or in a dot-directory that yadm tracks files in, such as `~/.config/karabiner-config` (`yadm ls-files --error-unmatch -- "$CLAUDE_PROJECT_DIR"`). The hook points to the file instead of printing it, because Claude Code cuts hook output off at 10,000 characters.
- `permissions.defaultMode` is `bypassPermissions`, which still enforces deny rules. `permissions.deny` blocks the commands this file forbids: `yadm commit`, `yadm push`, `dots push`, `dots save`, `yadm bootstrap`, `dots init` and `brew bundle cleanup` with `--force`. `dots commit` stays allowed for when the user asks for a commit. A rule that ends in ` *` also matches the bare command.
- `preferredNotifChannel` is `ghostty`, which sends desktop notifications as OSC 777. Both Ghostty and Rex show them. The default `auto` picks a channel from `TERM_PROGRAM`, doesn't recognize Rex (`TERM_PROGRAM=rex`) and sends nothing there.
- The `code-review` and `code-simplifier` plugins are disabled because they duplicate the built-in `/code-review` and `/simplify` and the `pr-review-toolkit:code-simplifier` agent. The three browser plugins (Playwright, Chrome DevTools, Claude in Chrome) overlap too, but all three are in use.
- The `typescript-lsp` plugin runs `typescript-language-server` (`brew "typescript-language-server"`). That server needs a TypeScript that ships `tsserver`, so it only works in projects whose `node_modules` has TypeScript 6 or older. TypeScript 7, which is the global `brew "typescript"`, dropped `tsserver`.
- The status line is [ccstatusline](https://github.com/sirmalloc/ccstatusline), installed globally through `npm "ccstatusline"` in `.Brewfile` (not `npx`, which is slower on every render) and set as the `statusLine` command in `settings.json`. Updates come from `brew bundle` or `npm update -g ccstatusline`. Its layout lives in `.config/ccstatusline/settings.json`: one row with model, effort, permission mode, ultracode, context (against the auto-compaction point), session cost, the 5h and weekly limits with their reset times, the weekly Fable limit, and git. Running `ccstatusline` without stdin opens its TUI editor, which rewrites that file.
- ccstatusline has no widget for permission mode or ultracode, and the statusLine JSON doesn't carry either. Two `custom-command` widgets read them from the session transcript (`transcript_path`): the last `permissionMode` and the last `ultra_effort_enter`/`ultra_effort_exit` attachment. Both update with the next prompt, not on Shift+Tab or `/effort`. The ultracode widget prints nothing while ultracode is off, so it and its separator disappear.
- To test a layout, pipe in a captured statusLine JSON: `ccstatusline --config <file> < input.json`.

## Shell and scripts

- `.zprofile` holds environment variables and PATH entries, grouped under `# ===` section banners with a `# Category: what` comment above each entry. `.zshrc` holds the Apple HIG color palette, shell integrations (zsh-autosuggestions, completions) and aliases. The palette is four associative arrays of hex values (`hig_light`, `hig_dark`, `hig_light_contrast`, `hig_dark_contrast`) keyed by color name (`red` … `brown`, `gray` … `gray6`), for `%F{$hig_dark[red]}` in prompts and `fg=$hig_dark[gray]` in highlight styles.
- `~/.bin` is on PATH through `.zprofile`. Karabiner shell commands get their PATH from `/Library/Application Support/org.pqrs/config/karabiner_environment`, which bootstrap `002` writes. A directory that Karabiner commands need must go in both places.
- `.bin/model -m chatgpt|pcc|local` pipes a prompt into the macOS Shortcut of the same name and converts the result to plain text. The Shortcuts aren't in the repo.
- `/usr/bin/env bash` resolves to Homebrew bash 5 (`brew "bash"` in `.Brewfile`), so scripts outside bootstrap may use bash 4+ features. If you remove that entry, check those scripts first (for example `declare -A` in `raycast-scripts/burp-chrome.sh` and `inherit_errexit` in `omniwm/scripts/lib.sh`).

## Other tracked config

- `.gitconfig`: identity, SSH commit signing through 1Password, and git-get with root `~/repos`, which clones repos to `~/repos/<host>/<path>`. `.git-repos` is the matching git-get dump. Restore it with `git get --dump ~/.git-repos` and refresh it with `git list --out dump > ~/.git-repos`.
- `.config/git/allowed_signers` lists the SSH keys git trusts when it verifies commit signatures: my 1Password key under my email, and the agent key `~/.ssh/agent-commit-signing` under the principal `agent-commit-signing`, so `%GS` tells agent commits apart. When a machine gets a new agent key, add its public key there.
- `.vscode/settings.json` holds workspace settings for `code ~`. VS Code's git extension finds no `~/.git`, so `dots edit` launches it with `GIT_DIR` and `GIT_WORK_TREE` pointing at the yadm repo. Because `.gitignore` is `*`, the explorer then greys out every untracked file and every folder without tracked files. The settings keep untracked files out of Source Control (`git status -uno`, so git never scans `$HOME`) and remove both variables from the integrated terminal, so plain `git` there still works on other repos. VS Code passes the variables only to the window `dots edit` opens; a `~` window it restores after a restart lacks them, so close it and run `dots edit` again. `files.watcherExclude` excludes non-dot entries and busy dot folders without tracked files (caches, `.claude/*/`, `.vscode/extensions`, `.local/share` except `yadm`). The git extension refreshes from a watcher on the yadm repo dir, so never exclude `.local/share/yadm`. If a new dot folder churns, add it there.

## Conventions

- The work tree is the live `$HOME`, so edits take effect immediately. The only build step is Karabiner's `npm run build`. After a change, reload the affected tool. Don't run `brew bundle` or bootstrap unless the user asks.
- To add config for a new tool:
  1. Put it under `~/.config/<tool>/` when the tool supports that.
  2. Make sure the tool is in `.Brewfile`.
  3. Stage the explicit config files, never caches or state.
  4. If setup needs more than files (`defaults`, `sudo`, a build), add a `bootstrap.d` step.
  5. Add the tool to [Layout](#layout), and give it a section here if it isn't trivial.
- Of the `code` plugin's skills, only `code:conventions` applies here.
- `README.md` stays user-facing and covers bootstrap only. Update this CLAUDE.md whenever a component, convention or flow changes, and stage it with the change.
