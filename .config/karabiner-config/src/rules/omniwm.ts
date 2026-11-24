import { map, rule, type RuleBuilder } from 'karabiner.ts'
import { omniwm, toggleApp } from '../commands.ts'
import { deKey, hyper, lCmdAlt, lCmdHyper, lShiftHyper } from '../keys.ts'

// OmniWM itself. Every OmniWM binding lives in Karabiner; OmniWM's own hotkeys are off
// (hotkeysEnabled = false in ~/.config/omniwm/settings.toml).

export const omniwmRules: RuleBuilder[] = [
  rule('omniwm: search').manipulators([
    // search all windows
    map(deKey('⏎'), hyper).to$(omniwm('open-command-palette windows')),
    // overview of all workspaces
    map(deKey('⏎'), lShiftHyper).to$(omniwm('toggle-overview')),
  ]),

  rule('omniwm: quake terminal').manipulators([
    // OmniWM's built-in Ghostty quake terminal ([quakeTerminal] in settings.toml)
    map(deKey('⏎'), lCmdAlt).to$(omniwm('toggle-quake-terminal')),
  ]),

  rule('omniwm: on/off').manipulators([
    // OmniWM can't be turned off over IPC, so quit or launch it
    map(deKey('⎋'), lCmdHyper).to$(toggleApp('OmniWM')),
  ]),
]
