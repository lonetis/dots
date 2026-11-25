# VS Code (`code ~`)

Workspace settings that make it practical to open `~` in VS Code to edit the dotfiles. Editor settings and extensions are elsewhere: the extensions are in `.Brewfile` ([homebrew.md](homebrew.md)), the user settings aren't tracked.

## Files

| Path | Tracked | Managed by | Purpose |
|---|---|---|---|
| `.vscode/settings.json` | yes | manual | Workspace settings for `~` |
| `~/Library/Application Support/Code/User/` | no | app | User settings, keybindings, state |

## How it works

- VS Code's git extension finds no `~/.git`, so `dots edit` starts VS Code with `GIT_DIR` and `GIT_WORK_TREE` pointing at the yadm repo. VS Code passes them only to the window `dots edit` opens; a `~` window it restores after a restart lacks them.
- Because `.gitignore` is `*`, the explorer greys out every untracked file and every folder without tracked files. The settings keep untracked files out of Source Control (`git status -uno`, so git never scans `$HOME`), hide and skip non-dot entries in the explorer and search, and remove both variables from the integrated terminal, so plain `git` there still works on other repos.
- `files.watcherExclude` excludes non-dot entries and busy dot folders without tracked files (caches, `.claude/*/`, `.vscode/extensions`, `.local/share` except `yadm`, OmniWM's `shell/default`). The git extension refreshes from a watcher on the yadm repo, so `.local/share/yadm` must stay watched.

## Changing it

- When a new dot folder churns, add it to `files.watcherExclude`; when a folder gains tracked files, narrow its exclusion.

## Per-machine setup

- Close a restored `~` window and run `dots edit` again.
