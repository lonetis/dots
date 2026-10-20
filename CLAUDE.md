# CLAUDE.md — dots

> **Scope:** this file is for the dotfiles in `$HOME` that yadm tracks. Claude Code also loads it in every project below `~` (for example `~/repos/...`). When you work in one of those projects, ignore this file. Its git rules apply only to `yadm`, never to other repositories.

Personal macOS dotfiles (Apple Silicon, Homebrew under `/opt/homebrew`, German keyboard layout), managed with [yadm](https://yadm.io) and published at `github.com/lonetis/dots`. **The repo is public.** Anyone can read every tracked file except the ones git-crypt encrypts.

## Version control (yadm)

yadm wraps git. The repo is at `~/.local/share/yadm/repo.git` and its work tree is `~`. There is no `~/.git`, so plain `git` in `~` doesn't see this repo (`GIT_CEILING_DIRECTORIES=$HOME` also stops git from searching upward). Use `yadm <git-subcommand>` for everything.

### Rules

- **Stage every change, and never commit.** After you create, edit, rename or delete a tracked file, stage it. Don't run `yadm commit`, `yadm push`, `dots commit`, `dots push` or `dots save`. The user reviews, commits and pushes.
- **The commit message is always exactly `update`.** If the user explicitly asks for a commit, run `dots commit` (which is `yadm commit -m "update"`). Don't add Conventional Commit prefixes, emoji, a body or any `Co-authored-by` trailer. The git guidelines in `~/.claude/CLAUDE.md` don't apply to this repo.
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
| Stage edits to tracked files | `yadm add -- <path>`, or `yadm add -u` for all tracked files, deletions included |
| Rename or move | `yadm mv <old> <new>` |
| Delete a file and stage the deletion | `yadm rm <path>` |
| Stop tracking but keep the file | `yadm rm --cached <path>` |
| List encrypted files | `yadm git-crypt status -e` |

`dots` (`.bin/dots`) wraps the user's own workflow: `status`, `diff` (the interactive `hunk` TUI), `edit` (opens `~` in VS Code), `add`, `commit`, `push`, `save` (`add -u`, commit `update`, push) and `init` (re-runs `.init.sh`). As an agent, use the plain `yadm` commands above. Avoid the interactive subcommands, and don't use the commit or push subcommands unless the user asks.

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
├── .zprofile, .zshrc              # zsh: env + PATH / integrations + aliases
├── .gitconfig, .gitignore_global
├── .gitignore                     # `*`: ignore all of $HOME; tracking is opt-in via `yadm add -f`
├── .gitattributes                 # git-crypt file list
├── .git-repos                     # 🔒 git-get dump of ~/repos (one "url branch" per line)
├── .ssh/config                    # 🔒
├── .claude/                       # Claude Code: CLAUDE.md (global instructions) + settings.json only
├── .vscode/settings.json          # makes `code ~` usable: hides non-dot entries, disables file watching
└── .config/
    ├── yadm/                      # bootstrap + bootstrap.d/NNN-*.sh
    ├── karabiner-config/          # karabiner.ts sources (TypeScript)
    ├── karabiner/karabiner.json   # GENERATED from karabiner-config
    ├── aerospace/                 # AeroSpace tiling WM: aerospace.toml + helper scripts
    ├── sketchybar/                # SketchyBar status bar (Lua)
    ├── borders/bordersrc          # JankyBorders window borders
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

This file is the single source of truth for installed software: taps, formulae, casks, Mac App Store apps (`mas`), VS Code extensions (`vscode`) and global npm packages (`npm`). Bootstrap installs it with `brew bundle install --global` and then **removes everything not listed**. Anything installed by hand has to be added here, or it disappears on the next bootstrap.

When you add entries, keep the format that `brew bundle dump --describe` writes: a `# description` comment above each formula and cask, sections ordered taps, brews, tap-qualified brews, casks, mas, vscode, npm, and alphabetical order inside each section.

## Keyboard and window management

Karabiner-Elements, AeroSpace and SketchyBar work as one system. **Every keybinding lives in Karabiner.** AeroSpace has no bindings of its own. Karabiner drives it through `aerospace` CLI calls and the scripts in `.config/aerospace/`.

### Karabiner (`.config/karabiner-config/`)

- The config is written in TypeScript with [karabiner.ts](https://karabiner.ts.evanliu.dev/). `src/index.ts` holds all rules. `src/de_key.ts` translates German key labels to US key codes, so wrap every key in `de_key()`. Reuse the modifier constants at the top of `index.ts`, because rules tell left and right modifiers apart.
- Hyper is Caps Lock, mapped to right ⌘⌥⌃⇧. Simlayers (hold one key, press another) group related actions. Each trigger key gets exactly one `simlayer(...)`, so to use a key that's already taken, add the mappings to its existing layer.
- To build, run `cd ~/.config/karabiner-config && npm run build`. It has to run from that directory, because `src/apps.ts` reads `./src/apps.json`. `npm run update` bumps `karabiner.ts` and changes `package-lock.json`. `node_modules/` is untracked.
- The build writes **two tracked, generated outputs**:
  1. the "Default profile" rules in `~/.config/karabiner/karabiner.json`, which Karabiner applies immediately
  2. the block between `##### BEGIN DEFAULT WORKSPACES #####` and `##### END DEFAULT WORKSPACES #####` in `aerospace.toml`

  Never edit either output by hand. Edit the sources, build, and then stage the sources and outputs together.

### App-to-workspace mapping

`src/apps.json` maps workspace keys to bundle IDs and is the single source of truth. Three things read it:

- Karabiner: Hyper plus a key cycles through that app's windows or launches the app, and ⌃+Hyper plus a key pulls one of its windows over.
- The generated block in `aerospace.toml`, which moves new windows to their workspace.
- `aerospace/map_bundle_id_to_default_workspace.bash` at runtime. Apps that aren't mapped fall back to workspace `q`.

To change a mapping, find the bundle ID with `mdls -name kMDItemCFBundleIdentifier -r /Applications/<App>.app`, edit `apps.json`, build, and stage `apps.json`, `karabiner.json` and `aerospace.toml`. Workspace names are `a–z`, `ä ö ü` and `0–9`. A new name also has to go into `space_names` in `sketchybar/items/aerospace.lua`.

### AeroSpace (`.config/aerospace/`)

- `aerospace.toml` holds the layout, the gaps (bottom gap = 30 px bar + 5) and the window rules. Hand-written `[[on-window-detected]]` rules, such as floating windows, go *below* the generated block. Focus and workspace changes trigger the SketchyBar events `aerospace_window_change` and `aerospace_workspace_change`.
- Karabiner calls the `*.bash` helpers with `bash ~/.config/aerospace/<script>`. They use `jq`. They keep short-lived state (pull and restore timestamps) on a RAM disk at `/Volumes/ramdisk`, which `init_ramdisk.bash` creates when needed.
- To reload, run `aerospace reload-config`.

### SketchyBar (`.config/sketchybar/`)

- It's written in Lua with SbarLua, which installs itself to `~/.local/share/sketchybar_lua` on first run. Files load in this order: `sketchybarrc`, then `init.lua`, which loads `bar.lua`, `default.lua` and `items/init.lua`, which loads `items/*.lua`. Shared values live in `helpers/` (`colors`, `fonts`, `icons`, and `icon_map`, which maps app names to sketchybar-app-font glyphs).
- To add an item, create `items/<name>.lua` and `require` it from `items/init.lua`.
- The config is hotloaded (`sbar.hotload(true)`). Never write state or log files into this directory, because that triggers reloads.
- System stats come from `stats_provider` (sketchybar-system-stats), which `helpers/stats_provider_supervisor.sh` keeps alive. The Wi-Fi SSID comes from a macOS Shortcut called `get-wlan-ssid`, which isn't in the repo.

## Raycast (`.config/raycast-scripts/`)

Each `*.sh` file is a Raycast script command. Raycast's own settings aren't tracked. New scripts follow the existing ones:

- They have a Raycast metadata header: `@raycast.schemaVersion 1`, `title`, `mode`, `icon icons/<name>.svg`, `packageName me.louisjannett.raycast.<name>`, `description`, `author`, and `argumentN` JSON.
- They start with `#!/usr/bin/env bash` and `set -euo pipefail`, check required commands up front, and print clear errors to stderr.
- They take configuration **only** from environment variables, each with an inline default and a short comment, for example `proxy="${BURP_PROXY:-127.0.0.1:8080}"  # Burp proxy listener`.
- They're executable. Stage the icon SVG together with the script.

Custom Raycast extensions live in their own repos. `bootstrap.d/030-raycast-extensions.sh` builds and installs them. To add one, append its SSH URL to the `extensions` array.

## Shell and scripts

- `.zprofile` holds environment variables and PATH entries, grouped under `# ===` section banners with a `# Category: what` comment above each entry. `.zshrc` holds shell integrations (starship, zsh-autosuggestions, completions) and aliases.
- `~/.bin` is on PATH through `.zprofile`. Karabiner shell commands get their PATH from `/Library/Application Support/org.pqrs/config/karabiner_environment`, which bootstrap `002` writes. A directory that Karabiner commands need must go in both places.
- `.bin/model -m chatgpt|pcc|local` pipes a prompt into the macOS Shortcut of the same name and converts the result to plain text. The Shortcuts aren't in the repo.
- `/usr/bin/env bash` resolves to Homebrew bash 5 (`brew "bash"` in `.Brewfile`), so scripts outside bootstrap may use bash 4+ features. If you remove that entry, check those scripts first (for example `declare -A` in `raycast-scripts/burp-chrome.sh`).

## Other tracked config

- `.gitconfig`: identity, SSH commit signing through 1Password, and git-get with root `~/repos`, which clones repos to `~/repos/<host>/<path>`. `.git-repos` is the matching git-get dump. Restore it with `git get --dump ~/.git-repos` and refresh it with `git list --out dump > ~/.git-repos`.
- `.claude/CLAUDE.md` is loaded in **every** Claude Code session, so edit it with care. Claude Code rewrites `.claude/settings.json` itself, so that file often shows up as modified. Nothing else under `~/.claude` (transcripts, memory, plugins, projects) is tracked, and nothing else there may be added.
- `.vscode/settings.json` holds workspace settings for `code ~` (`dots edit`).

## Conventions

- The work tree is the live `$HOME`, so edits take effect immediately. The only build step is Karabiner's `npm run build`. After a change, reload the affected tool. Don't run `brew bundle` or bootstrap unless the user asks.
- To add config for a new tool:
  1. Put it under `~/.config/<tool>/` when the tool supports that.
  2. Make sure the tool is in `.Brewfile`.
  3. Stage the explicit config files, never caches or state.
  4. If setup needs more than files (`defaults`, `sudo`, a build), add a `bootstrap.d` step.
  5. Add the tool to [Layout](#layout), and give it a section here if it isn't trivial.
- The global guidelines in `~/.claude/CLAUDE.md` about code style and environment-variable configuration still apply. The ones about Docker, `.env.example`, CI and commit messages don't.
- `README.md` stays user-facing and covers bootstrap only. Update this CLAUDE.md whenever a component, convention or flow changes, and stage it with the change.
