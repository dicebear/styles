# Contributing

Thanks for your interest in contributing to `@dicebear/styles`.

This repository holds the official DiceBear avatar style definitions: the
JSON files in `src/` that `@dicebear/core` (and every other DiceBear
wrapper) loads to render avatars. The schema those files conform to lives
in the [`@dicebear/schema`](https://github.com/dicebear/schema) package.

## Before you start

- Fixing a typo, a color, or a geometry bug in an existing style: open a
  pull request directly.
- Proposing a brand-new avatar style: open an issue before you do the work
  so we can align on scope, license, and naming.
- Security issues go privately to <contact@dicebear.com>, never into
  a public issue.
- Contributors follow the
  [DiceBear Code of Conduct](https://github.com/dicebear/.github/blob/main/CODE_OF_CONDUCT.md).

## The definition file is the source

Every file in `src/` is a complete style on its own. There is no separate
Figma file to keep in sync. Most of them were exported by
[DiceBear Studio](https://www.figma.com/community/plugin/1005765655729342787),
the DiceBear plugin for Figma, and say so in their `$comment` at the top.

Pick the tool that fits the change:

- Edit the JSON by hand for a color, a weight, a probability, or a small
  geometry fix. Run the optimizer of the DiceBear CLI before you commit
  (`npx dicebear optimize src/<style>.json -o src/<style>.json`), CI flags
  files it would still shrink.
- For artwork, import the definition into a Figma file with DiceBear Studio.
  The plugin rebuilds the components, variants and palettes as layers. Make
  the change in Figma, export the style again and replace the file in
  `src/`. See
  [Create an avatar style with Figma](https://www.dicebear.com/guides/create-an-avatar-style-with-figma/)
  for the full walkthrough.

Both ways lead to the same file, and a hand edit survives the next trip
through Figma, since the import reads the file you edited.

## Requirements

- [Node.js](https://nodejs.org/) 20 or newer
- For tests only: [uv](https://docs.astral.sh/uv/) and a container runtime
  ([Docker](https://www.docker.com/) or [Podman](https://podman.io/)), both
  needed by [Bowtie](https://docs.bowtie.report/)

## Local setup

```sh
git clone https://github.com/dicebear/styles.git
cd styles
npm install
```

Install the validator once per machine:

```sh
brew install uv            # macOS; see uv docs for other platforms
uv tool install bowtie-json-schema
```

## Scripts

| Script             | What it does                                                       |
| ------------------ | ------------------------------------------------------------------ |
| `npm run build`    | Writes minified definition files to `dist/` via `scripts/build.sh` |
| `npm test`         | Validates every file in `src/` against `@dicebear/schema`          |
| `npm run validate` | Same as `npm test`                                                 |

`npm test` uses Bowtie under the hood; the first run pulls a validator
container, so expect a slower warm-up.

## Making a change

1. Update the definition in `src/<style>.json`, or replace it with a fresh
   export from DiceBear Studio.
2. Run `npm test`. If the schema rejects the file, Bowtie prints the exact
   keyword and JSON pointer that failed, so you can fix the offending
   value directly.
3. Run `npm run build` and commit the regenerated `styles.rs`, `Cargo.toml`,
   `styles.go` and `styles.cs` alongside `src/` (CI fails the PR if they are
   stale). The
   minified `dist/` files and the Dart `lib/` are regenerated too, but they are
   git-ignored: only the npm publish ships `dist/`, and only the pub.dev
   publish ships `lib/`.
4. If you changed a style's license or credits, update `LICENSE.md`
   accordingly.

### Schema mismatches

If the validator complains about a field you believe is correct, the
problem may be in the schema rather than the definition. In that case,
open an issue on
[`dicebear/schema`](https://github.com/dicebear/schema/issues) referencing
the failing fixture here, and wait for the schema change to land before
you update the definition.

## Licensing

Every avatar style in this repository ships with its own license. The
master list is [`LICENSE.md`](./LICENSE.md); individual styles also carry
the license metadata inside their definition JSON. When you contribute a
new style, include the license terms in both places and make sure you
have the right to redistribute the artwork under them.

By opening a pull request you agree that your contribution is released
under the license you declare for your style (MIT for the tooling and
infrastructure, per-style for the art itself).

## Releasing (maintainers only)

Publishing is automated via the
[publish workflow](.github/workflows/publish.yml). To cut a release, bump the
version across all four manifests and tag it:

```sh
scripts/version.sh <version>   # e.g. 10.1.0 or 10.2.0-rc.1
git push && git push --tags
```

`scripts/version.sh` updates `version` in `package.json`, `pyproject.toml`,
`Cargo.toml`, `pubspec.yaml` **and** `DiceBear.Styles.csproj`, syncs
`package-lock.json`, then creates the commit and the `v<version>` tag. All five
manifests carry the same version, so
always release via this script (not `npm version`, which would bump only
`package.json`). Use a valid [semver](https://semver.org/) value; for
prereleases note that PyPI normalizes to PEP 440, so npm publishes `10.2.0-rc.1`
while PyPI publishes `10.2.0rc1`.

On the tag, the workflow:

1. Validates every file in `src/` and builds the minified dist files.
2. Publishes to npm with provenance (`@dicebear/styles`).
3. Builds the data-only wheel from `src/` and publishes to PyPI via Trusted
   Publishing (`dicebear-styles`).
4. Publishes the Rust crate to crates.io via Trusted Publishing
   (`dicebear-styles`).
5. Publishes the Dart package to pub.dev via the GitHub Actions integration
   (`dicebear_styles`). This requires automated publishing to be enabled in the
   pub.dev admin settings for the package (repository `dicebear/styles`, tag
   pattern `v{{version}}`).
6. Packs the assembly with the embedded definitions and publishes it to NuGet
   via Trusted Publishing (`DiceBear.Styles`). This requires a trusted
   publishing policy on nuget.org for this repository and workflow.

Packagist (`dicebear/styles`) and the Go module proxy
(`github.com/dicebear/styles/v11`) both pick up the same Git tag automatically,
with no publish step. The Go version lives entirely in the tag, so `scripts/version.sh`
does not touch `go.mod`.

> **Major version bumps and Go.** Go encodes the major version in the import path:
> the `go.mod` module path is `github.com/dicebear/styles/v11`, and consumers
> import that. On the next major, that suffix must be bumped by hand in `go.mod`
> (and the README import examples). `scripts/version.sh` refuses to tag while the
> module path and the version disagree, because the Go module proxy rejects such
> a tag and the release would be unusable from Go.
