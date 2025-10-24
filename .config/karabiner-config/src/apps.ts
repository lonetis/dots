import { readFileSync } from 'fs'

// mdls -name kMDItemCFBundleIdentifier -r /Applications/Safari.app/
let apps: { [key: string]: string } = {}

try {
  const data = readFileSync('./src/apps.json', 'utf-8')
  apps = JSON.parse(data) as { [key: string]: string }
} catch (error) {
  console.error(`Error reading or parsing apps: ${error}`)
}

export default apps
