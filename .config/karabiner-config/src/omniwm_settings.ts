import { createHash } from 'crypto'
import fs from 'fs'
import path from 'path'
import { homedir } from 'os'
import { parse } from 'smol-toml'
import apps from './apps'

type TomlValue = string | number | bigint | boolean | TomlValue[] | TomlTable
interface TomlTable { [key: string]: TomlValue }

const settingsPath = path.resolve(homedir(), '.config/omniwm/settings.toml')

// Workspace keys in bar order. OmniWM only accepts positive integers as workspace
// names, so key i becomes workspace `i + 1` and shows the key as its display name.
export const workspaceKeys = [...'abcdefghijklmnopqrstuvwxyzäöü0123456789']

// Home monitor of a newly generated workspace. A workspace that already exists keeps
// whatever home was set for it in OmniWM's settings.
const defaultHomes: { [key: string]: string } = {
  '4': 'secondary', '5': 'secondary', '6': 'secondary',
  '7': 'tertiary', '8': 'tertiary', '9': 'tertiary',
}

export function workspaceName(key: string): string {
  return String(workspaceKeys.indexOf(key) + 1)
}

// Deterministic UUIDs keep generated entries stable across builds, and let the build
// recognise the app rules it generated earlier (their id is derived from the bundle id).
function stableUUID(seed: string): string {
  const hash = createHash('sha1').update(`dots/omniwm/${seed}`).digest()
  hash[6] = (hash[6] & 0x0f) | 0x50
  hash[8] = (hash[8] & 0x3f) | 0x80
  const hex = hash.subarray(0, 16).toString('hex').toUpperCase()
  return `${hex.slice(0, 8)}-${hex.slice(8, 12)}-${hex.slice(12, 16)}-${hex.slice(16, 20)}-${hex.slice(20)}`
}

const appRuleId = (bundleId: string) => stableUUID(`app-rule/${bundleId}`)

function isTable(value: TomlValue | undefined): value is TomlTable {
  return typeof value === 'object' && value !== null && !Array.isArray(value)
}

function isTableArray(value: TomlValue): value is TomlTable[] {
  return Array.isArray(value) && value.length > 0 && value.every(isTable)
}

function formatKey(key: string): string {
  return /^[A-Za-z0-9_-]+$/.test(key) ? key : JSON.stringify(key)
}

// Integers are parsed as bigint, so every JS number is a TOML float. OmniWM rejects
// the whole file when a float key holds an integer.
function formatScalar(value: TomlValue): string {
  if (typeof value === 'string') return JSON.stringify(value)
  if (typeof value === 'bigint' || typeof value === 'boolean') return String(value)
  if (typeof value === 'number') {
    if (Number.isNaN(value)) return 'nan'
    if (!Number.isFinite(value)) return value > 0 ? 'inf' : '-inf'
    return Number.isInteger(value) ? value.toFixed(1) : String(value)
  }
  if (Array.isArray(value)) return `[${value.map(formatScalar).join(', ')}]`
  throw new Error(`cannot write an inline table to ${settingsPath}`)
}

// Mirrors OmniWM's canonical layout: sorted keys, plain values before sub-tables,
// a blank line between tables. Matching it keeps diffs small when OmniWM rewrites the file.
function formatTable(header: string, table: TomlTable, isArrayItem: boolean): string {
  const keys = Object.keys(table).sort()
  const lines = [isArrayItem ? `[[${header}]]` : `[${header}]`]
  for (const key of keys) {
    const value = table[key]
    if (!isTable(value) && !isTableArray(value)) lines.push(`${formatKey(key)} = ${formatScalar(value)}`)
  }
  const blocks = [lines.join('\n')]
  for (const key of keys) {
    const value = table[key]
    if (isTable(value)) blocks.push(formatTable(`${header}.${formatKey(key)}`, value, false))
  }
  for (const key of keys) {
    const value = table[key]
    if (isTableArray(value)) blocks.push(...value.map((item) => formatTable(`${header}.${formatKey(key)}`, item, true)))
  }
  return blocks.join('\n\n')
}

function generateWorkspaces(existing: TomlTable[]): TomlTable[] {
  return workspaceKeys.map((key) => {
    const label = key.toUpperCase()
    const previous = existing.find((workspace) => workspace.displayName === label)
    return {
      ...previous,
      id: previous?.id ?? stableUUID(`workspace/${key}`),
      name: workspaceName(key),
      displayName: label,
      layoutType: previous?.layoutType ?? 'default',
      monitorAssignment: previous?.monitorAssignment ?? { type: defaultHomes[key] ?? 'main' },
    }
  })
}

function generateAppRules(existing: TomlTable[]): TomlTable[] {
  const unknownKeys = Object.keys(apps).filter((key) => !workspaceKeys.includes(key))
  if (unknownKeys.length > 0) throw new Error(`apps.json uses unknown workspace keys: ${unknownKeys.join(', ')}`)

  const ownRules = existing.filter((rule) => rule.id !== appRuleId(String(rule.bundleId)))
  const generated = Object.entries(apps).map(([key, bundleId]) => ({
    assignToWorkspace: workspaceName(key),
    bundleId,
    id: appRuleId(bundleId),
  }))
  return [...ownRules, ...generated]
}

// Replaces every [[name]] block (with its sub-tables) by `replacement`, at the position
// of the first block, or at the end of the file when there is none.
function replaceTableArray(text: string, name: string, replacement: string): string {
  const header = /^\s*\[\[?\s*("[^"]*"|[^.\]\s]+)/
  const kept: string[] = []
  let insertAt = -1
  let inBlock = false

  for (const line of text.split('\n')) {
    const match = header.exec(line)
    if (match) inBlock = match[1] === name
    if (inBlock) {
      if (insertAt < 0) insertAt = kept.length
      continue
    }
    kept.push(line)
  }

  if (insertAt < 0) insertAt = kept.length
  const before = kept.slice(0, insertAt).join('\n').trimEnd()
  const after = kept.slice(insertAt).join('\n').trim()
  return [before, replacement, after].filter((part) => part !== '').join('\n\n') + '\n'
}

function updateOmniWMSettings() {
  if (!fs.existsSync(settingsPath)) {
    console.warn(`${settingsPath} not found, skipping OmniWM workspaces and app rules`)
    return
  }

  const text = fs.readFileSync(settingsPath, 'utf-8')
  const settings = parse(text, { integersAsBigInt: true }) as TomlTable
  const workspaces = generateWorkspaces((settings.workspaces ?? []) as TomlTable[])
  const appRules = generateAppRules((settings.appRules ?? []) as TomlTable[])

  let updated = replaceTableArray(text, 'appRules', appRules.map((rule) => formatTable('appRules', rule, true)).join('\n\n'))
  updated = replaceTableArray(updated, 'workspaces', workspaces.map((workspace) => formatTable('workspaces', workspace, true)).join('\n\n'))

  // OmniWM reloads on every write, which also drops runtime workspace-to-monitor moves.
  if (updated !== text) fs.writeFileSync(settingsPath, updated, 'utf-8')
}

export default updateOmniWMSettings
