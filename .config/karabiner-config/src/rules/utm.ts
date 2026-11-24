import { ifApp, map, rule, type RuleBuilder } from 'karabiner.ts'
import { deKey } from '../keys.ts'

// QEMU passes key codes to the guest, which uses a German PC layout. The targets are
// therefore raw key codes as the guest reads them, not German labels.

export const utmRules: RuleBuilder[] = [
  rule('utm: qemu keyboard fix', ifApp('^com\\.utmapp\\.UTM$')).manipulators([
    // undo Apple's ISO key swap (see keys.ts); ^ is a dead key in the guest, so type it with a space
    map(deKey('^'), '?⇧').to([{ key_code: 'grave_accent_and_tilde' }, { key_code: 'spacebar' }]),
    map(deKey('<'), '?⇧').to('non_us_backslash'),
    // ´ is a dead key as well
    map(deKey('´')).to([{ key_code: 'equal_sign' }, { key_code: 'spacebar' }]),
  ]),
]
