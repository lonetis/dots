# Claude Code

Settings of Claude Code and its status line, [ccstatusline](https://github.com/sirmalloc/ccstatusline). This doc is named `claude-code.md` because a `claude.md` would be loaded as a nested CLAUDE.md on a case-insensitive file system.

## Files

| Path | Tracked | Managed by | Purpose |
|---|---|---|---|
| `.claude/settings.json` | yes | app | User settings; Claude Code rewrites it when settings change |
| `.config/ccstatusline/settings.json` | yes | app | Status line layout; ccstatusline's TUI rewrites it |
| everything else under `~/.claude/` | no | app | Transcripts, memory, plugins, projects. Never add any of it |

## How it works

- There is no global `~/.claude/CLAUDE.md`. Coding conventions come from the skills of the `code` plugin, which load when they apply; of those, only `code:conventions` applies to this repo.
- Claude Code loads every `CLAUDE.md` from the session's directory upward, so `~/CLAUDE.md` would load in every project under `~`. `claudeMdExcludes` excludes it everywhere, and a SessionStart hook tells Claude to read it when a session starts in `~` or in a dot-directory that yadm tracks files in (`yadm ls-files --error-unmatch -- "$CLAUDE_PROJECT_DIR"`). The hook names the file instead of printing it, because hook output is cut off at 10,000 characters. The `agents-md` setting also loads `AGENTS.md` files, so don't add one to `~`.
- `permissions.defaultMode` is `bypassPermissions`, with no deny rules. What agents may not run in this repo (commit unless asked, push, bootstrap, `dots init`, `brew bundle cleanup --force`) is a rule in `CLAUDE.md`, not a permission.
- `preferredNotifChannel` is `ghostty` (OSC 777), which both Ghostty and Rex show. The default `auto` doesn't recognize Rex (`TERM_PROGRAM=rex`) and sends nothing there.
- The `code-review` and `code-simplifier` plugins are off because they duplicate the built-in `/code-review` and `/simplify` and the `pr-review-toolkit:code-simplifier` agent. The three browser plugins (Playwright, Chrome DevTools, Claude in Chrome) overlap, but all three are in use.
- The `typescript-lsp` plugin runs `typescript-language-server`, which needs a TypeScript that ships `tsserver`: version 6 or older in the project's `node_modules`. The global `brew "typescript"` is 7, which dropped `tsserver`.
- ccstatusline is installed globally through `npm "ccstatusline"` (faster than `npx` on every render) and set as the `statusLine` command. Its one row shows model, effort, permission mode, ultracode, context (against the auto-compaction point), session cost, the 5h and weekly limits with reset times, the weekly Fable limit and git.
- ccstatusline has no widget for permission mode or ultracode, and the statusLine JSON carries neither. Two `custom-command` widgets read them from the transcript (`transcript_path`): the last `permissionMode` and the last `ultra_effort_enter`/`ultra_effort_exit` attachment. Both update with the next prompt. The ultracode widget prints nothing while ultracode is off, so it and its separator disappear.

## Changing it

- Change settings through Claude Code (`/config`, `/permissions`, `/plugin`, …) or ask the user; review and stage the rewritten file.
- Change the status line in ccstatusline's TUI (`ccstatusline` without stdin). Test a layout by piping in a captured statusLine JSON: `ccstatusline --config <file> < input.json`. Update it with `npm update -g ccstatusline` or `brew bundle`.

## Per-machine setup

- Log in to Claude Code and install the plugins listed in `enabledPlugins`.
