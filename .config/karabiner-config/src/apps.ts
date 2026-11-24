import appsJson from './apps.json' with { type: 'json' }
import { isWorkspaceKey, workspaceKeys, type WorkspaceKey } from './workspaces.ts'

// apps.json maps a workspace key to the bundle ID of the app that lives on that workspace,
// or to a list of bundle IDs when several apps share it. The first one is launched when
// none of them has a window. A bundle ID belongs to one key only, because that key is
// its default workspace. Look a bundle ID up with:
//   mdls -name kMDItemCFBundleIdentifier -r /Applications/<App>.app
//
// The OmniWM scripts read apps.json at runtime too (OMNIWM_APPS_JSON in their lib.sh).

/** Bundle IDs of a workspace's apps, the one to launch first. */
export type BundleIds = [string, ...string[]]

export type Apps = Partial<Record<WorkspaceKey, BundleIds>>

function parseApps(raw: Record<string, unknown>): Apps {
  const apps: Apps = {}
  const keyOfBundleId = new Map<string, string>()

  for (const [key, value] of Object.entries(raw)) {
    if (!isWorkspaceKey(key)) {
      throw new Error(`apps.json: "${key}" is not a workspace key (${workspaceKeys.join(' ')})`)
    }
    const bundleIds: unknown[] = Array.isArray(value) ? value : [value]
    if (!isBundleIdList(bundleIds)) {
      throw new Error(`apps.json: "${key}" must map to a bundle ID or a non-empty list of bundle IDs`)
    }
    for (const bundleId of bundleIds) {
      const otherKey = keyOfBundleId.get(bundleId)
      if (otherKey !== undefined) throw new Error(`apps.json: ${bundleId} is listed under both "${otherKey}" and "${key}"`)
      keyOfBundleId.set(bundleId, key)
    }
    apps[key] = bundleIds
  }
  return apps
}

function isBundleIdList(values: unknown[]): values is BundleIds {
  return values.length > 0 && values.every((value) => typeof value === 'string' && value !== '')
}

export const apps = parseApps(appsJson)
