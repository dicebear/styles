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

// Verifies that every style constant embedded in lib/ is byte-identical to its
// src/*.json source, and that `all` matches the file list. This guards the
// string escaping in scripts/build.sh's Dart generator. Run it from the repo
// root: dart run tool/check_parity.dart

import 'dart:io';

import 'package:dicebear_styles/dicebear_styles.dart' as styles;

void main() {
  // Sort the bare style names (not the file paths) so the order matches the
  // generator, which sorts basenames under LC_ALL=C: `adventurer` sorts before
  // `adventurer-neutral`, while `adventurer.json` would sort after it.
  final names = Directory('src')
      .listSync()
      .whereType<File>()
      .map((f) => f.uri.pathSegments.last)
      .where((f) => f.endsWith('.json'))
      .map((f) => f.substring(0, f.length - '.json'.length))
      .toList()
    ..sort();

  var failures = 0;

  for (final name in names) {
    final file = File('src/$name.json');

    final embedded = styles.get(name);
    if (embedded == null) {
      stderr.writeln('MISSING: no embedded constant for `$name`');
      failures++;
    } else if (embedded != file.readAsStringSync()) {
      stderr.writeln('MISMATCH: `$name` differs from src/$name.json');
      failures++;
    }
  }

  if (styles.all.join('\n') != names.join('\n')) {
    stderr.writeln('MISMATCH: `all` does not match the src/*.json file list');
    failures++;
  }

  if (failures > 0) {
    exit(1);
  }

  print('OK: ${names.length} styles byte-identical to src/');
}
