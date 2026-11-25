# SSH

SSH client configuration. Keys live in 1Password and are served by its SSH agent; no private key is on disk.

## Files

| Path | Tracked | Managed by | Purpose |
|---|---|---|---|
| `.ssh/config` | 🔒 | manual | Hosts and their options |
| `.ssh/known_hosts`, other keys | no | ssh | Host keys and local keys |
| `~/Library/LaunchAgents/com.1password.SSH_AUTH_SOCK.plist` | no | manual | Links `SSH_AUTH_SOCK` of GUI apps to the 1Password agent socket |

## How it works

- `.zprofile` points `SSH_AUTH_SOCK` at the 1Password agent socket for shells; the LaunchAgent does the same for apps started by launchd.
- `.ssh/config` is encrypted because it names private hosts. Never copy anything out of it into a public file.

## Changing it

- Edit `.ssh/config` and stage it like any tracked file; git-crypt encrypts it on commit.

## Per-machine setup

- 1Password → Settings → Developer → SSH agent on.
- The LaunchAgent above, from 1Password's SSH agent setup guide.
