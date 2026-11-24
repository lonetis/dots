import { homedir } from 'node:os'
import { join } from 'node:path'

// Where the build writes. The defaults are the live configs. Point the variables at
// copies to try a build without touching Karabiner or OmniWM.
export const config = {
  karabinerJson: process.env.KARABINER_JSON || join(homedir(), '.config/karabiner/karabiner.json'), // receives the rules
  karabinerProfile: process.env.KARABINER_PROFILE || 'Default profile', // profile in karabiner.json whose rules are replaced
  omniwmSettings: process.env.OMNIWM_SETTINGS || join(homedir(), '.config/omniwm/settings.toml'), // same variable as the OmniWM scripts
}
