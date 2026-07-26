import Foundation

/// In-memory model of an Apple String Catalog (`.xcstrings`) file.
///
/// This is the single source of truth for reading and writing `.xcstrings`.
/// Every operation that manipulates a catalog (parse, distribute per variant,
/// filter, remove keys, generate Swift) works on this type instead of poking
/// at raw JSON, so the on-disk format is defined in exactly one place.
public struct StringCatalog: Equatable {
    public var sourceLanguage: String
    public var version: String
    /// key -> entry. Order is irrelevant: serialization always sorts keys.
    public var strings: [String: Entry]

    public init(sourceLanguage: String, version: String, strings: [String: Entry]) {
        self.sourceLanguage = sourceLanguage
        self.version = version
        self.strings = strings
    }

    /// A single translatable key: its localizations plus optional Xcode metadata
    /// (`comment`, `extractionState`) that we preserve verbatim so re-writing a
    /// catalog is lossless.
    public struct Entry: Equatable {
        public var localizations: [String: Localization]
        public var comment: String?
        public var extractionState: String?

        public init(localizations: [String: Localization], comment: String? = nil, extractionState: String? = nil) {
            self.localizations = localizations
            self.comment = comment
            self.extractionState = extractionState
        }
    }

    public struct Localization: Equatable {
        public var value: String
        public var state: String?

        public init(value: String, state: String? = nil) {
            self.value = value
            self.state = state
        }
    }
}

// MARK: - Reading

extension StringCatalog {
    public init(jsonString: String) throws {
        guard let data = jsonString.data(using: .utf8) else {
            throw AppError.apiDownloadTermsError
        }
        try self.init(data: data)
    }

    public init(contentsOfFile path: String) throws {
        guard let data = FileManager.default.contents(atPath: path) else {
            throw AppError.fileNotFound(file: path)
        }
        try self.init(data: data)
    }

    public init(data: Data) throws {
        guard
            let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
            let strings = json["strings"] as? [String: Any]
        else {
            throw AppError.apiDownloadTermsError
        }

        sourceLanguage = json["sourceLanguage"] as? String ?? "en"
        version = json["version"] as? String ?? "1.0"
        self.strings = strings.reduce(into: [:]) { result, element in
            result[element.key] = Entry(json: element.value)
        }
    }
}

extension StringCatalog.Entry {
    fileprivate init(json: Any) {
        let dict = json as? [String: Any] ?? [:]
        comment = dict["comment"] as? String
        extractionState = dict["extractionState"] as? String
        let localizations = dict["localizations"] as? [String: Any] ?? [:]
        self.localizations = localizations.reduce(into: [:]) { result, element in
            guard
                let stringUnit = (element.value as? [String: Any])?["stringUnit"] as? [String: Any],
                let value = stringUnit["value"] as? String
            else {
                return
            }
            result[element.key] = StringCatalog.Localization(value: value, state: stringUnit["state"] as? String)
        }
    }
}

// MARK: - Writing

extension StringCatalog {
    /// Deterministic, Xcode-compatible serialization.
    ///
    /// Uses `JSONSerialization` with `.prettyPrinted` and `.sortedKeys`, which
    /// matches the on-disk format Xcode/String Catalog editor produces
    /// (`"key" : value`, 2-space indent, recursively sorted keys) and gives
    /// stable git diffs for free. No trailing newline, mirroring Xcode.
    public func serialized() throws -> String {
        let object = jsonObject()
        let data = try JSONSerialization.data(
            withJSONObject: object,
            options: [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        )
        guard let string = String(data: data, encoding: .utf8) else {
            throw AppError.apiDownloadTermsError
        }
        return string
    }

    public func write(toFile path: String) throws {
        try serialized().write(toFile: path, atomically: true, encoding: .utf8)
    }

    private func jsonObject() -> [String: Any] {
        var strings: [String: Any] = [:]
        for (key, entry) in self.strings {
            strings[key] = entry.jsonObject()
        }
        return [
            "sourceLanguage": sourceLanguage,
            "version": version,
            "strings": strings
        ]
    }
}

extension StringCatalog.Entry {
    fileprivate func jsonObject() -> [String: Any] {
        var localizations: [String: Any] = [:]
        for (language, localization) in self.localizations {
            var stringUnit: [String: Any] = ["value": localization.value]
            if let state = localization.state {
                stringUnit["state"] = state
            }
            localizations[language] = ["stringUnit": stringUnit]
        }

        var entry: [String: Any] = ["localizations": localizations]
        if let comment {
            entry["comment"] = comment
        }
        // Our keys are generated and live outside the project, so Xcode never
        // finds them in source and warns unless they're marked manual. Default
        // to "manual" so every write path (distribute/filter/remove) fixes keys
        // that predate this behaviour, without needing a full re-download.
        entry["extractionState"] = extractionState ?? "manual"
        return entry
    }
}
