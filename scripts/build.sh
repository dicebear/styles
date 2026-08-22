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

The avatar styles and the code that ships them are under different licenses.

## Avatar styles

Each style has its own license, listed below and repeated in the `meta` block of
the definition itself. The build derives a copy of every definition for the
individual package ecosystems, and each copy keeps the license of the file it
came from.
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
  rows+=("File|[src/${name}.json](https://github.com/dicebear/styles/blob/main/src/${name}.json)")

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
    echo "### $title"
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

cat >> "$LICENSE_FILE" << 'EOF'

## Everything else

The language shims, the build and release scripts, the tooling and the package
manifests contain no avatar artwork. They refer to the style files by name. That
part is under the MIT license:

MIT License

Copyright (c) 2026 Florian Körner

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
EOF

# pub.dev rejects packages without a file named exactly LICENSE, while the
# other registries and GitHub all point at LICENSE.md. Ship the same content
# under both names: the copy is git-ignored like lib/, and only the pub
# publish includes it (see .pubignore).
cp "$LICENSE_FILE" "$BASE_DIR/../LICENSE"

echo "Generate Rust crate (styles.rs + Cargo.toml features)."

RUST_LIB="$BASE_DIR/../styles.rs"
CARGO_FILE="$BASE_DIR/../Cargo.toml"

# Collect style names, skipping any *.min.json. Sort under LC_ALL=C so the
# generated order is byte-stable across machines/locales (the glob's order is
# locale-dependent), keeping the committed styles.rs/Cargo.toml reproducible.
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

# --- styles.rs ---------------------------------------------------------------
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
//! This is a pure-data crate: the same source styles under `src/` that the
//! packages for the other languages ship, with no logic. The core parses and
//! renders these definitions. This crate only ships the bytes.
//!
//! Each style is gated behind a feature of the same name, so a binary only embeds
//! the styles it opts into:
//!
//! ```toml
//! dicebear-styles = { version = "10", features = ["shapes", "bottts"] }
//! ```
//!
//! Use `all` to pull in every style. The crate embeds the unminified `src/`
//! files and parses them at runtime. The minified `dist/` copy exists for the
//! browser and ships only on npm.
//!
//! The MIT license in this file's header covers this file only. The embedded
//! style definitions carry their own licenses, listed in LICENSE.md and in each
//! definition's `meta` block.

EOF

for name in "${names[@]}"; do
  const="$(const_name "$name")"
  printf '#[cfg(feature = "%s")]\npub const %s: &str = include_str!("src/%s.json");\n\n' \
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

/// Names of every style available in this build (those whose feature is enabled).
///
/// Companion to `get`: `all()` lists the names, `get(name)` fetches one.
pub fn all() -> Vec<&'static str> {
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

echo "Generate Go module (styles.go)."

GO_FILE="$BASE_DIR/../styles.go"

# kebab-case style name -> exported Go identifier (PascalCase). Style names are
# lowercase ASCII words joined by `-`, so a per-segment capitalize is enough:
# big-ears-neutral -> BigEarsNeutral.
pascal_name() {
  printf '%s' "$1" | LC_ALL=C awk -F'-' '{s="";for(i=1;i<=NF;i++)s=s toupper(substr($i,1,1)) substr($i,2);print s}'
}

# Reuse the same LC_ALL=C-sorted `names` list built for the Rust crate so the
# generated shims stay in lockstep. The output is hand-formatted to be gofmt-clean
# (tabs, single blank lines) — build.sh must not shell out to `gofmt`, since the
# rust-codegen CI job runs this script without a Go toolchain installed.

# License header, generated-marker (must match `^// Code generated .* DO NOT
# EDIT\.$` so `go` tooling treats the file as generated) and package docs. A
# quoted heredoc writes Go's backticks/`*` verbatim.
cat > "$GO_FILE" <<'EOF'
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

// Code generated by scripts/build.sh from src/*.json; DO NOT EDIT.

// Package styles embeds the DiceBear avatar style definitions.
//
// It is a pure-data package: the same source styles under src/ that the
// packages for the other languages ship, with no logic. The core parses and
// renders these definitions. This package only ships the bytes.
//
// Every style is embedded and exposed both as an exported variable (e.g.
// Adventurer) and by name via Get. Go embeds the whole set into the consuming
// binary, so there is no per-style opt-in like the Rust crate's features. The
// embedded copy is the unminified src/ JSON. The minified dist/ copy exists
// for the browser and ships only on npm.
//
// The MIT license in this file's header covers this file only. The embedded
// style definitions carry their own licenses, listed in LICENSE.md and in each
// definition's meta block.
package styles

import _ "embed"

EOF

for name in "${names[@]}"; do
  var="$(pascal_name "$name")"
  printf '//go:embed src/%s.json\nvar %s string\n\n' "$name" "$var" >> "$GO_FILE"
done

cat >> "$GO_FILE" <<'EOF'
// Get returns the raw JSON definition for the named style, or ("", false) if the
// style name is unknown.
func Get(name string) (string, bool) {
	switch name {
EOF
for name in "${names[@]}"; do
  var="$(pascal_name "$name")"
  printf '\tcase "%s":\n\t\treturn %s, true\n' "$name" "$var" >> "$GO_FILE"
done
cat >> "$GO_FILE" <<'EOF'
	}
	return "", false
}

// All returns the names of every embedded style, sorted.
//
// Companion to Get: All lists the names, Get fetches one.
func All() []string {
	return []string{
EOF
for name in "${names[@]}"; do
  printf '\t\t"%s",\n' "$name" >> "$GO_FILE"
done
cat >> "$GO_FILE" <<'EOF'
	}
}
EOF

echo "Generate Dart package (lib/*.dart)."

DART_DIR="$BASE_DIR/../lib"

# kebab-case style name -> Dart identifier (lowerCamelCase). Style names are
# lowercase ASCII words joined by `-`, so a per-segment capitalize is enough:
# big-ears-neutral -> bigEarsNeutral.
camel_name() {
  printf '%s' "$1" | LC_ALL=C awk -F'-' '{s=$1;for(i=2;i<=NF;i++)s=s toupper(substr($i,1,1)) substr($i,2);print s}'
}

# kebab-case style name -> Dart library file name: big-ears-neutral -> big_ears_neutral.
snake_name() { printf '%s' "$1" | LC_ALL=C tr '-' '_'; }

# Dart has no include_str!/go:embed, so the JSON is embedded as string literals.
# Escape for a non-raw triple-quoted Dart string ('''…'''): backslash first,
# then the quote and `$` (string interpolation). The escaped literal restores
# the exact source bytes, so the constants stay byte-identical to src/*.json
# and to what include_str!/go:embed ship (tool/check_parity.dart proves this in
# CI). The JSON files start with `{`, which matters: Dart strips a newline that
# directly follows the opening ''' delimiter. LC_ALL=C processes the UTF-8
# bytes as-is (the patterns are pure ASCII); without it, BSD sed errors out on
# byte sequences that are invalid in the active locale.
dart_escape() { LC_ALL=C sed -e 's/\\/\\\\/g' -e "s/'/\\\\'/g" -e 's/\$/\\$/g'; }

# Per-style file header. Unlike the other language shims, which are MIT-licensed
# and only *reference* the JSON, these files *contain* the style data, so
# they must not carry the repository's MIT tooling header. Each file credits its
# own artist and license instead, from the same `meta` that LICENSE.md is built
# from (every style carries `meta.license`).
dart_style_header() {
  local name="$1" f="$TARGET_DIR/$1.json"
  local license_name license_url license_text creator_name creator_url source_name source_url
  license_name=$(jq -r ".meta.license.name // empty" "$f")
  license_url=$(jq -r ".meta.license.url // empty" "$f")
  license_text=$(jq -r ".meta.license.text // empty" "$f")
  creator_name=$(jq -r ".meta.creator.name // empty" "$f")
  creator_url=$(jq -r ".meta.creator.url // empty" "$f")
  source_name=$(jq -r ".meta.source.name // empty" "$f")
  source_url=$(jq -r ".meta.source.url // empty" "$f")

  echo "// -----------------------------------------------------------------------------"
  printf '// DiceBear avatar style: %s\n' "$name"
  echo "//"
  if [ -n "$creator_name" ]; then
    if [ -n "$creator_url" ]; then
      printf '// Artist: %s (%s)\n' "$creator_name" "$creator_url"
    else
      printf '// Artist: %s\n' "$creator_name"
    fi
  fi
  if [ -n "$license_url" ]; then
    printf '// License: %s (%s)\n' "$license_name" "$license_url"
  else
    printf '// License: %s\n' "$license_name"
  fi
  if [ -n "$source_name" ]; then
    if [ -n "$source_url" ]; then
      printf '// Source: %s (%s)\n' "$source_name" "$source_url"
    else
      printf '// Source: %s\n' "$source_name"
    fi
  fi
  # The style's attribution statement (meta.license.text), wrapped to comment
  # width. LC_ALL=C makes fold count bytes on BSD and GNU alike, so the
  # generated wrapping is identical across machines; `fold -s` only breaks at
  # blanks, so multibyte characters (e.g. the „…” quotes) are never split, and
  # only all-ASCII words like URLs can exceed the width. The text may span
  # multiple lines (some styles carry a full license text). The second trim
  # turns the `// `-prefixed blank lines back into a bare `//`, so the output
  # stays free of trailing whitespace for dart format.
  if [ -n "$license_text" ]; then
    echo "//"
    printf '%s\n' "$license_text" | LC_ALL=C fold -s -w 77 \
      | LC_ALL=C sed -e 's|^|// |' -e 's/[[:space:]]*$//'
  fi
  echo "//"
  echo '// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR'
  echo "// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,"
  echo "// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE"
  echo "// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER"
  echo "// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,"
  echo "// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE"
  echo "// SOFTWARE."
  echo "// -----------------------------------------------------------------------------"
  echo ""
  printf '// @generated by scripts/build.sh from src/%s.json — do not edit by hand.\n' "$name"
  echo ""
}

# MIT license header for the generated umbrella library, which, like
# styles.rs/styles.go, contains only tooling code and no style data. A quoted
# heredoc writes `$` and backticks verbatim.
dart_header() {
  cat <<'EOF'
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

EOF
}

# Regenerate lib/ from scratch so styles removed from src/ don't linger (unlike
# styles.rs/styles.go, the Dart package is one file per style).
rm -rf "$DART_DIR"
mkdir -p "$DART_DIR"

# One library per style, so a compiled Dart/Flutter app only embeds the styles
# it imports: the Dart counterpart of the Rust crate's feature-per-style.
for name in "${names[@]}"; do
  {
    dart_style_header "$name"
    printf '/// Raw JSON definition of the DiceBear `%s` avatar style.\n' "$name"
    printf "const String %s = '''" "$(camel_name "$name")"
    dart_escape < "$TARGET_DIR/$name.json"
    printf "''';\n"
  } > "$DART_DIR/$(snake_name "$name").dart"
done

# Umbrella library: re-exports every style and adds runtime lookup by name.
{
  dart_header
  cat <<'EOF'
/// DiceBear avatar style definitions, embedded as Dart string constants.
///
/// This is a pure-data package: the same source styles that the packages for
/// the other languages ship, with no logic. The core parses and renders these
/// definitions. This package only ships the bytes.
///
/// Each style lives in its own library (e.g.
/// `package:dicebear_styles/adventurer.dart`), so a compiled app only embeds
/// the styles it imports. This umbrella library re-exports every style and
/// adds a runtime lookup by name, so importing it pulls in every style.
///
/// The MIT license in this file's header covers this file only. The style
/// definitions it re-exports carry their own licenses, listed in LICENSE and in
/// each definition's `meta` block.
library;

EOF
  for name in "${names[@]}"; do
    printf "import '%s.dart';\n" "$(snake_name "$name")"
  done
  echo ""
  for name in "${names[@]}"; do
    printf "export '%s.dart';\n" "$(snake_name "$name")"
  done
  cat <<'EOF'

/// Returns the raw JSON definition for the named style, or `null` if the style
/// is unknown.
String? get(String name) {
  switch (name) {
EOF
  for name in "${names[@]}"; do
    printf "    case '%s':\n      return %s;\n" "$name" "$(camel_name "$name")"
  done
  cat <<'EOF'
  }
  return null;
}

/// Names of every embedded style, sorted.
///
/// Companion to `get`: `all` lists the names, `get(name)` fetches one.
const List<String> all = [
EOF
  for name in "${names[@]}"; do
    printf "  '%s',\n" "$name"
  done
  echo "];"
} > "$DART_DIR/dicebear_styles.dart"

echo "Generate C# package (styles.cs)."

CS_FILE="$BASE_DIR/../styles.cs"

# kebab-case style name -> C# property name (PascalCase). Same shape as the Go
# identifiers, so `pascal_name` is reused.

# License header, generated-marker and type docs (static). A quoted heredoc
# writes the XML doc comments verbatim.
cat > "$CS_FILE" <<'EOF'
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

using System;
using System.Collections.Generic;
using System.IO;
using System.Reflection;
using System.Text;

namespace DiceBear
{
    /// <summary>
    /// The DiceBear avatar style definitions, embedded in the assembly.
    /// </summary>
    /// <remarks>
    /// <para>
    /// A pure-data package: the same source styles under <c>src/</c> that the
    /// packages for the other languages ship, with no logic. The core parses
    /// and renders these definitions. This package only ships the bytes.
    /// </para>
    /// <para>
    /// The assembly embeds the unminified <c>src/</c> JSON. The minified
    /// <c>dist/</c> copy exists for the browser and ships only on npm. Every
    /// style is embedded, so the assembly carries the whole set: there is no
    /// per-style opt-in like the Rust crate's features, and the trimmer leaves
    /// embedded resources alone.
    /// </para>
    /// <para>
    /// Every member reads its resource on each call and does not cache it. A
    /// definition is a few hundred kilobytes, and the usual path hands it to
    /// <c>Style.Parse</c> once and keeps the parsed style instead, so caching
    /// the raw text here would hold megabytes nobody reads again.
    /// </para>
    /// <para>
    /// The MIT license in this file's header covers this file only. The
    /// embedded style definitions carry their own licenses, listed in
    /// LICENSE.md and in each definition's <c>meta</c> block.
    /// </para>
    /// </remarks>
    public static class Styles
    {
        private const string ResourcePrefix = "DiceBear.Styles.";

EOF

for name in "${names[@]}"; do
  pascal="$(pascal_name "$name")"
  printf '        /// <summary>Raw JSON definition of the DiceBear <c>%s</c> avatar style.</summary>\n' "$name" >> "$CS_FILE"
  printf '        public static string %s => Read("%s");\n\n' "$pascal" "$name" >> "$CS_FILE"
done

cat >> "$CS_FILE" <<'EOF'
        /// <summary>
        /// Returns the raw JSON definition for the named style, or
        /// <see langword="null"/> if the style name is unknown.
        /// </summary>
        /// <param name="name">Style name, e.g. <c>"adventurer"</c>.</param>
        /// <remarks>
        /// Companion to <see cref="All"/>: <c>All()</c> lists the names,
        /// <c>Get(name)</c> fetches one.
        /// </remarks>
        public static string? Get(string name)
        {
            switch (name)
            {
EOF

for name in "${names[@]}"; do
  pascal="$(pascal_name "$name")"
  printf '                case "%s":\n                    return %s;\n' "$name" "$pascal" >> "$CS_FILE"
done

cat >> "$CS_FILE" <<'EOF'
                default:
                    return null;
            }
        }

        /// <summary>
        /// Names of every embedded style, sorted.
        /// </summary>
        /// <remarks>
        /// Companion to <see cref="Get"/>: <c>All()</c> lists the names,
        /// <c>Get(name)</c> fetches one.
        /// </remarks>
        public static IReadOnlyList<string> All()
        {
            return new[]
            {
EOF

for name in "${names[@]}"; do
  printf '                "%s",\n' "$name" >> "$CS_FILE"
done

cat >> "$CS_FILE" <<'EOF'
            };
        }

        /// <summary>
        /// Reads one embedded definition as UTF-8 text.
        /// </summary>
        private static string Read(string name)
        {
            var assembly = typeof(Styles).GetTypeInfo().Assembly;
            var resource = ResourcePrefix + name + ".json";

            using (var stream = assembly.GetManifestResourceStream(resource))
            {
                if (stream == null)
                {
                    throw new InvalidOperationException(
                        "Embedded style resource is missing: " + resource);
                }

                // The JSON files are committed without a byte order mark, and
                // BOM detection is switched off so that one appearing in src/
                // would survive into the string instead of being stripped. That
                // keeps the bytes identical to src/*.json on every platform, and
                // it lets tool/CheckParity see the difference: File.ReadAllText
                // does strip a BOM, so the comparison would fail and report it.
                using (var reader = new StreamReader(
                    stream, new UTF8Encoding(false), detectEncodingFromByteOrderMarks: false))
                {
                    return reader.ReadToEnd();
                }
            }
        }
    }
}
EOF

echo "Done!"
