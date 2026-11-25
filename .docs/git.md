# git

Global git configuration: identity, SSH commit signing through 1Password, and [git-get](https://github.com/grdl/git-get), which clones every repository to `~/repos/<host>/<path>`.

## Files

| Path | Tracked | Managed by | Purpose |
|---|---|---|---|
| `.gitconfig` | yes | manual | Identity, signing, LFS, git-get root, VS Code as difftool |
| `.gitignore_global` | yes | manual | Editor backups, `.DS_Store`, `.claude/settings.local.json` |
| `.config/git/allowed_signers` | yes | manual | SSH keys git trusts when it verifies commit signatures |
| `.git-repos` | 🔒 | manual | git-get dump of `~/repos`, one `url branch` per line |

## How it works

- Commits are signed with my SSH key from 1Password (`gpg.format = ssh`, `op-ssh-sign`).
- `allowed_signers` lists my 1Password key under my email and the agent key `~/.ssh/agent-commit-signing` under the principal `agent-commit-signing`, so `%GS` in `git log` tells agent commits apart.
- `.git-repos` is encrypted because it names private repositories.

## Changing it

- Restore all repositories with `git get --dump ~/.git-repos`; refresh the list with `git list --out dump > ~/.git-repos`.
- When a machine gets a new agent key, add its public key to `allowed_signers`.

## Per-machine setup

- 1Password with its SSH agent on ([ssh.md](ssh.md)); signing fails while 1Password is locked.
- The agent key `~/.ssh/agent-commit-signing`, if agents on this machine sign commits.
