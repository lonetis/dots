import { map, simlayer } from 'karabiner.ts'
import { deKey } from '../keys.ts'

// Letters are mnemonics for the emoji's name.
export const emojiLayer = simlayer(deKey('.'), 'emoji').manipulators([
  map(deKey('0')).toPaste('0️⃣'),
  map(deKey('1')).toPaste('1️⃣'),
  map(deKey('2')).toPaste('2️⃣'),
  map(deKey('3')).toPaste('3️⃣'),
  map(deKey('4')).toPaste('4️⃣'),
  map(deKey('5')).toPaste('5️⃣'),
  map(deKey('6')).toPaste('6️⃣'),
  map(deKey('7')).toPaste('7️⃣'),
  map(deKey('8')).toPaste('8️⃣'),
  map(deKey('9')).toPaste('9️⃣'),

  map(deKey('→')).toPaste('➡️'),
  map(deKey('←')).toPaste('⬅️'),
  map(deKey('↑')).toPaste('⬆️'),
  map(deKey('↓')).toPaste('⬇️'),

  map(deKey('a')).toPaste('⚠️'), // alert
  map(deKey('b')).toPaste('😁'), // beaming
  map(deKey('c')).toPaste('✅'), // check
  map(deKey('d')).toPaste('🤷‍♂️'), // don't know
  map(deKey('e')).toPaste('🤯'), // exploding
  map(deKey('g')).toPaste('😃'), // grinning
  map(deKey('h')).toPaste('❤️'), // heart
  map(deKey('i')).toPaste('ℹ️'), // info
  map(deKey('j')).toPaste('😂'), // joy
  map(deKey('k')).toPaste('👌'), // ok
  map(deKey('m')).toPaste('🫠'), // melting
  map(deKey('n')).toPaste('👎'), // no
  map(deKey('o')).toPaste('🆗'), // ok
  map(deKey('q')).toPaste('❓'), // question mark
  map(deKey('r')).toPaste('🤣'), // rolling
  map(deKey('s')).toPaste('🙂'), // smile
  map(deKey('u')).toPaste('🙃'), // upside down
  map(deKey('w')).toPaste('😉'), // wink
  map(deKey('x')).toPaste('❌'), // cross
  map(deKey('y')).toPaste('👍'), // yes
])
