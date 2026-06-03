# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to
[Semantic Versioning](https://semver.org/spec/v2.0.0.html).

This repository ships the DiceBear avatar styles as pure JSON definition files
(distributed via npm, Composer, and PyPI). Versions track the DiceBear release
line.

## [Unreleased]

### Fixed

- **Lorelei:** `hairAccessories` are now rendered at `0.4` opacity, matching the
  intended design.
- **Rings:** Now uses the default `shape-rendering` instead of `crispEdges`, so
  the rings render with smooth anti-aliased edges.
- **Packaging:** The published packages now reference `LICENSE.md` in the
  `package.json` `files` field, so the license is included in the npm tarball.

## [10.1.0-rc.1] - 2026-05-31

### Added

- **Python distribution:** A `dicebear-styles` package is now published to PyPI,
  alongside the existing npm and Composer distributions, exposing the same JSON
  style definitions to Python consumers.

## [10.0.0] - 2026-05-27

See the
[v10.0.0 release notes](https://github.com/dicebear/dicebear/releases/tag/v10.0.0).

### Added

- **6 new avatar styles:** Disco, Glyphs, Initial Face, Shape Grid, Stripes, and
  Triangles.
- **Composer distribution:** Style definitions are now published to Packagist so
  the PHP library can consume them.

### Changed

- Each avatar style is now stored as a JSON definition file (built to a minified
  `*.min.json`) instead of TypeScript/JavaScript code, separating licensing and
  artwork concerns from implementation.

[Unreleased]: https://github.com/dicebear/styles/compare/v10.1.0-rc.1...HEAD
[10.1.0-rc.1]: https://github.com/dicebear/styles/compare/v10.0.0...v10.1.0-rc.1
[10.0.0]: https://github.com/dicebear/styles/releases/tag/v10.0.0
