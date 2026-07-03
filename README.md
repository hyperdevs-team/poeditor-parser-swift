# POEditor-Parser
A simple generator of swift files from a given localized POeditor `strings` file.

[![Release Version](https://img.shields.io/github/release/hyperdevs-team/poeditor-parser-swift.svg)](https://github.com/hyperdevs-team/poeditor-parser-swift/releases) 
[![Release Date](https://img.shields.io/github/release-date/hyperdevs-team/poeditor-parser-swift.svg)](https://github.com/hyperdevs-team/poeditor-parser-swift/releases)
[![GitHub](https://img.shields.io/github/license/hyperdevs-team/poeditor-parser-swift.svg)](https://github.com/hyperdevs-team/poeditor-parser-swift/blob/master/LICENSE)
[![codecov](https://codecov.io/gh/hyperdevs-team/poeditor-parser-swift/branch/master/graph/badge.svg)](https://codecov.io/gh/hyperdevs-team/poeditor-parser-swift)

## Installation

POEditor-Parser is available through [Mint](https://github.com/yonaskolb/Mint)

To install it, simply add the following line to your `Mintfile`:
```ruby
hyperdevs-team/poeditor-parser-swift@2.2.0
```

## Usage

```ogdl
/bin/poe $APITOKEN $PROJECTID $LANGUAGE
```

### Options:
* `--apitoken` - The POEditor API token
* `--projectid` - The id of the project in POEditor
* `--projectlanguage` - The language code in POEditor
* `--onlygenerate` [default: false] -
* `--swiftfile` [default: Sources/Literals.swift] - The output Swift file directory.
* `--stringsfile` [default: Sources/Localizable.strings] - The output Strings file directory.
* `--typename` [default: Literals] - The type name that store all localized vars
* `--tablename` - The tableName value for NSLocalizedString
* `--outputformat` [default: Struct] - The output format for swift file (enum or struct)
* `--keysformat` [default: UpperCamelCase] - The format for the localized key
* `--format` [default: strings] - The translation file format to download and generate (`strings` or `xcstrings`). With `xcstrings` the file at `--stringsfile` is written with a `.xcstrings` extension, containing the full downloaded String Catalog (all languages). The generated `.swift` file keeps the same format regardless of this option.
* `--exportall` [default: false] - Download all languages at once (POEditor `options=[{"export_all": 1}]`). Does not have any effect when `--format` is `strings`.

Run poe help for more info

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
