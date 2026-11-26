import { readFileSync } from 'node:fs'
import type { ComplexModifications } from 'karabiner.ts'
import type { Output } from './output.ts'

// The ES module build of karabiner.ts calls require() inside writeToProfile(), which
// fails when Node runs the TypeScript natively. The build therefore only uses karabiner.ts
// to build the rules and writes karabiner.json itself, in the same format.

type KarabinerJson = {
  profiles?: Array<{ name: string; complex_modifications?: ComplexModifications }>
}

/** karabiner.json with the rules and parameters of a profile replaced. */
export function karabinerJsonOutput(path: string, profileName: string, complexModifications: ComplexModifications): Output {
  const text = readFileSync(path, 'utf-8')
  const karabinerJson = JSON.parse(text) as KarabinerJson
  const profile = karabinerJson.profiles?.find((candidate) => candidate.name === profileName)
  if (profile === undefined) {
    throw new Error(`${path}: profile "${profileName}" not found, create it in Karabiner-Elements or set KARABINER_PROFILE`)
  }
  profile.complex_modifications = complexModifications

  const updated = JSON.stringify(karabinerJson, null, 2)
  return { label: `Karabiner profile "${profileName}"`, path, text, updated }
}
