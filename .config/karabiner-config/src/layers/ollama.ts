import { map, simlayer } from 'karabiner.ts'
import { tinycastExtension } from '../commands.ts'
import { deKey } from '../keys.ts'

// Rewrites the selected text with the Ollama extension (a Raycast extension, run by Tinycast).
export const ollamaLayer = simlayer(deKey('o'), 'ollama').manipulators([
  map(deKey('+')).to$(tinycastExtension('massimiliano_pasquini/raycast-ollama/ollama-longer')), // longer
  map(deKey('-')).to$(tinycastExtension('massimiliano_pasquini/raycast-ollama/ollama-shorter')), // shorter
])
