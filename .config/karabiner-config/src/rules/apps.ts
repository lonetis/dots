import { map, rule, withMapper, type RuleBuilder } from 'karabiner.ts'
import { hotkeys } from '../apps.ts'
import { omniwm, omniwmHelper, openApp, orElse } from '../commands.ts'
import { deKey, hyper, lCmdHyper } from '../keys.ts'
import { workspaceKeys, workspaceName } from '../workspaces.ts'

// Hyper plus a workspace key, digits and letters alike: the key's app from apps.json, or
// the key's workspace when no app has the key. p toggles 1Password instead, so workspace P
// has no Hyper binding, and an app on p in apps.json fails the build as a conflict.
const onePasswordKey = 'p'
const keysWithoutApp = workspaceKeys.filter((key) => hotkeys[key] === undefined && key !== onePasswordKey)

export const appRules: RuleBuilder[] = [
  rule('omniwm: app management').manipulators([
    // return to the key's app's last focused window, then cycle through its windows, or launch it
    withMapper(hotkeys)((key, bundleId) =>
      map(deKey(key), hyper).to$(orElse(omniwmHelper('cycle', bundleId), openApp(bundleId))),
    ),
    // switch to the workspace of a key that no app has
    withMapper(keysWithoutApp)((key) =>
      map(deKey(key), hyper).to$(omniwm(`switch-workspace ${workspaceName(key)}`)),
    ),
    // pull a window of the key's app to the workspace under the pointer
    withMapper(hotkeys)((key, bundleId) =>
      map(deKey(key), lCmdHyper).to$(omniwmHelper('pull', bundleId)),
    ),
    // show or hide 1Password on top of the current workspace
    map(deKey(onePasswordKey), hyper).to$(omniwmHelper('toggle', 'com.1password.1password')),
  ]),
]
