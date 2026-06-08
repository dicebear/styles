# DiceBear Avatar Styles

This repository contains all official avatar style definitions for
[DiceBear](https://www.dicebear.com). An avatar style definition is a JSON file
that describes how to create an avatar. It contains all necessary information
like available elements and colors. The JSON files are ideal for creating
avatars in different programming languages with the corresponding DiceBear
wrapper. The JSON schema for the avatar style definitions can be found in the
[`@dicebear/schema`](https://github.com/dicebear/schema) package.

## Generate definitions

Most of the JSON files were created using the
[DiceBear Exporter](https://www.dicebear.com/guides/create-an-avatar-style-with-figma/)
for Figma. The used Figma files are linked in the `figma` folder. Files created
with this plugin are marked accordingly and should not be adjusted manually, but
exported again with the Figma plugin.

## Usage

**JavaScript**

```bash
npm install @dicebear/styles
```

```js
import adventurer from '@dicebear/styles/adventurer.json' with { type: 'json' };
import lorelei from '@dicebear/styles/lorelei.json' with { type: 'json' };
```

**PHP**

```bash
composer require dicebear/styles
```

```php
$basePath = \Composer\InstalledVersions::getInstallPath('dicebear/styles');

$adventurer = json_decode(file_get_contents($basePath . '/src/adventurer.json'), true);
$lorelei    = json_decode(file_get_contents($basePath . '/src/lorelei.json'), true);
```

**Python**

```bash
pip install dicebear-styles
```

```python
import json
from importlib.resources import files

adventurer = json.loads(files('dicebear_styles').joinpath('adventurer.json').read_text('utf-8'))
lorelei    = json.loads(files('dicebear_styles').joinpath('lorelei.json').read_text('utf-8'))
```

**Rust**

Each style is gated behind a feature of the same name, so a binary only embeds the
styles it opts into (use the `all` feature to pull in every style):

```bash
cargo add dicebear-styles --features adventurer,lorelei
```

The enabled styles are embedded at compile time and exposed as raw JSON
(`&'static str`). Parse them with `serde_json`:

```rust
use dicebear_styles::{ADVENTURER, LORELEI};

let adventurer: serde_json::Value = serde_json::from_str(ADVENTURER)?;
let lorelei: serde_json::Value = serde_json::from_str(LORELEI)?;

// Or look one up by name at runtime (None if unknown or its feature is off):
let style = dicebear_styles::get("adventurer");
```

**Go**

```bash
go get github.com/dicebear/styles/v10
```

Every style is embedded at compile time and exposed as raw JSON (`string`) — both
as an exported variable and by name via `Get`. Parse it with `encoding/json`:

```go
import (
	"encoding/json"

	styles "github.com/dicebear/styles/v10"
)

var adventurer map[string]any
_ = json.Unmarshal([]byte(styles.Adventurer), &adventurer)

// Or look one up by name (ok is false if the style is unknown):
raw, ok := styles.Get("lorelei")

// Names() lists every embedded style.
all := styles.Names()
```

## Contributing

See
[CONTRIBUTING.md](https://github.com/dicebear/definitions/blob/main/CONTRIBUTING.md)
for local development, testing, and the release process.

## License

The avatar styles are licensed under different licenses. More information can be
found in the file
[LICENSE.md](https://github.com/dicebear/definitions/blob/main/LICENSE.md) or in
the definition files themselves.

## Sponsors

Advertisement: Many thanks to our sponsors who provide us with free or discounted products.

<a href="https://bunny.net/" target="_blank" rel="noopener noreferrer">
    <picture>
        <source media="(prefers-color-scheme: dark)" srcset="https://www.dicebear.com/sponsors/bunny-light.svg">
        <source media="(prefers-color-scheme: light)" srcset="https://www.dicebear.com/sponsors/bunny-dark.svg">
        <img alt="bunny.net" src="https://www.dicebear.com/sponsors/bunny-dark.svg" height="64">
    </picture>
</a>
