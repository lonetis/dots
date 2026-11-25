# CLAUDE.md — dots

Personal macOS dotfiles (Apple Silicon, Homebrew in `/opt/homebrew`, German keyboard), managed with yadm: `~` is the work tree, so edits take effect immediately (reload the affected tool; the only build is Karabiner's). **The repo is public** (`github.com/lonetis/dots`); only the git-crypt files are private.

## Rules

- Use `yadm`, never plain `git`, for this repo.
- **Stage every change, never commit or push.** Stage explicit file paths (`yadm add -f -- <path>`), never directories or globs. Only when the user asks for a commit, run `dots commit` (the message is always `update`).
- Never write secrets, private hostnames or private repo names into a plaintext file ([yadm.md](.docs/yadm.md#secrets-git-crypt)).
- Don't hand-edit files that an app or a build writes (`app`, `build` and the generated parts of `hybrid` below). Change them in the app or in the sources.
- Don't run `yadm bootstrap`, `dots init` or `brew bundle`: they prompt for sudo, rebuild the Dock and uninstall software.
- Before you change a component, read its doc. After the change, update the doc and stage it with the change.
- Of the `code` plugin's skills, only `code:conventions` applies here.

## Docs

| Doc | Covers |
|---|---|
| [yadm.md](.docs/yadm.md) | The repo: staging, commands, git-crypt secrets |
| [bootstrap.md](.docs/bootstrap.md) | `.init.sh`, `yadm bootstrap` and its steps, macOS defaults, Dock, PATH for GUI apps |
| [homebrew.md](.docs/homebrew.md) | `.Brewfile`: all installed software |
| [zsh.md](.docs/zsh.md) | `.zprofile`, `.zshrc` |
| [bin.md](.docs/bin.md) | `~/.bin`: `dots`, `model` |
| [git.md](.docs/git.md) | `.gitconfig`, commit signing, git-get and `.git-repos` |
| [ssh.md](.docs/ssh.md) | `.ssh/config`, 1Password SSH agent |
| [karabiner.md](.docs/karabiner.md) | Karabiner-Elements: every keybinding, written in TypeScript |
| [omniwm.md](.docs/omniwm.md) | OmniWM window manager, workspaces and the app mapping, helper scripts |
| [tinycast.md](.docs/tinycast.md) | Tinycast launcher: settings, extensions, script commands |
| [claude-code.md](.docs/claude-code.md) | Claude Code settings and the ccstatusline status line |
| [vscode.md](.docs/vscode.md) | Workspace settings for editing `~` in VS Code |

## Doc structure

Every doc in `.docs/` covers one component and has the same sections. New docs follow it, and the table above lists them.

```markdown
# <Component>

<What it is and its role, in one paragraph.>

## Files
| Path | Tracked | Managed by | Purpose |   ← every file and folder the component uses, tracked or not

## How it works
## Changing it
## Per-machine setup                         ← what isn't in the repo; "None." if nothing
```

- **Tracked**: `yes`, `no` or `🔒` (tracked and encrypted with git-crypt).
- **Managed by**: `manual` (written by hand: edit it), `app` (the app writes it from its settings window or TUI and rewrites it on every change: change it there, then review and stage the rewrite), `build` (generated from sources in this repo: edit the sources and rebuild) or `hybrid` (several of these; the Purpose column says which part comes from where).

To add a tool: put its config under `~/.config/<tool>/` when the tool supports that, add the tool to `.Brewfile`, stage only config files (no caches or state), add a `bootstrap.d` step when setup needs more than files, and write its doc. `README.md` stays user-facing and covers bootstrap only.
