import type { FromKeyParam, ModifierParam } from 'karabiner.ts'

// --- Keys --------------------------------------------------------------------------

// Karabiner names keys after their position on a US keyboard, but this config is written
// for a German Mac keyboard: keys are given by the label printed on them and translated
// here. Wrap every key in deKey(), also the ones whose label matches, because some labels
// are karabiner.ts aliases for a different key (its '-' is the US hyphen key, the German ß).
const germanKeyCodes = {
  '^': 'non_us_backslash', // Apple ISO keyboards swap the key left of 1 ...
  '<': 'grave_accent_and_tilde', // ... with the key right of left ⇧
  'ß': 'hyphen',
  '´': 'equal_sign',
  'ü': 'open_bracket',
  '+': 'close_bracket',
  'ö': 'semicolon',
  'ä': 'quote',
  '#': 'backslash',
  'y': 'z',
  'z': 'y',
  ',': 'comma',
  '.': 'period',
  '-': 'slash',
} as const satisfies Record<string, FromKeyParam>

type GermanKey = keyof typeof germanKeyCodes

/** A key label on the German keyboard, or a karabiner.ts key that has no German label. */
export type Key = GermanKey | FromKeyParam

/** Translates a German key label to the key code Karabiner expects. */
export function deKey<K extends Key>(key: K): K extends GermanKey ? (typeof germanKeyCodes)[K] : K {
  const keyCode = Object.hasOwn(germanKeyCodes, key) ? germanKeyCodes[key as GermanKey] : key
  return keyCode as K extends GermanKey ? (typeof germanKeyCodes)[K] : K
}

// --- Modifiers ---------------------------------------------------------------------

// Rules tell left and right modifiers apart: Hyper holds all four right modifiers, so a
// left modifier on top of it gives a separate set of bindings. Reuse these constants
// instead of writing modifiers inline.

/** Caps Lock, see the hyper key rule in rules/system.ts. */
export const hyper: ModifierParam = { right: '⌘⌥⌃⇧' }

export const lCmd: ModifierParam = { left: '⌘' }
export const lAlt: ModifierParam = { left: '⌥' }
export const lShift: ModifierParam = { left: '⇧' }
export const lCmdShift: ModifierParam = { left: '⌘⇧' }
export const lAltShift: ModifierParam = { left: '⌥⇧' }
export const lCmdAlt: ModifierParam = { left: '⌘⌥' }
export const lCtrlAlt: ModifierParam = { left: '⌥⌃' }

export const lCmdHyper: ModifierParam = { left: '⌘', right: '⌘⌥⌃⇧' }
export const lAltHyper: ModifierParam = { left: '⌥', right: '⌘⌥⌃⇧' }
export const lCtrlHyper: ModifierParam = { left: '⌃', right: '⌘⌥⌃⇧' }
export const lShiftHyper: ModifierParam = { left: '⇧', right: '⌘⌥⌃⇧' }
export const lCmdShiftHyper: ModifierParam = { left: '⌘⇧', right: '⌘⌥⌃⇧' }
export const lAltShiftHyper: ModifierParam = { left: '⌥⇧', right: '⌘⌥⌃⇧' }
export const lCmdAltHyper: ModifierParam = { left: '⌘⌥', right: '⌘⌥⌃⇧' }

export const rCmd: ModifierParam = { right: '⌘' }
export const rCmdAlt: ModifierParam = { right: '⌘⌥' }
export const rCmdAltShift: ModifierParam = { right: '⌘⌥⇧' }
