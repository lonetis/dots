import type { RuleBuilder } from 'karabiner.ts'
import { emojiLayer } from './emoji.ts'
import { karabinerLayer } from './karabiner.ts'
import { omniwmLayer } from './omniwm.ts'
import { settingsLayer } from './settings.ts'
import { spaceFnLayer } from './space-fn.ts'
import { symbolsLayer } from './symbols.ts'
import { tinycastLayer } from './tinycast.ts'

// Simlayers: hold the trigger key and press another one. One file per trigger key, and
// each trigger key gets exactly one simlayer: a second one on the same key would compete
// for the same key combinations. To use a taken trigger key, add to its file.
export const layers: RuleBuilder[] = [
  omniwmLayer, // a
  karabinerLayer, // k
  symbolsLayer, // s
  tinycastLayer, // r
  spaceFnLayer, // ␣
  settingsLayer, // ,
  emojiLayer, // .
]
