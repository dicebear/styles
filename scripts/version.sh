#!/usr/bin/env bash

# -----------------------------------------------------------------------------
# MIT License
#
# Copyright (c) 2026 Florian Körner
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
# -----------------------------------------------------------------------------

set -euo pipefail

# Bumps the release version across every manifest in this repo, syncs the
# lockfile, then commits and tags — mirroring scripts/version.mjs in the
# dicebear monorepo. The version lives in the manifests (package.json,
# pyproject.toml, Cargo.toml and pubspec.yaml) and is the single source of
# truth for the npm, PyPI, crates.io and pub.dev publishes; this script keeps
# them in lockstep.
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
# crates.io: the `[package]` version. `^version = ` (column 0) matches only this
# line, not the indented dependency versions further down.
bump "Cargo.toml" '^version = "[^"]*"$' "version = \"$version\""
# pub.dev: pubspec's top-level `version:` is the only line matching at column 0.
bump "pubspec.yaml" '^version: .*$' "version: $version"

# Repository the changelog's compare links point at.
CHANGELOG_REPO_URL="https://github.com/dicebear/styles"

# Promote the changelog's `## [Unreleased]` section to a released version:
# move its entries under a dated `## [<version>]` heading, keep a fresh empty
# Unreleased section on top, and update the bottom compare links. Mirrors
# updateChangelog() in scripts/lib/version.mjs of the dicebear monorepo.
promote_changelog() {
  local file="$ROOT/CHANGELOG.md"
  [ -f "$file" ] || return 0

  if ! grep -Eq '^## \[Unreleased\]' "$file"; then
    echo "CHANGELOG.md: no [Unreleased] section (skipped)"
    return 0
  fi

  # Idempotent: if a previous run already promoted this version (e.g. it failed
  # after writing the changelog), don't promote the now-empty Unreleased again.
  if grep -Fq "## [$version]" "$file"; then
    echo "CHANGELOG.md: $version already present (skipped)"
    return 0
  fi

  local date tmp
  date="$(date +%F)"
  tmp="$(mktemp)"

  # POSIX awk only (no gawk-specific 3-arg match), to match this script's
  # BSD/GNU portability. The Unreleased compare link is only rewritten when it
  # follows the conventional `/compare/v<prev>...HEAD` shape; otherwise it (and
  # the rest of the file) is passed through untouched.
  awk -v version="$version" -v date="$date" -v repo="$CHANGELOG_REPO_URL" '
    /^## \[Unreleased\]/ {
      print
      print ""
      print "## [" version "] - " date
      next
    }
    /^\[Unreleased\]:.*\/compare\/v.*\.\.\.HEAD/ {
      prev = $0
      sub(/^.*\/compare\/v/, "", prev)
      sub(/\.\.\.HEAD.*$/, "", prev)
      print "[Unreleased]: " repo "/compare/v" version "...HEAD"
      print "[" version "]: " repo "/compare/v" prev "...v" version
      next
    }
    { print }
  ' "$file" > "$tmp"

  cat "$tmp" > "$file"
  rm -f "$tmp"
  echo
  echo "CHANGELOG.md: Unreleased → $version ($date)"
}

promote_changelog

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
