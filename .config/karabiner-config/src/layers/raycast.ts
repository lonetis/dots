import { map, simlayer } from 'karabiner.ts'
import { raycast } from '../commands.ts'
import { deKey } from '../keys.ts'

// Raycast commands. A command's deeplink is in Raycast's action panel ("Copy Deeplink").
export const raycastLayer = simlayer(deKey('r'), 'raycast').manipulators([
  map(deKey('b')).to$(raycast('luolei/karakeep/bookmarks')), // bookmarks
  map(deKey('c')).to$(raycast('thomas/visual-studio-code/index')), // recent code projects
  map(deKey('d')).to$(raycast('GastroGeek/folder-search/search')), // directory search
  map(deKey('e')).to$(raycast('raycast/emoji-symbols/search-emoji-symbols')), // emojis
  map(deKey('l')).to$(raycast('raycast/calendar/my-schedule')), // calendar schedule
  map(deKey('m')).to$(raycast('raycast/navigation/search-menu-items')), // menu bar
  map(deKey('p')).to$(raycast('raycast/raycast/confetti')), // party confetti
  map(deKey('q')).to$(raycast('mblode/quick-event/index')), // quick event
  map(deKey('s')).to$(raycast('raycast/screenshots/search-screenshots')), // screenshots
  map(deKey('t')).to$(raycast('raycast/snippets/search-snippets')), // snippets
  map(deKey('u')).to$(raycast('cecelot/utm-virtual-machines/index')), // utm
  map(deKey('v')).to$(raycast('SamuelNitsche/tunnelblick/index')), // vpn tunnelblick
  map(deKey('z')).to$(raycast('reckoning-dev/zotero/commandSearchZotero')), // zotero
  map(deKey('␣')).to$(raycast('raycast/file-search/search-files')), // file search
])
