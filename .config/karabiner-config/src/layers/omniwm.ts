import { map, simlayer } from 'karabiner.ts'
import { restartApp } from '../commands.ts'
import { deKey } from '../keys.ts'

// OmniWM reloads settings.toml on save, so a restart is only needed when it misbehaves.
export const omniwmLayer = simlayer(deKey('a'), 'omniwm').manipulators([
  map(deKey('c')).to$('code ~/.config/omniwm'), // config
  map(deKey('r')).to$(restartApp('OmniWM')), // restart
])
