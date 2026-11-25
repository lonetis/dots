# zsh

The login shell: environment variables and PATH in `.zprofile`, interactive settings in `.zshrc`.

## Files

| Path | Tracked | Managed by | Purpose |
|---|---|---|---|
| `.zprofile` | yes | manual | Environment variables and PATH; the block at the top was added by Docker Desktop |
| `.zshrc` | yes | manual | Color palette, shell integrations (autosuggestions, completions), aliases |
| `~/.zsh_history`, `~/.zcompdump*` | no | zsh | History and completion cache |

## How it works

- `.zprofile` groups entries under `# ===` section banners, with a `# Category: what` comment above each entry: Homebrew (`brew shellenv`, which also sets `HOMEBREW_PREFIX`), PATH additions (`~/.local/bin`, `~/.bin`, depot_tools, Antigravity), the 1Password SSH agent socket, `GIT_CEILING_DIRECTORIES` and the locale fix (`unset LC_CTYPE`, because ssh would send the macOS-only `UTF-8` value to servers).
- `.zshrc` has the same layout. The Apple HIG palette is four associative arrays of hex values (`hig_light`, `hig_dark`, `hig_light_contrast`, `hig_dark_contrast`) keyed by color name (`red` … `brown`, `gray` … `gray6`), for `%F{$hig_dark[red]}` in prompts and `fg=$hig_dark[gray]` in highlight styles.
- Aliases: the Chrome channels (`chrome`, `canary`, `beta`, `dev`) and `claude-nds`, which runs Claude Code with a company OAuth token from a 1Password Environment.
- Programs started outside a shell (GUI apps, Karabiner) never read these files. Their PATH comes from [bootstrap](bootstrap.md) step `002`.

## Changing it

- Add an entry under the matching banner with its `# Category: what` comment.
- A directory that GUI apps or Karabiner commands need must also go into `bootstrap.d/002-path.sh`.
- Leave Docker Desktop's marked block alone; Docker Desktop checks for it.

## Per-machine setup

None.
