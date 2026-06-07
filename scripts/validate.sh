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

IMPLEMENTATIONS=(
  -i js-ajv                   # JavaScript
  -i php-opis-json-schema     # PHP
  -i python-jsonschema        # Python
  -i rust-jsonschema          # Rust
)

if [ -n "${GITHUB_STEP_SUMMARY:-}" ]; then
  bowtie validate "${IMPLEMENTATIONS[@]}" "$SCHEMA_FILE" "$SRC_DIR"/*.json \
    | bowtie summary --show failures --format markdown \
    | tee "$GITHUB_STEP_SUMMARY"
else
  bowtie validate "${IMPLEMENTATIONS[@]}" "$SCHEMA_FILE" "$SRC_DIR"/*.json \
    | bowtie summary --show failures
fi
