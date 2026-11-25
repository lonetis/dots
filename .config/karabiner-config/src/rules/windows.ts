import { map, rule, type RuleBuilder } from 'karabiner.ts'
import { omniwm, omniwmHelper, orElse } from '../commands.ts'
import { deKey, hyper, lCmd, lCmdHyper, lCmdShiftHyper, lCtrlHyper } from '../keys.ts'

// The focused window and the layout of its workspace: Hyper moves focus, left ⌘ + Hyper
// moves and resizes the window, left ⌃ + Hyper switches one-off controls such as
// fullscreen and floating. Workspaces use either OmniWM's niri layout (scrolling columns)
// or dwindle (binary splits). Where a command exists for one layout only, the binding
// falls back to the other's equivalent.

export const windowRules: RuleBuilder[] = [
  rule('omniwm: window management').manipulators([
    // focus
    map(deKey('↑'), hyper).to$(omniwm('focus up')),
    map(deKey('↓'), hyper).to$(omniwm('focus down')),
    map(deKey('←'), hyper).to$(omniwm('focus left')),
    map(deKey('→'), hyper).to$(omniwm('focus right')),
    // move (niri: swap columns left / right, reorder within the column up / down)
    map(deKey('↑'), lCmdHyper).to$(omniwm('move up')),
    map(deKey('↓'), lCmdHyper).to$(omniwm('move down')),
    map(deKey('←'), lCmdHyper).to$(omniwm('move left')),
    map(deKey('→'), lCmdHyper).to$(omniwm('move right')),
    // join (niri: consume into / expel from columns; dwindle: move the tile instead)
    map(deKey('↑'), lCmdShiftHyper).to$(orElse(omniwm('consume-window-into-column'), omniwm('move up'))),
    map(deKey('↓'), lCmdShiftHyper).to$(orElse(omniwm('expel-window-from-column'), omniwm('move down'))),
    map(deKey('←'), lCmdShiftHyper).to$(orElse(omniwm('consume-or-expel-window-left'), omniwm('move left'))),
    map(deKey('→'), lCmdShiftHyper).to$(orElse(omniwm('consume-or-expel-window-right'), omniwm('move right'))),

    // resize (niri: column width; dwindle: focused window)
    map(deKey('+'), lCmdHyper).to$(orElse(omniwm('set-container-primary-span +10%'), omniwm('resize-focused grow'))),
    map(deKey('-'), lCmdHyper).to$(orElse(omniwm('set-container-primary-span -10%'), omniwm('resize-focused shrink'))),
    // balance
    map(deKey('b'), lCtrlHyper).to$(omniwm('balance-sizes')),
    // cycle size presets (1/3, 1/2, 2/3)
    map(deKey('#'), lCmdHyper).to$(omniwm('cycle-size forward')),

    // fullscreen within OmniWM
    map(deKey('f'), lCtrlHyper).to$(omniwm('toggle-fullscreen')),
    // minimize
    map(deKey('m'), lCtrlHyper).to(deKey('m'), lCmd),

    // close the window
    map(deKey('w'), lCtrlHyper).to$(omniwm('close-focused-window')),
    // close every other window on the workspace
    map(deKey('⌫'), lCtrlHyper).to$(omniwmHelper('close-others')),
  ]),

  rule('omniwm: layout management').manipulators([
    // tiling / floating
    map(deKey('t'), lCtrlHyper).to$(omniwm('toggle-focused-window-floating')),
    // raise every floating window above the tiled ones
    map(deKey('r'), lCtrlHyper).to$(omniwm('raise-all-floating-windows')),
    // niri / dwindle
    map(deKey('l'), lCtrlHyper).to$(omniwm('toggle-workspace-layout')),
    // niri: tabbed column
    map(deKey('c'), lCtrlHyper).to$(omniwm('toggle-column-tabbed')),
  ]),
]
