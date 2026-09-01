# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to
[Semantic Versioning](https://semver.org/spec/v2.0.0.html).

This repository ships the DiceBear avatar styles as pure JSON definition files
(distributed via npm, Composer, PyPI, crates.io, Go modules, pub.dev, and
NuGet).
Versions track the DiceBear release line.

## [Unreleased]

### Added

- **Declarative animations.** The 19 animated styles now describe their motion
  as `animations` keyframe blocks in the definition (schema 1.6) instead of
  embedded CSS. Rendering stays opt-in through the core's `animation` option,
  paced by `animationSpeed`, and every block carries a name (`gaze` has `look`,
  `blink` and `hop`, `blobs` has `sway` and `wander`, and so on), so single
  animations can be picked by name. Static output is unchanged. Reading these
  definitions requires a core with schema 1.6 support.

### Removed

- **The CSS animation component.** The animated styles no longer ship the
  speed-variant component, so the `animationVariant` option and the
  `animation` tag are gone. Passing `animationVariant` to these styles renders
  the static avatar. Use `animation` and `animationSpeed` instead.

### Fixed

- **Notionists:** 24 hair variants no longer let a bold background show
  through between hair and head outline
  ([#2](https://github.com/dicebear/styles/issues/2)).

## [10.6.0] - 2026-08-26

## [10.6.0-rc.2] - 2026-08-26

### Added

- **New style: Cameo.** A head that has hair and a mouth but no eyes. Six head
  shapes, eleven hairs and seven mouths, all clipped to the head. One `shade`
  slot holds its alpha in the hex value, once dark and once light, so every
  shape exists in both tones. The style has no background color of its own.
  Static, hand-authored, CC0 1.0.
- **New style: Gaze.** A pastel body with a pair of eyes and nothing else.
  Eleven silhouettes, seven of them plain geometry, the rest a pill, a column,
  an egg and an arch. Eleven eye pairs, five eye spacings, and a small tilt
  and size change per seed. The eyes take whichever ink color contrasts with
  the body. When animated, they wander, they blink, and the body hops.
  Hand-authored, CC0 1.0.
- **New style: Marbles.** A small face on a colored marble. Three blurred
  ellipses shade the disc without a gradient definition: a second color, a
  pastel tint and a white bloom. Twenty tops cover hats, headphones, hair, a
  bow and an antenna. The face has nine eye sets, eleven mouths and a nose on
  three of four seeds, all at one ink weight. Static by design, it carries no
  animation component. Hand-authored, CC0 1.0.
- **New style: Shadows.** A bust as a filled silhouette, all of it in one ink
  on a pale ground. Six shoulder lines, five head shapes, and a hat or a
  hairstyle on three of four seeds. The top sits behind the head, so both
  merge into one outline. Eleven inks, ten backgrounds. Static, hand-authored,
  CC0 1.0.
- **New style: Slice.** One silhouette, cut into three to six horizontal bands
  and shifted sideways against each other. Ten shapes, sixteen cut patterns,
  and a tilt of up to 45 degrees. Each band carries a different amount of
  white over the body color, so the shape runs through one hue from light to
  dark. Static, hand-authored, CC0 1.0.
- **New style: Stack.** A balanced pile of stones. Eleven layouts set how many
  stones lie on each other and how far they lean, and each one squashes one of
  seven stone shapes to its own width and height, with one of six caps on top.
  Three tones, light, mid and deep, on a paper background. Static,
  hand-authored, CC0 1.0.

## [10.6.0-rc.1] - 2026-08-22

### Added

- **`DiceBear.Styles` on NuGet.** The definitions now reach .NET the way they
  reach the other ecosystems, through a package rather than a manual download:
  `dotnet add package DiceBear.Styles`, then `Style.Parse(Styles.Lorelei)`.
  Every style is embedded in the assembly and reachable as a property or by
  name through `Get`.

### Changed

- **`LICENSE.md` now covers the code as well.** It used to list the styles
  only, while the MIT license for the shims, the scripts and the manifests
  lived in file headers. Both parts are now in the file that every package
  manifest points at.
- **The npm package declares its license.** `package.json` carried no `license`
  field, so tooling reported the package as unlicensed. It now says
  `SEE LICENSE IN LICENSE.md`.

### Fixed

- **Voxel Art: several rendering errors.** Stray light and dark edges no
  longer cut across hair and faces, shadows stay on the surface that catches
  them instead of falling on the background, and arms and hands are no longer
  buried under clothing. A few shapes look slightly different as a result,
  which is part of the fix.
- **Voxel Bot: the shadow below the torso.** It ran the full width of the body
  and fell onto the background between and beside the legs. Now it lands only
  on the legs themselves.

## [10.5.0] - 2026-08-16

## [10.5.0-rc.1] - 2026-08-15

### Added

- **New style: Cutouts.** Faces assembled from torn craft paper. The two eyes
  never match on purpose, six head silhouettes place their own hair, brows
  and features, and every scrap casts the same soft drop shadow. The accent
  palettes are curated darker than every face color, so mouths and noses
  stay readable on any head. Hand-authored, CC0 1.0.
- **New style: Line Face.** A calm face drawn with a few brush strokes
  directly on the background, in the spirit of one-line portraits. Eight eye
  pairs, six noses and eight mouths, each a single clean stroke, and the
  mouth settles into one of three tilts per seed. Hand-authored, CC0 1.0.
- **New style: Patchwork.** A quilt laid from traditional blocks such as
  pinwheel, flying geese, rail fence and clamshells. Each avatar picks two
  of the 18 blocks and repeats them as diagonal twins rotated by 180
  degrees, so every quilt comes out point-symmetric. All shapes share one
  grid, which lets neighbouring blocks meet flush at the seams.
  Hand-authored, CC0 1.0.

### Changed

- **Nine styles now expose the dark color they draw with.** Adventurer,
  Adventurer Neutral, Croodles, Croodles Neutral, Lorelei, Notionists,
  Notionists Neutral, Open Peeps and Toon Head painted that color into the
  artwork, where no render option could reach it. Each style names the new
  group after the job the color does there:

  - `ink` carries the whole drawing, outlines and filled masses alike. Seven
    styles use it: Adventurer, Adventurer Neutral, Croodles, Croodles Neutral,
    Notionists, Notionists Neutral and Open Peeps.
  - `outline` is only the head and ear contour, which is why Lorelei uses that
    name. Every feature there already had a group of its own.
  - `stroke` is a real SVG stroke rather than a filled path. Toon Head is the
    only style drawn that way.

  Five of the nine gained more than that one group. Adventurer and Adventurer
  Neutral split the face into `eyes`, `sclera`, `lips`, `teeth`, `tongue`,
  `throat`, `uvula` and `glasses`, and Adventurer adds `earrings` on top.
  Croodles gained `facialHair` for the beard and moustache. Notionists had no
  color groups at all before and now carries `ink` and `paper`, where the paper
  is the body the ink sits on rather than the canvas behind the figure.
  Notionists Neutral gains the same two next to the background it already had.

  Existing avatars keep their look. Every group defaults to the value the
  artwork already used, no palette changed, and no variant, probability or seed
  behaves differently. The SVG is not byte-identical to the previous release,
  because a literal `black` now resolves to `#000000` and separating the groups
  re-exported some path data. Those differences sit on the edges of eyebrows
  and eyes and stay under one percent of the pixels in a 300 px render. Only a
  raster cache that compares bytes will notice.

## [10.4.0] - 2026-08-09

### Added

- **New style: Voxel Bot.** The robot sibling of Voxel Art, built on the same
  voxel projection: a pastel shell, a dark faceplate with glowing LED eyes
  and mouth, gripper hands, chest panels from heart to cassette slot, and
  antennas from a radar dish to a siren. The LED color never repeats the
  shell color. When animated, the eyes power off briefly, the upper body
  jolts up by one voxel, and the head extends one more off the neck.
  Hand-authored, CC0 1.0.
- **New style: Voxel Art.** A chibi character built from voxels, seen almost
  head-on with the depth receding up and to the right. 76 variants across ten
  components, from a deep long-hair pool over animal-ear hoods to outfits with
  checkered jackets and dresses. When animated, the eyes blink and the upper
  body jolts up by one voxel while the feet stay planted. Hand-authored,
  CC0 1.0.

## [10.3.0] - 2026-08-01

### Changed

- **Moods, Landscape, Clay, Critters:** Renamed five variants whose names read
  as something else out of context. In `moods`, `face: hex` is now `hexagon`,
  which is also what `disco` and `shape-grid` call that shape. In `landscape`,
  `orb: halo` is now `glow`. The crossed and diverging eyes now say which way
  the pupils point instead of borrowing clinical terms: `clay` `eyes: cross`
  and `eyes: walleyed` became `inward` and `outward`, and `critters`
  `eyes: crossEyed` became `inward`. All four styles are release candidates and
  no stable release ever shipped the old names. Because the variant pool is
  drawn in alphabetical order, the rename moves these variants within their
  pool, so a seed in one of these styles can render differently than it did in
  the previous release candidate.

## [10.3.0-rc.3] - 2026-07-31

### Added

- **New style: Clay.** A hand-molded plasticine creature on a warm paper
  backdrop. Fourteen wobbly silhouettes with googly eyes and carved mouths,
  most seeds with a pinched top or a stamped belly mark. When animated, the
  body squashes gently and the pupils wobble. Hand-authored, CC0 1.0.

## [10.3.0-rc.2] - 2026-07-31

### Added

- **New style: Weave.** A woven tartan pattern: two to three translucent
  bands per axis over a light tinted tile, with the band colors repeating
  across both axes and a fine accent line per axis. Diagonal on most seeds,
  straight on the rest. Band positions are continuous, so two seeds
  practically never share a design. Static by design, it carries no
  animation component. Hand-authored, CC0 1.0.
- **Opt-in animation.** All new styles below, as well as Shapes, Glass, Thumbs,
  and Initial Face, carry an `animation` component. By default (`none`) they
  render fully static. The `animationVariant` render option selects a speed from
  `fastest` to `slowest`. A static avatar next to an animated one stays static,
  browsers without CSS `:has()` support show the static image, and the
  animations respect `prefers-reduced-motion`.
- **Animation tag.** The animated variants carry the bare `animation` variant
  tag, so the `tags` render option can switch the animation on (`animation`, at
  a random speed per seed) or keep it off (`!animation`). The static default
  variant carries no tag.
- **New style: Moods.** A lovable character face for product UIs: a big pastel
  face shape on a deep background, drawn with the shared depth system (cast
  shadow, light and dark rims). Nine silhouettes, sixteen eye sets (every open
  eye a white eyeball with an ink pupil), and fifteen thick rounded mouths,
  plus blush cheeks on half the seeds. The smiling variants have higher
  weights. When animated, it blinks. Hand-authored, CC0 1.0.
- **New style: Critters.** A small bug-like creature in shaded pastel on a deep
  background: fourteen bodies, nineteen eye sets, nineteen mouths, and usually
  an attachment in a second pastel. When animated, it bobs, blinks, and its
  horns sway. Hand-authored, CC0 1.0.
- **New style: Sprouts.** A potted plant with the face on the pot: twelve
  plants, seven pot shapes, and the Critters face set. When animated, the plant
  sways and the face blinks. Hand-authored, CC0 1.0.
- **New style: Loops.** A truchet pattern: quarter-circle arc tiles on a 3x3
  grid join into meandering paths. The pattern is tone-in-tone with the
  background by default, `patternVariant` switches to plain white or black. When
  animated, the tiles quarter-turn and keep reconfiguring the pattern.
  Hand-authored, CC0 1.0.
- **New style: Pixelbot.** An AI-bot face on a 12x12 LED panel. Unlit cells stay
  dark, lit pixels draw the face: seven eye sets and five mouths, nine glow
  colors, ten dark backgrounds. With animation enabled, the eyes blink row by
  row, the mouths widen, and every pixel switches hard like a real LED.
  Hand-authored, CC0 1.0.
- **New style: Squircles.** A depth stack of three to five nested superellipses.
  Opacity rises toward the center, each layer is jittered and rotated, and a
  small accent squircle appears on most seeds. Hand-authored, CC0 1.0.
- **New style: Blobs.** Two to four layered organic forms in white or black over
  a strong background color. Compositions range from calm concentric stacks to
  off-center clusters. Hand-authored, CC0 1.0.
- **New style: Constellation.** A constellation over a deep night sky, drawn
  from real star data, plus a per-seed star field, an occasional shooting star,
  and two rare easter eggs. Hand-authored, CC0 1.0.
- **New style: Landscape.** An abstract layered landscape: four hill bands, an
  optional sun or moon, and curated nature palettes that keep every random
  combination harmonious. Hand-authored, CC0 1.0.
- **New style: Planets.** A single planet over deep space with ten surface
  variants, an optional ring, moons, and a random star field. `shadeVariant`
  switches to a crisp two-tone shading. Hand-authored, CC0 1.0.
- **New style: Waves.** Three to six translucent wave bands over a saturated
  background color, freely rotated per seed. `rotationVariant` locks the
  direction. Hand-authored, CC0 1.0.

### Removed

- **Variant tags.** The tags introduced in 10.3.0-rc.1 moved to the
  `feat/variant-tags` branch and are not part of this release. The schema
  references stay at `@dicebear/schema` 1.3.0.

## [10.3.0-rc.1] - 2026-06-21

### Added

- **Variant tags.** The character styles now describe their variants with tags,
  so the DiceBear `tags` render option can filter the variant pool (for example,
  keep only `mood:happy` mouths, or drop facial hair with `!facialHair`). The
  shared set covers `mood`, `hairLength`, `hairStyle`, `headwear`, `facialHair`,
  `eyewear`, and `accessory`. The abstract styles carry no tags. This needs
  `@dicebear/schema` 1.3.0, and every definition's `$schema` reference now
  points to it.

### Fixed

- Re-exported the `glasses` in adventurer-neutral, the `hair` in big-smile, and
  the `mouth` in croodles and croodles-neutral. This shortens overlong
  coordinate decimals in the exported paths, for example `42.1899` becomes
  `42.19`.

## [10.2.0] - 2026-06-08

### Added

- **Dart:** The styles are now available as a `dicebear_styles` package on
  pub.dev. The Dart shim landed after the `v10.2.0` tag, so the pub.dev release
  of this version came from a later commit. Dart has no compile-time file
  embedding, so `scripts/build.sh` generates one library per style with the raw
  JSON as a string constant (e.g. `package:dicebear_styles/adventurer.dart`); a
  compiled app only embeds the styles it imports. The umbrella library
  `dicebear_styles.dart` re-exports every style and adds `get(name)` and `all`,
  so the Dart, Rust and Go shims share one API. Each generated file credits its
  style's artist and license. The generated `lib/` is git-ignored (like the npm
  `dist/`) and built fresh by the test and publish workflows;
  `tool/check_parity.dart` proves in CI that every embedded constant is
  byte-identical to its `src/*.json` source.
- **Go:** The styles are now available as a Go module
  (`github.com/dicebear/styles/v10`). Each style is embedded and exposed as an
  exported `string` variable and via `Get(name)`/`All()`. Generated by
  `scripts/build.sh` alongside the Rust shim.

### Changed

- **Rust (breaking):** Renamed `enabled()` to `all()`, so the Rust and Go shims
  share one API (`<Style>` constant/variable + `get(name)` + `all()`/`All()`).
  We normally follow [Semantic Versioning](https://semver.org/) strictly, which
  would make this a major bump. We make a one-time exception here: the crate had
  only just been uploaded to crates.io and was never promoted or officially
  announced, so it had no real-world users to break. Renaming now (before
  adoption) buys a clean, cross-language API rather than carrying a misnamed
  function (or a deprecated alias) forever.

## [10.1.0] - 2026-06-03

### Added

- **Rust distribution:** A `dicebear-styles` crate is now published to
  crates.io, alongside the existing npm, Composer, and PyPI distributions. It
  embeds the same JSON style definitions via `include_str!`, gated behind one
  Cargo feature per style, and exposes each as a `&'static str` constant plus
  `get(name)`/`enabled()` lookup helpers.

### Changed

- **Schema:** All style definitions now reference `@dicebear/schema@1.1.0`
  (previously `1.0.0`).

### Fixed

- **Lorelei:** The `mouth` is now visible through `beard` variants. The masking
  group overlaying the mouth on beards was rendered at `0` opacity (fully
  hidden) and is now at `0.4`, matching the intended design.
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

[Unreleased]: https://github.com/dicebear/styles/compare/v10.6.0...HEAD
[10.6.0]: https://github.com/dicebear/styles/compare/v10.6.0-rc.2...v10.6.0
[10.6.0-rc.2]: https://github.com/dicebear/styles/compare/v10.6.0-rc.1...v10.6.0-rc.2
[10.6.0-rc.1]: https://github.com/dicebear/styles/compare/v10.5.0...v10.6.0-rc.1
[10.5.0]: https://github.com/dicebear/styles/compare/v10.5.0-rc.1...v10.5.0
[10.5.0-rc.1]: https://github.com/dicebear/styles/compare/v10.4.0...v10.5.0-rc.1
[10.4.0]: https://github.com/dicebear/styles/compare/v10.3.0...v10.4.0
[10.3.0]: https://github.com/dicebear/styles/compare/v10.3.0-rc.3...v10.3.0
[10.3.0-rc.3]: https://github.com/dicebear/styles/compare/v10.3.0-rc.2...v10.3.0-rc.3
[10.3.0-rc.2]: https://github.com/dicebear/styles/compare/v10.3.0-rc.1...v10.3.0-rc.2
[10.3.0-rc.1]: https://github.com/dicebear/styles/compare/v10.2.0...v10.3.0-rc.1
[10.2.0]: https://github.com/dicebear/styles/compare/v10.1.0...v10.2.0
[10.1.0]: https://github.com/dicebear/styles/compare/v10.1.0-rc.1...v10.1.0
[10.1.0-rc.1]: https://github.com/dicebear/styles/compare/v10.0.0...v10.1.0-rc.1
[10.0.0]: https://github.com/dicebear/styles/releases/tag/v10.0.0
