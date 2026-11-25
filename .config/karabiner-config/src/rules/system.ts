import { ifDevice, map, rule, type RuleBuilder } from 'karabiner.ts'
import { deKey, lCmd, lCmdShift } from '../keys.ts'

// macOS-wide keys that have nothing to do with window management.

// Logitech (vendor 1133) MX Master 3, through the Unifying receiver (0xC52B) and over
// Bluetooth (0xB023).
const mxMaster3 = ifDevice([
  { vendor_id: 1133, product_id: 50475 },
  { vendor_id: 1133, product_id: 45091 },
])

export const systemRules: RuleBuilder[] = [
  rule('hyper key').manipulators([
    // Caps Lock becomes right ⌘⌥⌃⇧, so left modifiers can add to it (see keys.ts)
    map('caps_lock', '?<⌘⌥⌃⇧').to('>⌘', '>⌥⌃⇧'),
  ]),

  rule('mission control').manipulators([
    // tap for ⇥, hold for Mission Control
    map(deKey('⇥')).toAfterKeyUp(deKey('⇥')).toIfHeldDown({ key_code: 'mission_control', halt: true }),
  ]),

  rule('logitech mx master 3: thumb button', mxMaster3).manipulators([
    // the thumb button sends ⌘⇥, which opens Mission Control instead of the app switcher
    map(deKey('⇥'), lCmd).to('mission_control'),
  ]),

  rule('macos shortcuts').manipulators([
    // the Screenshot app instead of the area capture
    map(deKey('4'), lCmdShift).to$('open -b com.apple.screenshot.launcher'),
  ]),
]
