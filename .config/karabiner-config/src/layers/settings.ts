import { map, simlayer } from 'karabiner.ts'
import { raycast, systemSettings } from '../commands.ts'
import { deKey } from '../keys.ts'

// System Settings panes are opened by the bundle ID of their extension, listed with:
//   for e in /System/Library/ExtensionKit/Extensions/*.appex; do defaults read "$e/Contents/Info" CFBundleIdentifier; done
export const settingsLayer = simlayer(deKey(','), 'settings').manipulators([
  map(deKey('⏎')).to$(systemSettings()),
  map(deKey('a')).to$(systemSettings('com.apple.Sound-Settings.extension')), // audio
  map(deKey('b')).to$(systemSettings('com.apple.BluetoothSettings')), // bluetooth
  map(deKey('d')).to$(systemSettings('com.apple.Displays-Settings.extension')), // displays
  map(deKey('i')).to$(raycast('benvp/audio-device/set-input-device')), // audio input
  map(deKey('n')).to$(systemSettings('com.apple.Network-Settings.extension')), // network
  map(deKey('o')).to$(raycast('benvp/audio-device/set-output-device')), // audio output
  map(deKey('s')).to$(systemSettings('com.apple.settings.PrivacySecurity.extension')), // privacy & security
])
