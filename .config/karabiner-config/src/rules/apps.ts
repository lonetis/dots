import { map, rule, withMapper, type RuleBuilder } from 'karabiner.ts'
import { hotkeys } from '../apps.ts'
import { omniwmScript, openApp, orElse } from '../commands.ts'
import { deKey, hyper, lCtrlHyper } from '../keys.ts'

// One app per key, from apps.json. Hyper plus a digit switches workspaces instead
// (rules/workspaces.ts), so a digit key in apps.json fails the build as a conflict.

export const appRules: RuleBuilder[] = [
  rule('omniwm: app management').manipulators([
    // cycle through the windows of the key's app, or launch it
    withMapper(hotkeys)((key, bundleId) =>
      map(deKey(key), hyper).to$(orElse(omniwmScript('cycle', bundleId), openApp(bundleId))),
    ),
    // pull a window of the key's app to the workspace under the pointer
    withMapper(hotkeys)((key, bundleId) =>
      map(deKey(key), lCtrlHyper).to$(omniwmScript('pull', bundleId)),
    ),
    // show or hide 1Password on top of the current workspace
    map(deKey('p'), hyper).to$(omniwmScript('toggle', 'com.1password.1password')),
  ]),
]
