import { map, rule, withMapper, type RuleBuilder } from 'karabiner.ts'
import { omniwm, omniwmScript, orElse } from '../commands.ts'
import { deKey, lCmd, lCmdHyper, lCmdShiftHyper } from '../keys.ts'

// The focused window and the layout of its workspace, all on left ⌘ + Hyper. Workspaces
// use either OmniWM's niri layout (scrolling columns) or dwindle (binary splits). Where a
// command exists for one layout only, the binding falls back to the other's equivalent.

export const windowRules: RuleBuilder[] = [
  rule('omniwm: window management').manipulators([
    // focus
    map(deKey('↑'), lCmdHyper).to$(omniwm('focus up')),
    map(deKey('↓'), lCmdHyper).to$(omniwm('focus down')),
    map(deKey('←'), lCmdHyper).to$(omniwm('focus left')),
    map(deKey('→'), lCmdHyper).to$(omniwm('focus right')),
    // move (niri: swap columns left / right, reorder within the column up / down)
    map(deKey('w'), lCmdHyper).to$(omniwm('move up')),
    map(deKey('s'), lCmdHyper).to$(omniwm('move down')),
    map(deKey('a'), lCmdHyper).to$(omniwm('move left')),
    map(deKey('d'), lCmdHyper).to$(omniwm('move right')),
    // join (niri: consume into / expel from columns; dwindle: move the tile instead)
    map(deKey('k'), lCmdHyper).to$(orElse(omniwm('consume-window-into-column'), omniwm('move up'))),
    map(deKey('j'), lCmdHyper).to$(orElse(omniwm('expel-window-from-column'), omniwm('move down'))),
    map(deKey('h'), lCmdHyper).to$(orElse(omniwm('consume-or-expel-window-left'), omniwm('move left'))),
    map(deKey('l'), lCmdHyper).to$(orElse(omniwm('consume-or-expel-window-right'), omniwm('move right'))),

    // focus column by index
    withMapper([1, 2, 3, 4] as const)((index) =>
      map(deKey(index), lCmdHyper).to$(omniwm(`focus-column ${index}`)),
    ),

    // resize (niri: column width; dwindle: focused window)
    map(deKey('+'), lCmdHyper).to$(orElse(omniwm('set-container-primary-span +10%'), omniwm('resize-focused grow'))),
    map(deKey('-'), lCmdHyper).to$(orElse(omniwm('set-container-primary-span -10%'), omniwm('resize-focused shrink'))),
    // balance
    map(deKey('b'), lCmdHyper).to$(omniwm('balance-sizes')),
    // cycle size presets (1/3, 1/2, 2/3)
    map(deKey('#'), lCmdHyper).to$(omniwm('cycle-size forward')),

    // fullscreen within OmniWM / native macOS fullscreen
    map(deKey('f'), lCmdHyper).to$(omniwm('toggle-fullscreen')),
    map(deKey('f'), lCmdShiftHyper).to$(omniwm('toggle-native-fullscreen')),
    // minimize
    map(deKey('m'), lCmdHyper).to(deKey('m'), lCmd),

    // close the window / and quit its app when it was the last window
    map(deKey('x'), lCmdHyper).to$(omniwm('close-focused-window')),
    map(deKey('x'), lCmdShiftHyper).to$(omniwmScript('close', '--quit-if-last-window')),
    // close every other window on the workspace / and quit apps left without windows
    map(deKey('⌫'), lCmdHyper).to$(omniwmScript('close-others')),
    map(deKey('⌫'), lCmdShiftHyper).to$(omniwmScript('close-others', '--quit-if-last-window')),
  ]),

  rule('omniwm: layout management').manipulators([
    // tiling / floating
    map(deKey('t'), lCmdHyper).to$(omniwm('toggle-focused-window-floating')),
    // niri / dwindle
    map(deKey('v'), lCmdHyper).to$(omniwm('toggle-workspace-layout')),
    // dwindle: split orientation
    map(deKey('v'), lCmdShiftHyper).to$(omniwm('toggle-split')),
    // niri: tabbed column
    map(deKey('c'), lCmdHyper).to$(omniwm('toggle-column-tabbed')),
  ]),
]
