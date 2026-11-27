import { map, rule, type RuleBuilder } from 'karabiner.ts'
import { tinycast, tinycastExtension } from '../commands.ts'
import { deKey, lCmd, lCmdAlt, lCtrlAlt } from '../keys.ts'

// Tinycast's shortcuts, as deeplinks. The r simlayer (layers/tinycast.ts) holds more of its
// commands.

// A deeplink only opens the launcher, so the launcher key sends the one hotkey Tinycast
// binds itself, its "Show Launcher", which also closes it: a combo no keyboard has.
const tinycastLauncherHotkey = [deKey('f19'), '⌘⌥⌃⇧'] as const

export const tinycastRules: RuleBuilder[] = [
  rule('tinycast: launcher').manipulators([
    map(deKey('␣'), lCmd).to(...tinycastLauncherHotkey), // toggle the launcher
    map(deKey('␣'), lCmdAlt).to$(tinycast('clipboard-history')), // clipboard history
    map(deKey('e'), lCtrlAlt).to$(tinycast('search-emoji')), // emojis
  ]),

  rule('tinycast: reponizer').manipulators([
    map(deKey('r'), lCtrlAlt).to$(tinycastExtension('lonetis/reponizer/search-repos')), // search repositories
    map(deKey('c'), lCtrlAlt).to$(tinycastExtension('lonetis/reponizer/create-repo')), // create a repository
  ]),
]
