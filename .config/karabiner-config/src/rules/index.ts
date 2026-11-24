import type { RuleBuilder } from 'karabiner.ts'
import { appRules } from './apps.ts'
import { displayRules } from './displays.ts'
import { omniwmRules } from './omniwm.ts'
import { systemRules } from './system.ts'
import { utmRules } from './utm.ts'
import { windowRules } from './windows.ts'
import { workspaceRules } from './workspaces.ts'

// Rules that bind keys with modifiers, one file per area. Karabiner tries them in this
// order and applies the first match. The build rejects exact duplicates (conflicts.ts),
// so the order only matters for bindings that overlap through optional modifiers.
export const rules: RuleBuilder[] = [
  ...systemRules,
  ...omniwmRules,
  ...appRules,
  ...workspaceRules,
  ...windowRules,
  ...displayRules,
  ...utmRules,
]
