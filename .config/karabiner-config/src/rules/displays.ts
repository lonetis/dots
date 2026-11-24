import { map, rule, withMapper, type RuleBuilder } from 'karabiner.ts'
import { omniwmScript } from '../commands.ts'
import { deKey, lAltHyper, lCmdHyper, rCmdAltShift } from '../keys.ts'
import { workspaceKeys } from '../workspaces.ts'

// Windows and workspaces between displays. The scripts wrap around at the last display
// and route over the monitor grid from OmniWM's Monitor Setup, because OmniWM itself
// only moves a workspace to an adjacent display.

export const displayRules: RuleBuilder[] = [
  rule('omniwm: display management').manipulators([
    // move the focused window to the next / previous display
    map(deKey('e'), lAltHyper).to$(omniwmScript('move-window-to-display', 'next')),
    map(deKey('q'), lAltHyper).to$(omniwmScript('move-window-to-display', 'prev')),
    // move the focused workspace to the next / previous display
    map(deKey('e'), lCmdHyper).to$(omniwmScript('move-workspace', 'next')),
    map(deKey('q'), lCmdHyper).to$(omniwmScript('move-workspace', 'prev')),
    // move the key's workspace to the next display
    withMapper(workspaceKeys)((key) =>
      map(deKey(key), rCmdAltShift).to$(omniwmScript('send-workspace', key)),
    ),
  ]),
]
