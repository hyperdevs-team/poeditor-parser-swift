# POEditor-Parser
A generator of Swift literal files and Apple String Catalogs (`.xcstrings`) from a POEditor project.

[![Release Version](https://img.shields.io/github/release/hyperdevs-team/poeditor-parser-swift.svg)](https://github.com/hyperdevs-team/poeditor-parser-swift/releases) 
[![Release Date](https://img.shields.io/github/release-date/hyperdevs-team/poeditor-parser-swift.svg)](https://github.com/hyperdevs-team/poeditor-parser-swift/releases)
[![GitHub](https://img.shields.io/github/license/hyperdevs-team/poeditor-parser-swift.svg)](https://github.com/hyperdevs-team/poeditor-parser-swift/blob/master/LICENSE)
[![codecov](https://codecov.io/gh/hyperdevs-team/poeditor-parser-swift/branch/master/graph/badge.svg)](https://codecov.io/gh/hyperdevs-team/poeditor-parser-swift)

## What's new in 3.0

3.0 is a rewrite around Apple String Catalogs. **Breaking changes:**

- Only the `.xcstrings` format is supported. The old `.strings` output has been removed.
- The single monolithic command is replaced by explicit subcommands: `download`, `generate`, `distribute`, `filter`, `remove`.
- The `--onlygenerate`, `--stringsfile`, `--format` and `--exportall` options are gone.

## Installation

POEditor-Parser is available through [Mint](https://github.com/yonaskolb/Mint).

Add the following line to your `Mintfile`:
```ruby
hyperdevs-team/poeditor-parser-swift@3.0.0
```

## Commands

### `download`
Download a String Catalog (all languages) from POEditor. Placeholders like `{1{var}}` are normalized to `{{var}}`.

```
poe download --apitoken $TOKEN --projectid $ID --language es --out Localizable.xcstrings
```

| Option | Default | Description |
|--------|---------|-------------|
| `--apitoken` | – | The POEditor API token (required) |
| `--projectid` | – | The POEditor project id (required) |
| `--language` | `en` | Preferred language code |
| `--out` | `Localizable.xcstrings` | Output `.xcstrings` file path |

### `generate`
Generate the Swift literals file from a local `.xcstrings`.

```
poe generate --in Localizable.xcstrings --swiftfile Sources/Literals.swift --outputformat enum --typename Literals --keysformat lowerCamelCase
```

| Option | Default | Description |
|--------|---------|-------------|
| `--in` | `Localizable.xcstrings` | Input `.xcstrings` file path |
| `--swiftfile` | `Sources/Literals.swift` | Output Swift file path |
| `--typename` | `Literals` | Type name that stores all localized vars |
| `--tablename` | – | The `tableName` value for `NSLocalizedString` |
| `--outputformat` | `struct` | Swift output format (`enum` or `struct`) |
| `--keysformat` | `upperCamelCase` | Key format (`lowerCamelCase` or `upperCamelCase`) |
| `--language` | – | Preferred language to source values from |

### `distribute`
Split a multi-variant `.xcstrings` into a single-variant one. Keys may carry a suffix `key[variantA|variantB]`; a variant-specific key wins over the plain (common) key of the same base name, and keys targeting other variants are dropped.

```
poe distribute --in Localizable.xcstrings --out Variants/Yoigo/Localizable.xcstrings --variant yoigo
```

| Option | Default | Description |
|--------|---------|-------------|
| `--in` | `Localizable.xcstrings` | Input multi-variant `.xcstrings` file path |
| `--out` | `Localizable.xcstrings` | Output single-variant `.xcstrings` file path |
| `--variant` | – | The variant to extract (`key[variant]` suffix) |

### `filter`
Keep only the changes of keys matching `--keys` between a baseline and a working `.xcstrings`; every other key falls back to the baseline. The command is git-agnostic: provide the baseline (e.g. the `HEAD` contents) as a file.

```
poe filter --baseline head.xcstrings --working Localizable.xcstrings --out Localizable.xcstrings --keys "about*,*profile*"
```

| Option | Default | Description |
|--------|---------|-------------|
| `--baseline` | – | Baseline `.xcstrings` (e.g. `HEAD` contents; may be absent/empty) |
| `--working` | – | Working-tree `.xcstrings` |
| `--out` | `--working` | Output `.xcstrings` file path |
| `--keys` | – | Comma-separated key patterns (`*` and `?` wildcards) |

### `remove`
Remove every key matching the given patterns.

```
poe remove --in Localizable.xcstrings --keys "about*,legacy_key" [--dryrun]
```

| Option | Default | Description |
|--------|---------|-------------|
| `--in` | `Localizable.xcstrings` | Input `.xcstrings` file path |
| `--out` | `--in` | Output `.xcstrings` file path |
| `--keys` | – | Comma-separated key patterns (`*` and `?` wildcards) |
| `--dryrun` | off | Only print the keys that would be removed |

### Key patterns
`--keys` (in `filter` and `remove`) accepts comma-separated patterns matched against the whole key:

- `*` matches any run of characters (e.g. `about*`, `*profile*`).
- `?` matches a single character (e.g. `user?info`).

## Authors & Collaborators

* **[Edilberto Lopez Torregrosa](https://github.com/ediLT)**
* **[Raúl Pedraza León](https://github.com/r-pedraza)**
* **[Jorge Revuelta](https://github.com/minuscorp)**
* **[Sebastián Varela](https://github.com/sebastianvarela)**
* **[David Martínez García](https://github.com/daviwiki)**
* **[Adrián Ruiz Lafuente](https://github.com/adrianrl)**

## License

POEditor-Parser is available under the Apache 2.0. See the LICENSE file for more info.  

## Android alternative
If you want a similar solution for your Android projects, check this out: [poeditor-android-gradle-plugin](https://github.com/hyperdevs-team/poeditor-android-gradle-plugin)
