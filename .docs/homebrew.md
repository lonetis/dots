# Homebrew

`.Brewfile` is the single source of truth for installed software. Bootstrap installs it and then **removes everything not listed**, so anything installed by hand has to be added here or it disappears on the next bootstrap.

## Files

| Path | Tracked | Managed by | Purpose |
|---|---|---|---|
| `.Brewfile` | yes | manual | Taps, formulae, casks, Mac App Store apps, VS Code extensions, Go, uv and npm packages |

## How it works

- Bootstrap step `012` runs `brew bundle install --global` (which reads `~/.Brewfile`) and then `brew bundle cleanup --global --force`, which uninstalls and untaps what isn't listed.
- Sections, in this order: `tap`, `brew`, tap-qualified `brew`, `cask`, `mas`, `vscode`, `go`, `uv`, `npm`. Entries are alphabetical inside each section; the Python formulae keep `brew bundle dump`'s dependency order.
- Every `brew` and `cask` line has a `# description` comment above it, taken from `brew desc <name>` or `brew desc --cask <name>`. Casks without a description (the fonts) get their name instead.
- `brew "bash"` makes `/usr/bin/env bash` resolve to bash 5 in shells and GUI apps (PATH from [bootstrap](bootstrap.md) step `002`).

## Changing it

- Add or remove entries in the format above. Homebrew disabled `brew bundle dump --describe`, so write the comment yourself.
- To find what's missing, compare a plain `brew bundle dump --file=<tmp>` with `.Brewfile`. `brew bundle cleanup --global` without `--force` only lists what bootstrap would remove.
- Don't run `brew bundle` or bootstrap unless the user asks; `brew bundle cleanup --force` is blocked for agents.

## Per-machine setup

- Sign in to the App Store for the `mas` entries.
