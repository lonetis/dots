// Builds the Karabiner-Elements rules and the OmniWM workspaces and app rules they rely
// on. Run `npm run build`. karabiner.ts docs: https://karabiner.ts.evanliu.dev
//
// src/
//   rules/          bindings with modifiers, one file per area
//   layers/         simlayers, one file per trigger key
//   apps.json       workspace key → bundle IDs, read by the rules, the OmniWM settings and scripts
//   workspaces.ts   workspace keys and their OmniWM names
//   keys.ts         German key labels and the modifier constants
//   commands.ts     shell commands the bindings run
//   conflicts.ts    build-time check for duplicate bindings
//   karabiner-json.ts             writes the rules to karabiner.json
//   omniwm-settings.ts, toml.ts   writes the generated parts of OmniWM's settings.toml
//   config.ts       output paths, overridable through the environment

import { complexModifications } from 'karabiner.ts'
import { config } from './config.ts'
import { assertNoConflicts } from './conflicts.ts'
import { writeProfileRules } from './karabiner-json.ts'
import { layers } from './layers/index.ts'
import { updateOmniWMSettings } from './omniwm-settings.ts'
import { rules } from './rules/index.ts'

const parameters = {
  'simlayer.threshold_milliseconds': 300, // time to press the second key of a simlayer (default 200)
}

// Build and check everything before writing anything, so a broken config leaves both
// Karabiner and OmniWM as they were.
const karabinerRules = complexModifications([...rules, ...layers], parameters)
assertNoConflicts(karabinerRules.rules)

updateOmniWMSettings()
writeProfileRules(config.karabinerJson, config.karabinerProfile, karabinerRules)
