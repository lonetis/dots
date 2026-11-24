// OmniWM workspaces, one per key, in workspace bar order. OmniWM only accepts positive
// integers as workspace names, so the key at index i becomes workspace `i + 1` and shows
// the upper-case key as its display name (1 → 1, 0 → 10, a → 11 "A", ü → 39 "Ü").
//
// Only append keys. Inserting one renumbers every workspace after it, and OmniWM keeps
// open windows on their workspace number across a reload, so they would all show up
// under a different key.
export const workspaceKeys = [
  '1', '2', '3', '4', '5', '6', '7', '8', '9', '0',
  'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k', 'l', 'm',
  'n', 'o', 'p', 'q', 'r', 's', 't', 'u', 'v', 'w', 'x', 'y', 'z',
  'ä', 'ö', 'ü',
] as const

export type WorkspaceKey = (typeof workspaceKeys)[number]

export type MonitorAssignment = 'main' | 'secondary' | 'tertiary'

// Home monitor of a workspace when the build first creates it. A home changed later in
// OmniWM's Settings window survives the build.
const initialMonitors: Partial<Record<WorkspaceKey, MonitorAssignment>> = {
  '4': 'secondary', '5': 'secondary', '6': 'secondary',
  '7': 'tertiary', '8': 'tertiary', '9': 'tertiary',
}

export function isWorkspaceKey(key: string): key is WorkspaceKey {
  return (workspaceKeys as readonly string[]).includes(key)
}

/** The workspace's name in OmniWM, which omniwmctl commands take. */
export function workspaceName(key: WorkspaceKey): string {
  return String(workspaceKeys.indexOf(key) + 1)
}

/** The label OmniWM shows in the workspace bar, which the OmniWM scripts look workspaces up by. */
export function workspaceLabel(key: WorkspaceKey): string {
  return key.toUpperCase()
}

export function initialMonitor(key: WorkspaceKey): MonitorAssignment {
  return initialMonitors[key] ?? 'main'
}
