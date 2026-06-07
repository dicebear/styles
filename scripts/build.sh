#!/bin/bash

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

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET_DIR="$BASE_DIR/../src"
DIST_DIR="$BASE_DIR/../dist"
LICENSE_FILE="$BASE_DIR/../LICENSE.md"

echo "Minify definition files."

mkdir -p "$DIST_DIR"

PACKAGE_FILE="$BASE_DIR/../package.json"
version=$(jq -r '.version' "$PACKAGE_FILE")
exports="{}"

for f in "$TARGET_DIR"/*.json; do

  [ -f "$f" ] || continue

  name=$(basename "$f" .json)
  echo "  Minify ${name}.json"

  id="https://cdn.hopjs.net/npm/@dicebear/styles@${version}/dist/${name}.min.json"
  jq -c --arg id "$id" '{"$id": $id} + .' "$f" > "$DIST_DIR/${name}.min.json"

  exports=$(echo "$exports" | jq --arg key "./${name}.json" --arg val "./dist/${name}.min.json" '. + {($key): {types: $val, default: $val}}')

done

echo "Update exports in package.json."

jq --argjson exports "$exports" '. + {exports: $exports}' "$PACKAGE_FILE" > "$PACKAGE_FILE.tmp"
mv "$PACKAGE_FILE.tmp" "$PACKAGE_FILE"

echo "Generate LICENSE.md"

cat > "$LICENSE_FILE" << 'EOF'
# License

The avatar styles are subject to different licences. You can find the licence in
the following list or in the individual files.
EOF

for f in "$TARGET_DIR"/*.json; do

  [ -f "$f" ] || continue
  [[ "$f" == *.min.json ]] && continue

  name=$(basename "$f" .json)

  # Convert filename to title: split by -, capitalize each word
  title=$(echo "$name" | sed 's/-/ /g' | awk '{for(i=1;i<=NF;i++) $i=toupper(substr($i,1,1))substr($i,2)}1')

  license_name=$(jq -r ".meta.license.name // empty" "$f")
  license_url=$(jq -r ".meta.license.url // empty" "$f")
  creator_name=$(jq -r ".meta.creator.name // empty" "$f")
  creator_url=$(jq -r ".meta.creator.url // empty" "$f")
  source_name=$(jq -r ".meta.source.name // empty" "$f")
  source_url=$(jq -r ".meta.source.url // empty" "$f")

  # Collect rows as "label|value" pairs
  rows=()
  rows+=("File|[src/${name}.json](./src/${name}.json)")

  if [ -n "$creator_name" ]; then
    if [ -n "$creator_url" ]; then
      rows+=("Artist|[$creator_name]($creator_url)")
    else
      rows+=("Artist|$creator_name")
    fi
  fi

  if [ -n "$license_name" ] && [ -n "$license_url" ]; then
    rows+=("License|[$license_name]($license_url)")
  fi

  if [ -n "$source_name" ]; then
    if [ -n "$source_url" ]; then
      rows+=("Source|[$source_name]($source_url)")
    else
      rows+=("Source|$source_name")
    fi
  fi

  # Find max value length for column alignment
  max_len=0
  for row in "${rows[@]}"; do
    value="${row#*|}"
    len=${#value}
    [ "$len" -gt "$max_len" ] && max_len=$len
  done

  # Generate separator dashes
  separator=":$(printf '%*s' "$((max_len - 1))" '' | tr ' ' '-')"

  {
    echo ""
    echo "## $title"
    echo ""

    for i in "${!rows[@]}"; do
      label="${rows[$i]%%|*}"
      value="${rows[$i]#*|}"

      # Compensate for multibyte characters (e.g. ö = 2 bytes, 1 char)
      byte_len=$(printf '%s' "$value" | wc -c)
      char_len=${#value}
      pad_len=$((max_len + byte_len - char_len))

      printf '| %7s | %-*s |\n' "$label" "$pad_len" "$value"

      if [ "$i" -eq 0 ]; then
        printf '| %7s | %-*s |\n' "------:" "$max_len" "$separator"
      fi
    done
  } >> "$LICENSE_FILE"

done

echo "Generate Rust crate (rust/lib.rs + Cargo.toml features)."

RUST_LIB="$BASE_DIR/../rust/lib.rs"
CARGO_FILE="$BASE_DIR/../Cargo.toml"

# Collect style names, skipping any *.min.json. Sort under LC_ALL=C so the
# generated order is byte-stable across machines/locales (the glob's order is
# locale-dependent), keeping the committed lib.rs/Cargo.toml reproducible.
names=()
while IFS= read -r name; do
  names+=("$name")
done < <(
  for f in "$TARGET_DIR"/*.json; do
    [ -f "$f" ] || continue
    [[ "$f" == *.min.json ]] && continue
    basename "$f" .json
  done | LC_ALL=C sort
)

const_name() { printf '%s' "$1" | LC_ALL=C tr '[:lower:]' '[:upper:]' | LC_ALL=C tr '-' '_'; }

# --- rust/lib.rs -------------------------------------------------------------
# License header, generated-marker and module docs (static). A quoted heredoc
# writes Rust's backticks, `!` and `&` verbatim.
cat > "$RUST_LIB" <<'EOF'
// -----------------------------------------------------------------------------
// MIT License
//
// Copyright (c) 2026 Florian Körner
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.
// -----------------------------------------------------------------------------

// @generated by scripts/build.sh from src/*.json — do not edit by hand.

//! DiceBear avatar style definitions, embedded at compile time.
//!
//! This is a pure-data crate. It mirrors the npm (`@dicebear/<style>`), Composer
//! and PyPI (`dicebear-styles`) packages: the same source styles under `src/`,
//! with no logic. The core parses and renders these definitions; this crate only
//! ships the bytes.
//!
//! Each style is gated behind a feature of the same name, so a binary only embeds
//! the styles it opts into:
//!
//! ```toml
//! dicebear-styles = { version = "10", features = ["shapes", "bottts"] }
//! ```
//!
//! Use `all` to pull in every style. Unlike npm — which serves the minified
//! `dist/` over the browser — Rust embeds and parses the JSON at runtime, so the
//! unminified `src/` files are used directly, matching the Python and PHP packages.

EOF

for name in "${names[@]}"; do
  const="$(const_name "$name")"
  printf '#[cfg(feature = "%s")]\npub const %s: &str = include_str!("../src/%s.json");\n\n' \
    "$name" "$const" "$name" >> "$RUST_LIB"
done

cat >> "$RUST_LIB" <<'EOF'
/// Returns the raw JSON definition for the named style, or `None` if the style is
/// unknown or its feature is not enabled in this build.
pub fn get(name: &str) -> Option<&'static str> {
    match name {
EOF
for name in "${names[@]}"; do
  const="$(const_name "$name")"
  printf '        #[cfg(feature = "%s")]\n        "%s" => Some(%s),\n' \
    "$name" "$name" "$const" >> "$RUST_LIB"
done
cat >> "$RUST_LIB" <<'EOF'
        _ => None,
    }
}

/// Names of every style compiled into this build (those whose feature is enabled).
pub fn enabled() -> Vec<&'static str> {
    #[allow(unused_mut)]
    let mut v = Vec::new();
EOF
for name in "${names[@]}"; do
  printf '    #[cfg(feature = "%s")]\n    v.push("%s");\n' "$name" "$name" >> "$RUST_LIB"
done
cat >> "$RUST_LIB" <<'EOF'
    v
}
EOF

# --- Cargo.toml [features] ---------------------------------------------------
# Regenerate the derived [features] table while preserving everything above it
# (package metadata incl. the version bumped by scripts/version.sh, and [lib]).
# [features] must stay the last section of Cargo.toml for this to be safe, so
# fail loudly if any section follows it (the truncation below would drop it).
if awk '/^\[features\]/{f=1; next} f && /^\[[^]]+\]/{bad=1} END{exit(bad?0:1)}' "$CARGO_FILE"; then
  echo "  ERROR: a section follows [features] in Cargo.toml — build.sh would drop it." >&2
  echo "         Keep [features] last, or teach this script to preserve trailing sections." >&2
  exit 1
fi

cargo_tmp="$(mktemp)"
awk '/^\[features\]/{exit} {print}' "$CARGO_FILE" > "$cargo_tmp"
{
  echo "[features]"
  echo "# No style is compiled in by default — opt in per style to keep binaries small."
  echo "default = []"
  echo "# Convenience: pull in every style."
  echo "all = ["
  for name in "${names[@]}"; do
    printf '  "%s",\n' "$name"
  done
  echo "]"
  echo ""
  echo '# One feature per style. `dicebear-styles = { features = ["shapes", "bottts"] }`'
  for name in "${names[@]}"; do
    printf '%s = []\n' "$name"
  done
} >> "$cargo_tmp"
# Copy back in place so the manifest keeps its original permissions.
cat "$cargo_tmp" > "$CARGO_FILE"
rm -f "$cargo_tmp"

echo "Done!"
