import { readFileSync } from 'fs'

// Workspace key -> bundle IDs of the apps that live on that workspace. In apps.json a key
// maps to one bundle ID or to a list of them; the first one is launched when none of
// them has a window. A bundle ID belongs to one key only, which is its default workspace.
// mdls -name kMDItemCFBundleIdentifier -r /Applications/Safari.app/
export type Apps = { [key: string]: string[] }

function readApps(path: string): Apps {
  const raw = JSON.parse(readFileSync(path, 'utf-8')) as { [key: string]: unknown }
  const apps: Apps = {}
  const keyOfBundleId = new Map<string, string>()

  for (const [key, value] of Object.entries(raw)) {
    const bundleIds: unknown[] = Array.isArray(value) ? value : [value]
    if (bundleIds.length === 0 || !bundleIds.every((id): id is string => typeof id === 'string' && id !== '')) {
      throw new Error(`${path}: "${key}" must map to a bundle ID or a non-empty list of bundle IDs`)
    }
    for (const bundleId of bundleIds) {
      const otherKey = keyOfBundleId.get(bundleId)
      if (otherKey !== undefined) throw new Error(`${path}: ${bundleId} is listed under both "${otherKey}" and "${key}"`)
      keyOfBundleId.set(bundleId, key)
    }
    apps[key] = bundleIds
  }
  return apps
}

const apps = readApps('./src/apps.json')

export default apps
