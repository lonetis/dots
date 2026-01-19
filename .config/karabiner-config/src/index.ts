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
import updateDefaultWorkspaces from './update_default_workspaces'

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

updateDefaultWorkspaces()

writeToProfile('Default profile', [

  rule('hyperkey').manipulators([
    map('caps_lock', '?<⌘⌥⌃⇧').to('>⌘', '>⌥⌃⇧'),
  ]),

  rule('raycast extension pull window').manipulators([
    map('⏎', hyper).to$('open -u raycast://extensions/chearix/raycast-extension-pull-window/windows'),
    map('⏎', lShiftHyper).to$('open -u raycast://extensions/chearix/raycast-extension-pull-window/workspaces'),
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
    map('⏎', lAltShift).to$(`open -n -b $(aerospace list-windows --focused --format '%{app-bundle-id}')`),
  ]),

  rule('aerospace: config').manipulators([
    map(de_key('⎋'), lCmdHyper).to$('aerospace enable toggle'),
  ]),

  rule('aerospace: app management').manipulators([
    withMapper(apps)((ws, bid) =>
      map(de_key(ws), hyper).to$(`bash ~/.config/aerospace/cycle_windows.bash ${bid} || open -b '${bid}'`),
    ),
    withMapper(apps)((ws, bid) =>
      map(de_key(ws), lCtrlHyper).to$(`bash ~/.config/aerospace/pull_windows_restore.bash ${bid}`),
    ),
    map(de_key('p'), hyper).to$('bash ~/.config/aerospace/toggle_app.bash com.1password.1password'),
  ]),

  rule('aerospace: workspace management').manipulators([
    withMapper(numbers)((k) =>
      map(de_key(k), hyper).to$(`aerospace workspace ${k}`),
    ),
    withMapper([...alphabet, ...numbers])((k) =>
      map(de_key(k), rCmd).to$(`bash ~/.config/aerospace/summon_workspace_swap.bash ${k}`)
    ),
    withMapper([...alphabet, ...numbers])((k) =>
      map(de_key(k), rCmdAlt).to$(`aerospace move-node-to-workspace ${k} --focus-follows-window`)
    ),
    // focus to previous workspace
    map(de_key('^'), hyper).to$('aerospace workspace-back-and-forth'),
    // focus to previous window or workspace if previous window is closed
    map(de_key('⇥'), hyper).to$('aerospace focus-back-and-forth || aerospace workspace-back-and-forth'),
    // move node to default workspace or workspace q if it is already on its default workspace
    map(de_key('⎋'), hyper).to$('bash ~/.config/aerospace/move_node_to_default_workspace.bash'),
    // move all nodes to default workspaces or workspace q if they are already on their default workspaces
    map(de_key('⎋'), lShiftHyper).to$('bash ~/.config/aerospace/move_all_nodes_to_default_workspace.bash'),
  ]),

  rule('aerospace: window management').manipulators([
    // focus
    map(de_key('↑'), lCmdHyper).to$('aerospace focus up'),
    map(de_key('↓'), lCmdHyper).to$('aerospace focus down'),
    map(de_key('←'), lCmdHyper).to$('aerospace focus left'),
    map(de_key('→'), lCmdHyper).to$('aerospace focus right'),
    // move
    map(de_key('w'), lCmdHyper).to$('aerospace move up'),
    map(de_key('s'), lCmdHyper).to$('aerospace move down'),
    map(de_key('a'), lCmdHyper).to$('aerospace move left'),
    map(de_key('d'), lCmdHyper).to$('aerospace move right'),
    // join
    map(de_key('k'), lCmdHyper).to$('aerospace join-with up'),
    map(de_key('j'), lCmdHyper).to$('aerospace join-with down'),
    map(de_key('h'), lCmdHyper).to$('aerospace join-with left'),
    map(de_key('l'), lCmdHyper).to$('aerospace join-with right'),

    // focus by dfs index
    withMapper([1, 2, 3, 4])((k) =>
      map(de_key(k), lCmdHyper).to$(`aerospace focus --dfs-index ${k-1}`),
    ),

    // resize
    map(de_key('+'), lCmdHyper).to$('aerospace resize smart +200'),
    map(de_key('-'), lCmdHyper).to$('aerospace resize smart -200'),
    // balance
    map(de_key('b'), lCmdHyper).to$('aerospace balance-sizes'),
    // flatten
    map(de_key('#'), lCmdHyper).to$('aerospace flatten-workspace-tree'),

    // fullscreen
    map(de_key('f'), lCmdHyper).to$('aerospace fullscreen'),
    // fullscreen native
    map(de_key('f'), lCmdShiftHyper).to$('aerospace macos-native-fullscreen'),
    // minimize window
    map(de_key('m'), lCmdHyper).to$('aerospace macos-native-minimize'),

    // close window
    map(de_key('x'), lCmdHyper).to$('aerospace close'),
    // quit window
    map(de_key('x'), lCmdShiftHyper).to$('aerospace close --quit-if-last-window'),
    // close all but current window
    map(de_key('⌫'), lCmdHyper).to$('aerospace close-all-windows-but-current'),
    // quit all but current window
    map(de_key('⌫'), lCmdShiftHyper).to$('aerospace close-all-windows-but-current --quit-if-last-window'),
  ]),

  rule('aerospace: layout management').manipulators([
    // tiling / floating
    map(de_key('t'), lCmdHyper).to$('aerospace layout floating tiling'),
    // tiles
    map(de_key('v'), lCmdHyper).to$('aerospace layout tiles vertical horizontal'),
    // accordion
    map(de_key('c'), lCmdHyper).to$('aerospace layout accordion horizontal vertical'),
  ]),

  rule('aerospace: display management').manipulators([
    // move focused window to next monitor
    map(de_key('e'), lAltHyper).to$('aerospace move-node-to-monitor --focus-follows-window --wrap-around next'),
    // move focused window to previous monitor
    map(de_key('q'), lAltHyper).to$('aerospace move-node-to-monitor --focus-follows-window --wrap-around prev'),
    // move focused workspace to next monitor
    map(de_key('e'), lCmdHyper).to$('aerospace move-workspace-to-monitor --wrap-around next && aerospace move-mouse monitor-lazy-center'),
    // move focused workspace to previous monitor
    map(de_key('q'), lCmdHyper).to$('aerospace move-workspace-to-monitor --wrap-around prev && aerospace move-mouse monitor-lazy-center'),
    // move workspace to next monitor
    withMapper([...alphabet, ...numbers])((k) =>
      map(de_key(k), rCmdAltShift).to$(`aerospace move-workspace-to-monitor --workspace ${k} --wrap-around next && aerospace focus-monitor --wrap-around next`)
    ),
  ]),

  rule('qemu keyboard fix', ifApp('^com\\.utmapp\\.UTM$')).manipulators([
    map('non_us_backslash', '?⇧').to([{key_code: 'grave_accent_and_tilde'}, {key_code: 'spacebar'}]),
    map('grave_accent_and_tilde', '?⇧').to('non_us_backslash'),
    map('equal_sign').to([{key_code: 'equal_sign'}, {key_code: 'spacebar'}]),
  ]),

  simlayer('a', 'aerospace').manipulators([
    map(de_key('c')).to$('code ~/.config/aerospace'),
    map(de_key('r')).to$('aerospace reload-config && osascript -e \'display notification with title "reloaded aerospace config"\''),
  ]),

  simlayer('k', 'karabiner').manipulators([
    map(de_key('c')).to$('code ~/.config/karabiner-config'),
    map(de_key('r')).to$('cd ~/.config/karabiner-config/ && npm run build && osascript -e \'display notification with title "reloaded karabiner config"\''),
  ]),

  simlayer('s', 'sketchybar').manipulators([
    map(de_key('c')).to$('code ~/.config/sketchybar'),
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

  simlayer('s', 'symbols').manipulators([
    withMapper(['⌘', '⌥', '⌃', '⇧', '⇪'])((k, i) => map((i + 1) as NumberKeyValue).toPaste(k)),
    withMapper(['←', '→', '↑', '↓', '␣', '⏎', '⇥', '⎋', '⌫', '⌦'])((k) => map(k).toPaste(k)),
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
