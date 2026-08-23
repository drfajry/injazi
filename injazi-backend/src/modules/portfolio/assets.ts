import { readFileSync } from 'node:fs';
import { join } from 'node:path';

// Loaded once at module import time and cached — reading a 38KB file off
// disk is cheap, but there's no reason to repeat it on every request.
// Kept as a real binary .png file in /assets rather than a base64 string
// baked into source code: readable diffs, normal image tooling works on
// it, and it doesn't bloat the TypeScript file it's used from.
//
// Uses process.cwd() rather than a relative __dirname path: Render (and
// `npm start`) always runs the compiled server from the project root
// (injazi-backend/), so this stays correct regardless of how deep this
// module ends up inside dist/ after compilation.
let ministryLogoBase64Cache: string | null = null;
let ministryLogoLoadFailed = false;

export function getMinistryLogoBase64(): string | null {
  if (ministryLogoLoadFailed) return null;

  if (ministryLogoBase64Cache === null) {
    try {
      const path = join(process.cwd(), 'assets', 'ministry-logo.png');
      ministryLogoBase64Cache = readFileSync(path).toString('base64');
    } catch (error) {
      // Missing/unreadable logo file should never break the export — fall
      // back to no logo rather than crashing the whole request.
      console.error('Failed to load ministry logo asset:', error);
      ministryLogoLoadFailed = true;
      return null;
    }
  }

  return ministryLogoBase64Cache;
}
