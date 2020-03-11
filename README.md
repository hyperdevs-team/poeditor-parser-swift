# POEditor-Parser
A simple generator of swift files from a given localized POeditor `strings` file.

[![Release Version](https://img.shields.io/github/release/bq/poeditor-parser-swift.svg)](https://github.com/bq/poeditor-parser-swift/releases) 
[![Release Date](https://img.shields.io/github/release-date/bq/poeditor-parser-swift.svg)](https://github.com/bq/poeditor-parser-swift/releases)
[![Pod](https://img.shields.io/cocoapods/v/POEditor-Parser.svg?style=flat)](https://cocoapods.org/pods/POEditor-Parser)
[![Platform](https://img.shields.io/cocoapods/p/POEditor-Parser.svg?style=flat)](https://cocoapods.org/pods/POEditor-Parser)
[![GitHub](https://img.shields.io/github/license/bq/poeditor-parser-swift.svg)](https://github.com/bq/poeditor-parser-swift/blob/master/LICENSE)

[![Build Status](https://travis-ci.org/bq/poeditor-parser-swift.svg?branch=master)](https://travis-ci.org/bq/poeditor-parser-swift)
[![codecov](https://codecov.io/gh/bq/poeditor-parser-swift/branch/master/graph/badge.svg)](https://codecov.io/gh/bq/poeditor-parser-swift)

## Installation

```
$ make
```

## Usage
```
Usage:

    $ poe <APITOKEN> <id> <language>

Arguments:

    APITOKEN - The POEditor API token
    id - The id of the project
    language - The language code

Options:
    --swiftfile [default: ${SRCROOT}/${TARGET_NAME}/Literals.swift] - The output Swift file directory.
    --stringsfile [default: ${SRCROOT}/${TARGET_NAME}/Localizable.strings] - The output Strings file directory.
```

## Authors & Collaborators

* **[Edilberto Lopez Torregrosa](https://github.com/ediLT)**
* **[Raúl Pedraza León](https://github.com/r-pedraza)**
* **[Jorge Revuelta](https://github.com/minuscorp)**
* **[Sebastián Varela](https://github.com/sebastianvarela)**

## License

POEditor-Parser is available under the Apache 2.0. See the LICENSE file for more info.  
  
## Android alternative
If you want a similar solution for your Android projects, check this out: [poeditor-android-gradle-plugin](https://github.com/bq/poeditor-android-gradle-plugin)
