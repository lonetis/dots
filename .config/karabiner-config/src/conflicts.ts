import type { BasicManipulator, Rule } from 'karabiner.ts'

// Karabiner applies the first manipulator that matches an event, so a binding with the
// same trigger and conditions as an earlier one never fires. This turns that into a build
// error, e.g. when apps.json gains a key that another Hyper binding already uses, or when
// two simlayers share a trigger key and map the same second key.
//
// Only exact duplicates are caught. A binding with optional modifiers that shadows one
// with mandatory modifiers on the same key goes unnoticed.

/** Throws when two manipulators react to the same trigger under the same conditions. */
export function assertNoConflicts(rules: Rule[]): void {
  const firstRuleOfTrigger = new Map<string, string>()
  const conflicts: string[] = []

  for (const rule of rules) {
    for (const manipulator of rule.manipulators) {
      if (manipulator.type !== 'basic') continue
      const trigger = triggerOf(manipulator)
      const firstRule = firstRuleOfTrigger.get(trigger)
      if (firstRule === undefined) firstRuleOfTrigger.set(trigger, rule.description)
      else conflicts.push(`- "${rule.description}" repeats a binding of "${firstRule}": ${JSON.stringify(manipulator.from)}`)
    }
  }

  if (conflicts.length > 0) throw new Error(`conflicting bindings:\n${conflicts.join('\n')}`)
}

// The options of a simultaneous trigger hold what happens on key up (a simlayer turns its
// variable off there), not what triggers it. Key order and modifier order don't matter.
function triggerOf({ from, conditions }: BasicManipulator): string {
  const { simultaneous_options: _, ...trigger } = from as typeof from & { simultaneous_options?: unknown }
  return JSON.stringify({ from: trigger, conditions: conditions ?? [] }, (key, value: unknown) => {
    if (Array.isArray(value)) return key === 'mandatory' || key === 'optional' ? [...value].sort() : value
    if (typeof value === 'object' && value !== null) {
      return Object.fromEntries(Object.entries(value).sort(([a], [b]) => (a < b ? -1 : a > b ? 1 : 0)))
    }
    return value
  })
}
