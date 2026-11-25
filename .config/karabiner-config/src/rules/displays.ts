import { map, rule, type RuleBuilder } from 'karabiner.ts'
import { omniwmScript } from '../commands.ts'
import { deKey, lAltHyper, lCmdHyper } from '../keys.ts'

// Windows and workspaces between displays: left ⌘ + Hyper moves the window, left ⌥ + Hyper
// the workspace. The scripts step along the rows of the monitor grid from OmniWM's Monitor
// Setup (left to right without one), wrap around at the last display and route over the
// grid, because OmniWM itself only moves a workspace to an adjacent display.

export const displayRules: RuleBuilder[] = [
  rule('omniwm: display management').manipulators([
    // move the focused window to the display on the left / right
    map(deKey(','), lCmdHyper).to$(omniwmScript('move-window-to-display', 'prev')),
    map(deKey('.'), lCmdHyper).to$(omniwmScript('move-window-to-display', 'next')),
    // move the focused workspace to the display on the left / right
    map(deKey(','), lAltHyper).to$(omniwmScript('move-workspace', 'prev')),
    map(deKey('.'), lAltHyper).to$(omniwmScript('move-workspace', 'next')),
  ]),
]
