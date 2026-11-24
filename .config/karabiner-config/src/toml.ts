import type { TomlTable, TomlValue } from 'smol-toml'

// Writes TOML in the canonical layout OmniWM uses when it saves settings.toml: sorted
// keys, plain values before sub-tables, a blank line between tables. Matching it keeps
// the diff small when OmniWM rewrites the file. smol-toml's stringify() keeps insertion
// order and writes integers and floats alike, so it can't be used.
//
// Parse with `integersAsBigInt: true`: integers then stay bigint, and every JS number is
// written as a float. OmniWM rejects the whole file when a float key holds an integer.

export type { TomlTable }

export function isTable(value: TomlValue | undefined): value is TomlTable {
  return typeof value === 'object' && value !== null && !Array.isArray(value) && !(value instanceof Date)
}

function isTableArray(value: TomlValue): value is TomlTable[] {
  return Array.isArray(value) && value.length > 0 && value.every(isTable)
}

/** Reads an array of tables (`[[key]]`), which may be missing. */
export function getTableArray(table: TomlTable, key: string): TomlTable[] {
  const value = table[key]
  if (value === undefined) return []
  if (!Array.isArray(value) || !value.every(isTable)) throw new Error(`"${key}" is not an array of tables`)
  return value
}

function formatKey(key: string): string {
  return /^[A-Za-z0-9_-]+$/.test(key) ? key : JSON.stringify(key)
}

function formatValue(value: TomlValue): string {
  if (typeof value === 'string') return JSON.stringify(value)
  if (typeof value === 'bigint' || typeof value === 'boolean') return String(value)
  if (typeof value === 'number') {
    if (Number.isNaN(value)) return 'nan'
    if (!Number.isFinite(value)) return value > 0 ? 'inf' : '-inf'
    return Number.isInteger(value) ? value.toFixed(1) : String(value)
  }
  if (value instanceof Date) return value.toISOString() // smol-toml's TomlDate keeps the original precision
  if (Array.isArray(value)) return `[${value.map(formatValue).join(', ')}]`
  throw new Error(`cannot write ${JSON.stringify(value)} as an inline TOML value`)
}

function formatTable(header: string, table: TomlTable, isArrayItem: boolean): string {
  const keys = Object.keys(table).sort()
  const valueLines = keys
    .filter((key) => !isTable(table[key]) && !isTableArray(table[key]!))
    .map((key) => `${formatKey(key)} = ${formatValue(table[key]!)}`)
  const blocks = [[isArrayItem ? `[[${header}]]` : `[${header}]`, ...valueLines].join('\n')]

  for (const key of keys) {
    const value = table[key]!
    if (isTable(value)) blocks.push(formatTable(`${header}.${formatKey(key)}`, value, false))
  }
  for (const key of keys) {
    const value = table[key]!
    if (isTableArray(value)) blocks.push(...value.map((item) => formatTable(`${header}.${formatKey(key)}`, item, true)))
  }
  return blocks.join('\n\n')
}

/** Formats `items` as the `[[name]]` blocks of an array of tables. */
export function formatTableArray(name: string, items: TomlTable[]): string {
  return items.map((item) => formatTable(formatKey(name), item, true)).join('\n\n')
}

// Matches a table header (`[name]`, `[name.sub]`, `[[name]]`) and captures its first key.
const tableHeader = /^\s*\[\[?\s*("[^"]*"|[A-Za-z0-9_-]+)\s*[.\]]/

/**
 * Replaces every block of the top-level table `name` (including its sub-tables) in the
 * TOML `text` by `replacement`. The replacement goes where the first block was, or at
 * the end when there was none. Everything else stays as it was, byte for byte.
 */
export function replaceTable(text: string, name: string, replacement: string): string {
  const kept: string[] = []
  let insertAt = -1
  let inBlock = false

  for (const line of text.split('\n')) {
    const header = tableHeader.exec(line)
    if (header) inBlock = header[1] === formatKey(name)
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
