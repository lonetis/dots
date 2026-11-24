import { map, simlayer } from 'karabiner.ts'
import { raycast } from '../commands.ts'
import { deKey } from '../keys.ts'

// Rewrites the selected text with the Raycast Ollama extension.
export const ollamaLayer = simlayer(deKey('o'), 'ollama').manipulators([
  map(deKey('+')).to$(raycast('massimiliano_pasquini/raycast-ollama/ollama-longer')), // longer
  map(deKey('-')).to$(raycast('massimiliano_pasquini/raycast-ollama/ollama-shorter')), // shorter
])
