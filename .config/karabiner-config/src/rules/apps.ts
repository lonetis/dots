import { map, rule, withMapper, type RuleBuilder } from 'karabiner.ts'
import { apps } from '../apps.ts'
import { omniwmScript, openApp, orElse } from '../commands.ts'
import { deKey, hyper, lCtrlHyper } from '../keys.ts'

// Apps by workspace key, from apps.json. Hyper plus a digit switches workspaces instead
// (rules/workspaces.ts), so a digit in apps.json fails the build as a conflict.

export const appRules: RuleBuilder[] = [
  rule('omniwm: app management').manipulators([
    // cycle through the windows of the key's apps, or launch the first app
    withMapper(apps)((key, bundleIds) =>
      map(deKey(key), hyper).to$(orElse(omniwmScript('cycle', ...bundleIds), openApp(bundleIds[0]))),
    ),
    // pull a window of the key's apps to the workspace under the pointer
    withMapper(apps)((key, bundleIds) =>
      map(deKey(key), lCtrlHyper).to$(omniwmScript('pull', ...bundleIds)),
    ),
    // show or hide 1Password on top of the current workspace
    map(deKey('p'), hyper).to$(omniwmScript('toggle', 'com.1password.1password')),
  ]),
]
