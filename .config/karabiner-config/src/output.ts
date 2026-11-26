import { writeFileSync } from 'node:fs'

/** A file the build writes: what it holds now and what the build wants it to hold. */
export type Output = {
  label: string
  path: string
  text: string
  updated: string
}

/** Writes the output only when it changed: Karabiner and OmniWM reload on every write. */
export function writeOutput({ label, path, text, updated }: Output): void {
  if (updated === text) {
    console.log(`✓ ${label} unchanged.`)
    return
  }
  writeFileSync(path, updated, 'utf-8')
  console.log(`✓ ${label} updated.`)
}
