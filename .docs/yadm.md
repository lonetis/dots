# yadm (the repository)

`~` is the work tree of a [yadm](https://yadm.io) repository, published at `github.com/lonetis/dots`. **The repo is public.** Anyone can read every tracked file except the ones git-crypt encrypts.

## Files

| Path | Tracked | Managed by | Purpose |
|---|---|---|---|
| `README.md` | yes | manual | User-facing: bootstrap instructions only |
| `CLAUDE.md` | yes | manual | Agent entry point: rules and the index of `.docs/` |
| `.docs/*.md` | yes | manual | One doc per component, all in the same structure |
| `.gitignore` | yes | manual | `*`: ignores all of `$HOME`, so tracking is opt-in |
| `.gitattributes` | yes | manual | The list of git-crypt encrypted files |
| `.bin/dots` | yes | manual | My yadm workflow, see [bin.md](bin.md) |
| `~/.local/share/yadm/repo.git` | no | yadm | The repository itself |
| `~/.git-crypt` | no | manual | The git-crypt key, never commit it |

## How it works

- yadm wraps git. There is no `~/.git`, so plain `git` in `~` doesn't see this repo, and `GIT_CEILING_DIRECTORIES=$HOME` (in `.zprofile`) stops git from searching upward from other folders. Use `yadm <git-subcommand>` for everything.
- `.gitignore` is `*`, so `yadm status` hides untracked files and a new file needs `yadm add -f`. `-f` also bypasses `.gitignore_global`, which is why staging a directory would pull in `node_modules/`, `.DS_Store`, Claude Code transcripts and similar files.
- Commits are SSH-signed through 1Password (`op-ssh-sign`) and pushes go through the 1Password SSH agent ([git.md](git.md), [ssh.md](ssh.md)), so both can need the user to unlock 1Password.
- Every commit message is `update` (`dots commit`). No Conventional Commit prefixes, emoji, body or trailers; the `code:git` skill doesn't apply here.

### Secrets (git-crypt)

Paths marked `filter=git-crypt diff=git-crypt` in `.gitattributes` are encrypted on the remote and decrypted in the local checkout. Currently these are `.ssh/config` and `.git-repos`. Bootstrap step `001` unlocks the repo with `~/.git-crypt`.

- Never copy anything from an encrypted file into a plaintext file, a commit message or a doc.
- Every other file is public: no tokens, API keys, private hostnames or IPs, internal URLs or private repo names. Read secrets at runtime from the environment or 1Password (`op`).

## Changing it

| Task | Command |
|---|---|
| Show status | `yadm status` |
| List tracked files / check one | `yadm list -a` / `yadm ls-files --error-unmatch <path>` |
| Review changes | `yadm diff`, `yadm diff --cached` |
| Stage a new file, or edits inside a directory | `yadm add -f -- <path>` |
| Stage edits to a file directly in `~` | `yadm add -- <path>` |
| Stage edits and deletions of all tracked files | `yadm add -u` |
| Rename, delete, untrack (keep the file) | `yadm mv <old> <new>`, `yadm rm <path>`, `yadm rm --cached <path>` |
| List encrypted files | `yadm git-crypt status -e` |

- Stage explicit file paths, never directories or globs.
- To track a new sensitive file, add it to `.gitattributes` *before* staging it, stage both, then check that `yadm git-crypt status -e` lists it. A file once committed as plaintext stays readable in the history; tell the user if that happens.

## Per-machine setup

- The git-crypt key at `~/.git-crypt` before bootstrap (see `README.md`). Export it on a machine that has it with `yadm git-crypt export-key ~/.git-crypt`.
- 1Password with its SSH agent turned on (Settings → Developer), for signing and pushing.
