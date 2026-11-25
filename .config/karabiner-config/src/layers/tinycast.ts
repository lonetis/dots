import { map, simlayer } from 'karabiner.ts'
import { tinycast, tinycastExtension } from '../commands.ts'
import { deKey } from '../keys.ts'

// Tinycast commands. A command's deeplink is in Tinycast's action panel ("Copy Deeplink", ⇧⌘C).
export const tinycastLayer = simlayer(deKey('r'), 'tinycast').manipulators([
  map(deKey('b')).to$(tinycastExtension('luolei/karakeep/bookmarks')), // bookmarks
  map(deKey('c')).to$(tinycastExtension('thomas/visual-studio-code/index')), // recent code projects
  map(deKey('d')).to$(tinycastExtension('GastroGeek/folder-search/search')), // directory search
  map(deKey('e')).to$(tinycast('search-emoji')), // emojis
  map(deKey('l')).to$(tinycast('my-schedule')), // calendar schedule
  map(deKey('m')).to$(tinycast('search-menu-items')), // menu bar
  map(deKey('q')).to$(tinycastExtension('mblode/quick-event/index')), // quick event
  map(deKey('s')).to$(tinycast('search-files', '~/Documents/Screenshots/')), // screenshots
  map(deKey('t')).to$(tinycast('search-snippets')), // snippets
  map(deKey('u')).to$(tinycastExtension('cecelot/utm-virtual-machines/index')), // utm
  map(deKey('v')).to$(tinycastExtension('SamuelNitsche/tunnelblick/index')), // vpn tunnelblick
  map(deKey('z')).to$(tinycastExtension('reckoning-dev/zotero/commandSearchZotero')), // zotero
  map(deKey('␣')).to$(tinycast('search-files')), // file search
])
