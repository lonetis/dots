import { map, simlayer, withMapper, type NumberKeyValue } from 'karabiner.ts'
import { deKey } from '../keys.ts'

// Types the symbols of modifier and special keys, e.g. for writing about shortcuts.
export const symbolsLayer = simlayer(deKey('s'), 'symbols').manipulators([
  // 1–5: modifiers
  withMapper(['⌘', '⌥', '⌃', '⇧', '⇪'] as const)((symbol, index) => map(deKey((index + 1) as NumberKeyValue)).toPaste(symbol)),
  // each key pastes its own symbol
  withMapper(['←', '→', '↑', '↓', '␣', '⏎', '⇥', '⎋', '⌫', '⌦'] as const)((key) => map(deKey(key)).toPaste(key)),
])
