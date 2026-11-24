import { map, simlayer } from 'karabiner.ts'
import { deKey, lAlt, lAltShift, lShift } from '../keys.ts'

// Programming symbols and navigation under the right hand and WASD. The targets are the
// key combinations that type each symbol on the German layout.
export const spaceFnLayer = simlayer(deKey('␣'), 'space fn').manipulators([
  map(deKey(',')).to(deKey('5'), lAlt), // [
  map(deKey('.')).to(deKey('6'), lAlt), // ]
  map(deKey('-')).to(deKey('7'), lAlt), // |
  map(deKey('ö')).to(deKey('8'), lAlt), // {
  map(deKey('ä')).to(deKey('9'), lAlt), // }
  map(deKey('ü')).to(deKey('8'), lShift), // (
  map(deKey('+')).to(deKey('9'), lShift), // )
  map(deKey('ß')).to(deKey('7'), lAltShift), // \

  map(deKey('w')).to(deKey('↑')),
  map(deKey('a')).to(deKey('←')),
  map(deKey('s')).to(deKey('↓')),
  map(deKey('d')).to(deKey('→')),

  map(deKey('q')).to('home'),
  map(deKey('e')).to('end'),
  map(deKey('↑')).to('page_up'),
  map(deKey('↓')).to('page_down'),

  // ⏎ and b still type ⏎ and space when they follow space within the simlayer threshold
  map(deKey('⏎')).to(deKey('⏎')),
  map(deKey('b')).to(deKey('␣')),
  map(deKey('t')).toPaste(' → '),
  map(deKey('c')).toPaste('```\n```'), // code block
])
