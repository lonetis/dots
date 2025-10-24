import fs from 'fs'
import path from 'path'
import apps from './apps'
import { homedir } from 'os'

const aerospaceConfigPath = path.resolve(homedir(), '.config/aerospace/aerospace.toml')

function updateDefaultWorkspaces() {
  const aerospaceConfig = fs.readFileSync(aerospaceConfigPath, 'utf-8')
  const beginMarker = '##### BEGIN DEFAULT WORKSPACES #####'
  const endMarker = '##### END DEFAULT WORKSPACES #####'

  const beginIndex = aerospaceConfig.indexOf(beginMarker) + beginMarker.length
  const endIndex = aerospaceConfig.indexOf(endMarker)

  const newAssignments = Object.entries(apps).map(([ws, bid]) => {
    return `[[on-window-detected]]\nif.app-id = '${bid}'\nrun = 'move-node-to-workspace ${ws}'\ncheck-further-callbacks = true`
  }).join('\n')

  const updatedConfig = aerospaceConfig.slice(0, beginIndex) + '\n' + newAssignments + '\n' + aerospaceConfig.slice(endIndex)

  fs.writeFileSync(aerospaceConfigPath, updatedConfig, 'utf-8')
}

export default updateDefaultWorkspaces
