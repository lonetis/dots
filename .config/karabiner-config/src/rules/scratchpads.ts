import { map, rule, withMapper, type RuleBuilder } from 'karabiner.ts'
import { omniwm } from '../commands.ts'
import { deKey, rCmd, rCmdAlt } from '../keys.ts'

// OmniWM's scratchpads on right ⌘ plus a digit. OmniWM numbers them 1–10, so the digits
// pick them in keyboard order and 0 is scratchpad 10, like workspace 10.
const scratchpadKeys = ['1', '2', '3', '4', '5', '6', '7', '8', '9', '0'] as const

export const scratchpadRules: RuleBuilder[] = [
  rule('omniwm: scratchpad management').manipulators([
    // show or hide the scratchpad
    withMapper(scratchpadKeys)((key, index) =>
      map(deKey(key), rCmd).to$(omniwm(`scratchpad toggle ${index + 1}`)),
    ),
    // assign the focused window to the scratchpad, or take it out again
    withMapper(scratchpadKeys)((key, index) =>
      map(deKey(key), rCmdAlt).to$(omniwm(`scratchpad assign ${index + 1}`)),
    ),
  ]),
]
