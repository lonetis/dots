import appsJson from './apps.json' with { type: 'json' }
import { isWorkspaceKey, workspaceKeys, type WorkspaceKey } from './workspaces.ts'

// apps.json lists the apps with their workspace and, optionally, their key:
//   { "workspace": "t", "key": "t", "bundleId": "com.mitchellh.ghostty" }
// Several apps can share a workspace, but a key belongs to one app only. Look a bundle ID
// up with:
//   mdls -name kMDItemCFBundleIdentifier -r /Applications/<App>.app
//
// The OmniWM scripts read apps.json at runtime too (OMNIWM_APPS_JSON in their lib.sh).

export interface App {
  bundleId: string
  /** The app's default workspace: its first window opens there. */
  workspace: WorkspaceKey
  /** Hyper plus this key cycles through the app's windows or launches it. */
  key?: WorkspaceKey
}

const appFields = new Set(['workspace', 'key', 'bundleId'])

function parseApp(value: unknown, index: number): App {
  if (typeof value !== 'object' || value === null || Array.isArray(value)) {
    throw new Error(`apps.json: entry ${index + 1} must be { "workspace": …, "key": …, "bundleId": … }`)
  }
  const fields = value as Record<string, unknown>
  const { workspace, key, bundleId } = fields
  if (typeof bundleId !== 'string' || bundleId === '') throw new Error(`apps.json: entry ${index + 1} needs a bundleId`)
  const unknownField = Object.keys(fields).find((field) => !appFields.has(field))
  if (unknownField !== undefined) throw new Error(`apps.json: ${bundleId} has unknown field "${unknownField}"`)
  if (typeof workspace !== 'string' || !isWorkspaceKey(workspace)) {
    throw new Error(`apps.json: ${bundleId} needs a workspace, one of ${workspaceKeys.join(' ')}`)
  }
  if (key === undefined) return { bundleId, workspace }
  if (typeof key !== 'string' || !isWorkspaceKey(key)) {
    throw new Error(`apps.json: key of ${bundleId} must be one of ${workspaceKeys.join(' ')}`)
  }
  return { bundleId, workspace, key }
}

function parseApps(raw: unknown[]): App[] {
  const apps = raw.map(parseApp)
  const bundleIds = new Set<string>()
  for (const { bundleId } of apps) {
    if (bundleIds.has(bundleId)) throw new Error(`apps.json: ${bundleId} is listed twice`)
    bundleIds.add(bundleId)
  }
  return apps
}

/** Maps each key to the bundle ID of its app. */
function hotkeysOf(apps: App[]): Partial<Record<WorkspaceKey, string>> {
  const hotkeys: Partial<Record<WorkspaceKey, string>> = {}
  for (const { bundleId, key } of apps) {
    if (key === undefined) continue
    const otherBundleId = hotkeys[key]
    if (otherBundleId !== undefined) throw new Error(`apps.json: key "${key}" is used by both ${otherBundleId} and ${bundleId}`)
    hotkeys[key] = bundleId
  }
  return hotkeys
}

export const apps = parseApps(appsJson)

export const hotkeys = hotkeysOf(apps)
