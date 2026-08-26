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
SRC_DIR="$BASE_DIR/../src"

SCHEMA_FILE="$BASE_DIR/../node_modules/@dicebear/schema/dist/definition.min.json"

# Two entries below are not a plain implementation name. The PHP harness is
# pinned to the last image built on PHP 8.5.8, because `latest` runs a PHP 8.6
# beta where `spl_object_hash()` is deprecated. opis still calls it while
# loading a schema, the notice reaches Bowtie instead of the expected response,
# and every definition comes back as an error. The pinned build carries the
# same opis 2.6.0 and can go once `latest` is on a PHP release that opis stays
# quiet under. The .NET harness needs longer to answer than the two seconds
# Bowtie waits by default, so it gets its own timeout.
#
# The Go port's validator is missing here on purpose. Its harness reads stdin
# with a plain bufio.Scanner and gives up past 64 KB, which most definitions
# exceed. For the Dart port there is no harness in Bowtie at all.
IMPLEMENTATIONS=(
  -i js-ajv                   # JavaScript
  -i js-schemasafe            # JavaScript, the one the JS port validates with
  -i python-jsonschema        # Python
  -i rust-jsonschema          # Rust
  -i image:php-opis-json-schema:028f1e8128f53da9307504d15fb080477fa336ec # PHP
  -i image:dotnet-jsonschema-net:read_timeout_sec=20 # C#
)

if [ -n "${GITHUB_STEP_SUMMARY:-}" ]; then
  bowtie validate "${IMPLEMENTATIONS[@]}" "$SCHEMA_FILE" "$SRC_DIR"/*.json \
    | bowtie summary --show failures --format markdown \
    | tee "$GITHUB_STEP_SUMMARY"
else
  bowtie validate "${IMPLEMENTATIONS[@]}" "$SCHEMA_FILE" "$SRC_DIR"/*.json \
    | bowtie summary --show failures
fi
