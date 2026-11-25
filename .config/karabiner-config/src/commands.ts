// Builders for the shell commands that bindings run with to$(). Karabiner runs them with
// /bin/sh and the PATH from karabiner_environment (written by bootstrap step 002), which
// covers Homebrew (omniwmctl, node, npm) and ~/.bin. Every value interpolated below is
// written in this repo, so values are at most wrapped in single quotes, never escaped.

const omniwmScriptsDir = '~/.config/omniwm/scripts'

/** Runs a native OmniWM command, e.g. `omniwm('focus left')`. */
export function omniwm(command: string): string {
  return `omniwmctl command ${command}`
}

/** Runs one of the helper scripts in ~/.config/omniwm/scripts, e.g. `omniwmScript('cycle', bundleId)`. */
export function omniwmScript(name: string, ...args: string[]): string {
  return [`${omniwmScriptsDir}/${name}.sh`, ...args].join(' ')
}

/** Runs each command only if the one before it failed, e.g. to fall back from a niri-only OmniWM command. */
export function orElse(...commands: string[]): string {
  return commands.join(' || ')
}

export function openApp(bundleId: string): string {
  return `open -b '${bundleId}'`
}

export function openUrl(url: string): string {
  return `open -u '${url}'`
}

// Tinycast links open with `open -g`, so the app in front keeps focus: snippets paste into it and
// extensions read its selected text.
function openTinycast(path: string): string {
  return `open -g -u 'tinycast://${path}'`
}

/**
 * Runs a built-in Tinycast command by its deeplink id, e.g. `tinycast('clipboard-history')`.
 * `fallbackText` types into the command's first field. Tinycast asks once before it runs a link
 * with text ("Always Allow" remembers the answer).
 */
export function tinycast(command: string, fallbackText?: string): string {
  const query = fallbackText === undefined ? '' : `?fallbackText=${encodeURIComponent(fallbackText)}`
  return openTinycast(`command/${command}${query}`)
}

/** Runs a Raycast extension command in Tinycast by its deeplink path, `<author>/<extension>/<command>`. */
export function tinycastExtension(command: string): string {
  return openTinycast(`extensions/${command}`)
}

/** Opens System Settings, or one of its panes by the bundle ID of the pane's extension. */
export function systemSettings(pane?: string): string {
  return pane === undefined ? openApp('com.apple.systempreferences') : openUrl(`x-apple.systempreferences:${pane}`)
}

export function notify(title: string): string {
  return `osascript -e 'display notification with title "${title}"'`
}

/** Quits the app when it runs, launches it otherwise. */
export function toggleApp(app: string): string {
  return `if pgrep -xq '${app}'; then osascript -e 'quit app "${app}"'; else open -a '${app}'; fi`
}

/** Quits the app, waits up to 10 s for it to exit, launches it again and reports the outcome. */
export function restartApp(app: string): string {
  return [
    `osascript -e 'quit app "${app}"'`,
    `for _ in $(seq 50); do pgrep -xq '${app}' || break; sleep 0.2; done`,
    `if pgrep -xq '${app}'; then ${notify(`${app} did not quit`)}; else open -a '${app}' && ${notify(`restarted ${app}`)}; fi`,
  ].join('; ')
}
