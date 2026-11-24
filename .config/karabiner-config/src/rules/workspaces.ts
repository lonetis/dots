import { map, rule, withMapper, type RuleBuilder } from 'karabiner.ts'
import { omniwm, omniwmScript, orElse } from '../commands.ts'
import { deKey, hyper, lShiftHyper, rCmd, rCmdAlt } from '../keys.ts'
import { workspaceKeys, workspaceName } from '../workspaces.ts'

// Hyper plus a digit switches to that workspace. Letters belong to apps (rules/apps.ts),
// whose workspaces Hyper reaches by cycling through their windows. Right ⌘ reaches every
// workspace, see also right ⌘⌥⇧ in rules/displays.ts.
const digitKeys = workspaceKeys.filter((key) => /^\d$/.test(key))

export const workspaceRules: RuleBuilder[] = [
  rule('omniwm: workspace management').manipulators([
    withMapper(digitKeys)((key) =>
      map(deKey(key), hyper).to$(omniwm(`switch-workspace ${workspaceName(key)}`)),
    ),
    // show the workspace on the display under the pointer
    withMapper(workspaceKeys)((key) =>
      map(deKey(key), rCmd).to$(omniwmScript('summon', key)),
    ),
    // move the focused window to the workspace and follow it
    withMapper(workspaceKeys)((key) =>
      map(deKey(key), rCmdAlt).to$(omniwmScript('move-window', key)),
    ),
    // previous workspace
    map(deKey('^'), hyper).to$(omniwm('switch-workspace back-and-forth')),
    // previous window, or previous workspace when that window is gone
    map(deKey('⇥'), hyper).to$(orElse(omniwm('focus previous'), omniwm('switch-workspace back-and-forth'))),
    // move the focused window to its app's workspace, or to Q when it is already there
    map(deKey('⎋'), hyper).to$(omniwmScript('move-to-default')),
    // move every window to its app's workspace
    map(deKey('⎋'), lShiftHyper).to$(omniwmScript('move-all-to-default')),
  ]),
]
