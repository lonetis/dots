import { map, rule, withMapper, type RuleBuilder } from 'karabiner.ts'
import { omniwm, omniwmHelper, orElse } from '../commands.ts'
import { deKey, hyper, lAltHyper, lCmdAltHyper, lCmdHyper, lCtrlHyper } from '../keys.ts'
import { workspaceKeys } from '../workspaces.ts'

// Hyper plus a workspace key goes to the key's app or, without one, to its workspace
// (rules/apps.ts). Left ⌥ + Hyper and left ⌘⌥ + Hyper reach every workspace.

export const workspaceRules: RuleBuilder[] = [
  rule('omniwm: workspace management').manipulators([
    // pull the workspace to the display under the pointer
    withMapper(workspaceKeys)((key) =>
      map(deKey(key), lAltHyper).to$(omniwmHelper('summon', key)),
    ),
    // send the focused window to the workspace, also one in the background, and stay on the
    // source workspace; pressing the key again right away follows the window
    withMapper(workspaceKeys)((key) =>
      map(deKey(key), lCmdAltHyper).to$(omniwmHelper('send-window', key)),
    ),
    // previous workspace
    map(deKey('^'), hyper).to$(omniwm('switch-workspace back-and-forth')),
    // previous window, or previous workspace when that window is gone
    map(deKey('⇥'), hyper).to$(orElse(omniwm('focus previous'), omniwm('switch-workspace back-and-forth'))),
    // send the focused window to its app's workspace, or to Q when it is already there, and
    // stay on the source workspace; pressing the key again right away follows the window
    map(deKey('␣'), lCmdHyper).to$(omniwmHelper('send-window', 'default')),
    // move every window to its app's workspace
    map(deKey('␣'), lCtrlHyper).to$(omniwmHelper('move-all-to-default')),
  ]),
]
