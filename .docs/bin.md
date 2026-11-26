# Personal scripts (`~/.bin`)

Small commands of my own, on PATH in shells (`.zprofile`) and for GUI apps and Karabiner ([bootstrap](bootstrap.md) step `002`).

## Files

| Path | Tracked | Managed by | Purpose |
|---|---|---|---|
| `.bin/dots` | yes | manual | My yadm workflow |
| `.bin/model` | yes | manual | Sends a prompt to a language model through a macOS Shortcut |
| `.bin/model-chatgpt`, `model-local`, `model-pcc` | yes | manual | Pipe stdin to the Shortcut of the same name, without `model`'s preamble |

## How it works

- `dots` subcommands: `status`, `diff` (the interactive `hunk` TUI), `edit` (opens `~` in VS Code with the yadm repo, see [vscode.md](vscode.md)), `add` (`yadm add -f`), `commit` (message `update`), `push`, `save` (`add -u`, commit, push) and `init` (re-runs `.init.sh` from GitHub, see [bootstrap.md](bootstrap.md)). Agents use plain `yadm` instead, never the interactive subcommands, and `commit` only when the user asks; agents never run `push`, `save` or `init`.
- `model -m chatgpt|pcc|local` takes the prompt from `-p`, the remaining arguments or stdin, prepends a preamble that stops the model from treating it as a follow-up, pipes it into the Shortcut `model-<model>` and converts the rich-text answer to plain text with `textutil`.

## Changing it

- New scripts start with `#!/usr/bin/env bash` and `set -euo pipefail`, are executable, and print errors to stderr.

## Per-machine setup

- The Shortcuts `model-chatgpt`, `model-pcc` and `model-local` in the Shortcuts app. They aren't in the repo.
