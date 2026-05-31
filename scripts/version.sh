#!/usr/bin/env bash
set -euo pipefail

# Bumps the release version across every manifest in this repo, syncs the
# lockfile, then commits and tags — mirroring scripts/version.mjs in the
# dicebear monorepo. The version lives in the manifests (package.json and
# pyproject.toml) and is the single source of truth for both the npm and the
# PyPI publish; this script keeps them in lockstep.
#
#   scripts/version.sh 10.1.0

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

version="${1:-}"
if [ -z "$version" ]; then
  echo "Usage: scripts/version.sh <version>" >&2
  exit 1
fi

# Sanity-check the shape (X.Y.Z with an optional -prerelease). npm and hatchling
# do the authoritative semver / PEP 440 validation at publish time.
if ! [[ "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+(-[A-Za-z0-9.]+)?$ ]]; then
  echo "Invalid version: $version" >&2
  exit 1
fi

# Replace only the version string so generated blocks (e.g. the package.json
# `exports` map) stay byte-for-byte untouched.
bump() {
  local file="$1" pattern="$2"
  local path="$ROOT/$file"

  if ! grep -Eq "$pattern" "$path"; then
    echo "$file: version field not found" >&2
    exit 1
  fi

  # Edit via a temp file (portable across BSD/GNU sed, which differ on `-i`),
  # then copy back in place so the manifest keeps its original permissions —
  # a bare `mv` would leave it with mktemp's 0600.
  local tmp
  tmp="$(mktemp)"
  sed -E "s/$pattern/$3/" "$path" > "$tmp"
  cat "$tmp" > "$path"
  rm -f "$tmp"
  echo "  $file → $version"
}

bump "package.json" '"version": "[^"]*"' "\"version\": \"$version\""
bump "pyproject.toml" '^version = "[^"]*"$' "version = \"$version\""

echo
echo "Syncing package-lock.json..."
( cd "$ROOT" && npm install --package-lock-only )

tag="v$version"
echo
echo "Creating commit and tag $tag..."
cd "$ROOT"
git add -A
git commit -m "$tag"
git tag "$tag"

echo
echo "Done! Push with: git push && git push --tags"
