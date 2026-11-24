import { map, simlayer } from 'karabiner.ts'
import { notify } from '../commands.ts'
import { deKey } from '../keys.ts'

const projectDir = '~/.config/karabiner-config'

export const karabinerLayer = simlayer(deKey('k'), 'karabiner').manipulators([
  map(deKey('c')).to$(`code ${projectDir}`), // config
  // update the packages within their version ranges and rebuild; the output is lost, so
  // run `npm run build` in a terminal to see why a build failed
  map(deKey('r')).to$(
    `cd ${projectDir} && npm run update && npm run build && ${notify('reloaded karabiner config')} || ${notify('karabiner config build failed')}`,
  ),
])
