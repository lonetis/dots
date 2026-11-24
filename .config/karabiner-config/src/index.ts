/*
Github: https://github.com/evan-liu/karabiner.ts
Documentation: https://karabiner.ts.evanliu.dev/
*/

import {
  map,
  rule,
  layer,
  simlayer,
  modifierLayer,
  withMapper,
  NumberKeyValue,
  writeToProfile,
  ifApp,
  FromModifierParam,
  to$,
  ifDevice,
  toApp,
  LayerKeyParam,
} from 'karabiner.ts'
import apps from './apps'
import de_key from './de_key'
import updateOmniWMSettings, { workspaceName } from './omniwm_settings'

/*
TODO:
- focus workspace on any display
- focus workspace on active display
- focus app on any display
- focus app on active display
- not working: modifierLayer(hyper, ',').description('Settings').leaderMode().notification().manipulators([])
*/

const hyper: FromModifierParam = {right: '⌘⌥⌃⇧'}
const lCmd: FromModifierParam = {left: '⌘'}
const lAlt: FromModifierParam = {left: '⌥'}
const lShift: FromModifierParam = {left: '⇧'}
const lCmdShift: FromModifierParam = {left: '⌘⇧'}
const lAltShift: FromModifierParam = {left: '⌥⇧'}
const lCmdAlt: FromModifierParam = {left: '⌘⌥'}
const lCmdHyper: FromModifierParam = {left: '⌘', right: '⌘⌥⌃⇧'}
const lAltHyper: FromModifierParam = {left: '⌥', right: '⌘⌥⌃⇧'}
const lCtrlHyper: FromModifierParam = {left: '⌃', right: '⌘⌥⌃⇧'}
const lCmdShiftHyper: FromModifierParam = {left: '⌘⇧', right: '⌘⌥⌃⇧'}
const lShiftHyper: FromModifierParam = {left: '⇧', right: '⌘⌥⌃⇧'}
const rCmd: FromModifierParam = {right: '⌘'}
const rCmdAlt: FromModifierParam = {right: '⌘⌥'}
const rCmdAltShift: FromModifierParam = {right: '⌘⌥⇧'}

const numbers = [...'1234567890']
const alphabet = [...'abcdefghijmnopqrstuvwxyzäöü']

updateOmniWMSettings()

const wm = '~/.config/omniwm/scripts'

writeToProfile('Default profile', [

  rule('hyperkey').manipulators([
    map('caps_lock', '?<⌘⌥⌃⇧').to('>⌘', '>⌥⌃⇧'),
  ]),

  rule('omniwm: search').manipulators([
    // search all windows
    map('⏎', hyper).to$('omniwmctl command open-command-palette windows'),
    // overview of all workspaces
    map('⏎', lShiftHyper).to$('omniwmctl command toggle-overview'),
  ]),

  rule('mission control').manipulators([
    map('⇥').toAfterKeyUp('⇥').toIfHeldDown({key_code: 'mission_control', halt: true}),
  ]),

  rule('logitech mx master 3: thumb button', ifDevice([{product_id: 50475, vendor_id: 1133}, {product_id: 45091, vendor_id: 1133}])).manipulators([
    map('⇥', lCmd).to('mission_control'),
  ]),

  rule('default stuff').manipulators([
    // open screenshot launcher
    map(de_key('4'), lCmdShift).to$('open -b com.apple.screenshot.launcher'),
    // open new window of focused app (not always supported)
    map('⏎', lAltShift).to$(`${wm}/new-window.sh`),
  ]),

  rule('omniwm: config').manipulators([
    // OmniWM has no on/off switch over IPC, so quit or relaunch it
    map(de_key('⎋'), lCmdHyper).to$(`pgrep -xq OmniWM && osascript -e 'quit app "OmniWM"' || open -a OmniWM`),
  ]),

  rule('omniwm: app management').manipulators([
    withMapper(apps)((ws, bid) =>
      map(de_key(ws), hyper).to$(`${wm}/cycle.sh ${bid} || open -b '${bid}'`),
    ),
    withMapper(apps)((ws, bid) =>
      map(de_key(ws), lCtrlHyper).to$(`${wm}/pull.sh ${bid}`),
    ),
    map(de_key('p'), hyper).to$(`${wm}/toggle.sh com.1password.1password`),
  ]),

  rule('omniwm: workspace management').manipulators([
    withMapper(numbers)((k) =>
      map(de_key(k), hyper).to$(`omniwmctl command switch-workspace ${workspaceName(k)}`),
    ),
    withMapper([...alphabet, ...numbers])((k) =>
      map(de_key(k), rCmd).to$(`${wm}/summon.sh ${k}`)
    ),
    withMapper([...alphabet, ...numbers])((k) =>
      map(de_key(k), rCmdAlt).to$(`${wm}/move-window.sh ${k}`)
    ),
    // focus to previous workspace
    map(de_key('^'), hyper).to$('omniwmctl command switch-workspace back-and-forth'),
    // focus to previous window or workspace if previous window is closed
    map(de_key('⇥'), hyper).to$('omniwmctl command focus previous || omniwmctl command switch-workspace back-and-forth'),
    // move window to default workspace or workspace q if it is already on its default workspace
    map(de_key('⎋'), hyper).to$(`${wm}/move-to-default.sh`),
    // move all windows to their default workspaces
    map(de_key('⎋'), lShiftHyper).to$(`${wm}/move-all-to-default.sh`),
  ]),

  rule('omniwm: window management').manipulators([
    // focus
    map(de_key('↑'), lCmdHyper).to$('omniwmctl command focus up'),
    map(de_key('↓'), lCmdHyper).to$('omniwmctl command focus down'),
    map(de_key('←'), lCmdHyper).to$('omniwmctl command focus left'),
    map(de_key('→'), lCmdHyper).to$('omniwmctl command focus right'),
    // move (niri: swap columns left / right, reorder within the column up / down)
    map(de_key('w'), lCmdHyper).to$('omniwmctl command move up'),
    map(de_key('s'), lCmdHyper).to$('omniwmctl command move down'),
    map(de_key('a'), lCmdHyper).to$('omniwmctl command move left'),
    map(de_key('d'), lCmdHyper).to$('omniwmctl command move right'),
    // join (niri: consume into / expel from columns; dwindle: join or extract tiles)
    map(de_key('k'), lCmdHyper).to$('omniwmctl command consume-window-into-column || omniwmctl command move up'),
    map(de_key('j'), lCmdHyper).to$('omniwmctl command expel-window-from-column || omniwmctl command move down'),
    map(de_key('h'), lCmdHyper).to$('omniwmctl command consume-or-expel-window-left || omniwmctl command move left'),
    map(de_key('l'), lCmdHyper).to$('omniwmctl command consume-or-expel-window-right || omniwmctl command move right'),

    // focus column by index
    withMapper([1, 2, 3, 4])((k) =>
      map(de_key(k), lCmdHyper).to$(`omniwmctl command focus-column ${k}`),
    ),

    // resize (niri: column width; dwindle: focused window)
    map(de_key('+'), lCmdHyper).to$('omniwmctl command set-container-primary-span +10% || omniwmctl command resize-focused grow'),
    map(de_key('-'), lCmdHyper).to$('omniwmctl command set-container-primary-span -10% || omniwmctl command resize-focused shrink'),
    // balance
    map(de_key('b'), lCmdHyper).to$('omniwmctl command balance-sizes'),
    // cycle size presets (1/3, 1/2, 2/3)
    map(de_key('#'), lCmdHyper).to$('omniwmctl command cycle-size forward'),

    // fullscreen
    map(de_key('f'), lCmdHyper).to$('omniwmctl command toggle-fullscreen'),
    // fullscreen native
    map(de_key('f'), lCmdShiftHyper).to$('omniwmctl command toggle-native-fullscreen'),
    // minimize window
    map(de_key('m'), lCmdHyper).to('m', lCmd),

    // close window
    map(de_key('x'), lCmdHyper).to$('omniwmctl command close-focused-window'),
    // quit window
    map(de_key('x'), lCmdShiftHyper).to$(`${wm}/close.sh --quit-if-last-window`),
    // close all but current window
    map(de_key('⌫'), lCmdHyper).to$(`${wm}/close-others.sh`),
    // quit all but current window
    map(de_key('⌫'), lCmdShiftHyper).to$(`${wm}/close-others.sh --quit-if-last-window`),
  ]),

  rule('omniwm: layout management').manipulators([
    // tiling / floating
    map(de_key('t'), lCmdHyper).to$('omniwmctl command toggle-focused-window-floating'),
    // niri / dwindle
    map(de_key('v'), lCmdHyper).to$('omniwmctl command toggle-workspace-layout'),
    // dwindle: toggle split orientation
    map(de_key('v'), lCmdShiftHyper).to$('omniwmctl command toggle-split'),
    // niri: tabbed column
    map(de_key('c'), lCmdHyper).to$('omniwmctl command toggle-column-tabbed'),
  ]),

  rule('omniwm: display management').manipulators([
    // move focused window to next monitor
    map(de_key('e'), lAltHyper).to$(`${wm}/move-window-to-display.sh next`),
    // move focused window to previous monitor
    map(de_key('q'), lAltHyper).to$(`${wm}/move-window-to-display.sh prev`),
    // move focused workspace to next monitor
    map(de_key('e'), lCmdHyper).to$(`${wm}/move-workspace.sh next`),
    // move focused workspace to previous monitor
    map(de_key('q'), lCmdHyper).to$(`${wm}/move-workspace.sh prev`),
    // move workspace to next monitor
    withMapper([...alphabet, ...numbers])((k) =>
      map(de_key(k), rCmdAltShift).to$(`${wm}/send-workspace.sh ${k}`)
    ),
  ]),

  rule('qemu keyboard fix', ifApp('^com\\.utmapp\\.UTM$')).manipulators([
    map('non_us_backslash', '?⇧').to([{key_code: 'grave_accent_and_tilde'}, {key_code: 'spacebar'}]),
    map('grave_accent_and_tilde', '?⇧').to('non_us_backslash'),
    map('equal_sign').to([{key_code: 'equal_sign'}, {key_code: 'spacebar'}]),
  ]),

  // OmniWM reloads settings.toml on save; r restarts it
  simlayer('a', 'omniwm').manipulators([
    map(de_key('c')).to$('code ~/.config/omniwm'),
    map(de_key('r')).to$('osascript -e \'quit app "OmniWM"\'; while pgrep -xq OmniWM; do sleep 0.2; done; open -a OmniWM && osascript -e \'display notification with title "restarted omniwm"\''),
  ]),

  simlayer('k', 'karabiner').manipulators([
    map(de_key('c')).to$('code ~/.config/karabiner-config'),
    map(de_key('r')).to$('cd ~/.config/karabiner-config/ && npm install && npm run update && npm run build && osascript -e \'display notification with title "reloaded karabiner config"\''),
  ]),

  // one simlayer per trigger key: a second simlayer('s', ...) would compete for the same s+key combos
  simlayer('s', 'symbols').manipulators([
    withMapper(['⌘', '⌥', '⌃', '⇧', '⇪'])((k, i) => map((i + 1) as NumberKeyValue).toPaste(k)),
    withMapper(['←', '→', '↑', '↓', '␣', '⏎', '⇥', '⎋', '⌫', '⌦'])((k) => map(k).toPaste(k)),
  ]),

  simlayer('o', 'ollama').manipulators([
    map(de_key('+')).to$('open -u raycast://extensions/massimiliano_pasquini/raycast-ollama/ollama-longer'), // longer
    map(de_key('-')).to$('open -u raycast://extensions/massimiliano_pasquini/raycast-ollama/ollama-shorter'), // shorter
  ]),

  simlayer('r', 'raycast').manipulators([
    map(de_key('b')).to$('open -u raycast://extensions/luolei/karakeep/bookmarks'), // bookmarks
    map(de_key('c')).to$('open -u raycast://extensions/thomas/visual-studio-code/index'), // recent code projects
    map(de_key('d')).to$('open -u raycast://extensions/GastroGeek/folder-search/search'), // directory search
    map(de_key('e')).to$('open -u raycast://extensions/raycast/emoji-symbols/search-emoji-symbols'), // emojis
    map(de_key('l')).to$('open -u raycast://extensions/raycast/calendar/my-schedule'), // calendar schedule
    map(de_key('m')).to$('open -u raycast://extensions/raycast/navigation/search-menu-items'), // menu bar
    map(de_key('p')).to$('open -u raycast://extensions/raycast/raycast/confetti'), // party confetti
    map(de_key('q')).to$('open -u raycast://extensions/mblode/quick-event/index'), // quick event
    map(de_key('s')).to$('open -u raycast://extensions/raycast/screenshots/search-screenshots'), // screenshots
    map(de_key('t')).to$('open -u raycast://extensions/raycast/snippets/search-snippets'), // snippets
    map(de_key('u')).to$('open -u raycast://extensions/cecelot/utm-virtual-machines/index'), // utm
    map(de_key('v')).to$('open -u raycast://extensions/SamuelNitsche/tunnelblick/index'), // vpn tunnelblick
    map(de_key('z')).to$('open -u raycast://extensions/reckoning-dev/zotero/commandSearchZotero'), // zotero
    map(de_key('␣')).to$('open -u raycast://extensions/raycast/file-search/search-files'), // file search
  ]),

  simlayer('␣', 'space fn').manipulators([
    map(de_key(',')).to('5', lAlt),      // [
    map(de_key('.')).to('6', lAlt),      // ]
    map(de_key('-')).to('7', lAlt),      // |
    map(de_key('ö')).to('8', lAlt),      // {
    map(de_key('ä')).to('9', lAlt),      // }
    map(de_key('ü')).to('8', lShift),    // (
    map(de_key('+')).to('9', lShift),    // )
    map(de_key('ß')).to('7', lAltShift), // \

    map(de_key('w')).to('↑'),
    map(de_key('a')).to('←'),
    map(de_key('s')).to('↓'),
    map(de_key('d')).to('→'),

    map(de_key('q')).to('home'),
    map(de_key('e')).to('end'),
    map(de_key('↑')).to('page_up'),
    map(de_key('↓')).to('page_down'),

    map(de_key('⏎')).to('⏎'), // enter
    map(de_key('b')).to('␣'), // space
    map(de_key('t')).toPaste(' → '), // to
    map(de_key('c')).toPaste('```\n```'), // code
  ]),

  simlayer(',', 'settings').manipulators([
    map(de_key('⏎')).to$("open -b com.apple.systempreferences"),
    map(de_key('a')).to$("open /System/Library/PreferencePanes/Sound.prefPane"), // audio
    map(de_key('b')).to$("open /System/Library/PreferencePanes/Bluetooth.prefPane"), // bluetooth
    map(de_key('d')).to$("open /System/Library/PreferencePanes/Displays.prefPane"), // display
    map(de_key('i')).to$("open -u raycast://extensions/benvp/audio-device/set-input-device"), // input
    map(de_key('n')).to$("open /System/Library/PreferencePanes/Network.prefPane"), // network
    map(de_key('o')).to$("open -u raycast://extensions/benvp/audio-device/set-output-device"), // output
    map(de_key('s')).to$("open /System/Library/PreferencePanes/Security.prefPane"), // security
  ]),

  simlayer('.', 'emoji').manipulators([
    map(de_key('0')).toPaste('0️⃣'),
    map(de_key('1')).toPaste('1️⃣'),
    map(de_key('2')).toPaste('2️⃣'),
    map(de_key('3')).toPaste('3️⃣'),
    map(de_key('4')).toPaste('4️⃣'),
    map(de_key('5')).toPaste('5️⃣'),
    map(de_key('6')).toPaste('6️⃣'),
    map(de_key('7')).toPaste('7️⃣'),
    map(de_key('8')).toPaste('8️⃣'),
    map(de_key('9')).toPaste('9️⃣'),

    map(de_key('→')).toPaste('➡️'),
    map(de_key('←')).toPaste('⬅️'),
    map(de_key('↑')).toPaste('⬆️'),
    map(de_key('↓')).toPaste('⬇️'),

    map(de_key('a')).toPaste('⚠️'), // Alert
    map(de_key('b')).toPaste('😁'), // Beaming
    map(de_key('c')).toPaste('✅'), // Check
    map(de_key('d')).toPaste('🤷‍♂️'), // Don't know
    map(de_key('e')).toPaste('🤯'), // Exploding
    map(de_key('g')).toPaste('😃'), // Grinning
    map(de_key('h')).toPaste('❤️'),  // Heart
    map(de_key('i')).toPaste('ℹ️'), // Info
    map(de_key('j')).toPaste('😂'), // Joy
    map(de_key('k')).toPaste('👌'), // oK
    map(de_key('m')).toPaste('🫠'), // Melting
    map(de_key('n')).toPaste('👎'), // No
    map(de_key('o')).toPaste('🆗'), // Ok
    map(de_key('q')).toPaste('❓'), // Question mark
    map(de_key('r')).toPaste('🤣'), // Rolling
    map(de_key('s')).toPaste('🙂'), // Smile
    map(de_key('u')).toPaste('🙃'), // Upside down
    map(de_key('w')).toPaste('😉'), // Wink
    map(de_key('x')).toPaste('❌'), // eXclamation mark
    map(de_key('y')).toPaste('👍'), // Yes
  ]),

], {
  'simlayer.threshold_milliseconds': 300 // default: 200
})
