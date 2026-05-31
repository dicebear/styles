import { readFileSync, writeFileSync } from "node:fs";
import { join, resolve } from "node:path";
import { execSync } from "node:child_process";

// Bumps the release version across every manifest in this repo, syncs the
// lockfile, then commits and tags — mirroring scripts/version.mjs in the
// dicebear monorepo. The version lives in the manifests (package.json and
// pyproject.toml) and is the single source of truth for both the npm and the
// PyPI publish; this script keeps them in lockstep.
//
//   node scripts/version.mjs 10.1.0

const ROOT = resolve(import.meta.dirname, "..");

const version = process.argv[2];
if (!version) {
  console.error("Usage: node scripts/version.mjs <version>");
  process.exit(1);
}

// Sanity-check the shape (X.Y.Z with an optional -prerelease). npm and hatchling
// do the authoritative semver / PEP 440 validation at publish time.
if (!/^\d+\.\d+\.\d+(-[\w.]+)?$/.test(version)) {
  console.error(`Invalid version: ${version}`);
  process.exit(1);
}

// Replace only the version string so generated blocks (e.g. the package.json
// `exports` map) stay byte-for-byte untouched.
function bump(file, pattern, replacement) {
  const path = join(ROOT, file);
  const raw = readFileSync(path, "utf-8");
  const next = raw.replace(pattern, replacement);

  if (next === raw) {
    console.error(`${file}: version field not found`);
    process.exit(1);
  }

  writeFileSync(path, next);
  console.log(`  ${file} → ${version}`);
}

bump("package.json", /"version": "[^"]*"/, `"version": "${version}"`);
bump("pyproject.toml", /^version = "[^"]*"$/m, `version = "${version}"`);

console.log("\nSyncing package-lock.json...");
execSync("npm install --package-lock-only", { cwd: ROOT, stdio: "inherit" });

const tag = `v${version}`;
console.log(`\nCreating commit and tag ${tag}...`);
execSync("git add -A", { cwd: ROOT, stdio: "inherit" });
execSync(`git commit -m "${tag}"`, { cwd: ROOT, stdio: "inherit" });
execSync(`git tag "${tag}"`, { cwd: ROOT, stdio: "inherit" });

console.log(`\nDone! Push with: git push && git push --tags`);
