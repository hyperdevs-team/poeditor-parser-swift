import Foundation

/// Parses an Apple String Catalog (`.xcstrings`) file into `[Translation]`.
///
/// The `.swift` output only needs the key and one value per term (placeholders
/// like `{{var}}` are identical across languages), so we take the value from the
/// preferred language, falling back to the source language, then any available.
public class XCStringsTranslationParser: TranslationParser {
    let typeName: String
    let translation: String
    let keysFormat: KeysFormat
    let preferredLanguage: String?

    public init(typeName: String, translation: String, keysFormat: KeysFormat, preferredLanguage: String?) {
        self.typeName = typeName
        self.translation = translation
        self.keysFormat = keysFormat
        self.preferredLanguage = preferredLanguage
    }

    public func parse() throws -> [Translation] {
        guard
            let data = translation.data(using: .utf8),
            let json = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any],
            let strings = json["strings"] as? [String: Any]
        else {
            throw AppError.apiDownloadTermsError
        }

        let sourceLanguage = json["sourceLanguage"] as? String

        return try strings.compactMap { key, entry -> Translation? in
            guard
                let entry = entry as? [String: Any],
                let localizations = entry["localizations"] as? [String: Any]
            else {
                // Key with no translations yet: emit an empty value so it still
                // appears in the generated Swift literals.
                return try Translation(typeName: typeName, key: key, rawValue: "", keysFormat: keysFormat)
            }

            let value = value(from: localizations, sourceLanguage: sourceLanguage) ?? ""
            return try Translation(typeName: typeName, key: key, rawValue: value, keysFormat: keysFormat)
        }
    }

    /// Converts placeholder-marked variables like `{1{variable}}` (used by other
    /// platforms that share this POEditor project) into the plain `{{variable}}`
    /// format iOS expects, mirroring what `TranslationValueParser` does for the
    /// `.strings` output. Runs over the whole catalog so every language is
    /// normalized in a single pass, without re-serializing the JSON.
    public static func normalizingPlaceholders(in catalog: String) -> String {
        // {optional-order-number{ name }}
        let pattern = "\\{[0-9]*\\{([^{}]+)\\}\\}"
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return catalog }
        let ns = catalog as NSString
        let matches = regex.matches(in: catalog, range: NSRange(location: 0, length: ns.length))
        guard !matches.isEmpty else { return catalog }

        // Single forward pass: append the text between matches plus the rewritten
        // variable. O(n) overall, versus the quadratic cost of per-match index
        // conversions + replaceSubrange (which is what made --exportall slow).
        var result = ""
        result.reserveCapacity(ns.length)
        var cursor = 0
        for match in matches {
            result += ns.substring(with: NSRange(location: cursor, length: match.range.location - cursor))
            let parameterKey = Variable(rawKey: ns.substring(with: match.range(at: 1))).parameterKey
            result += "{{\(parameterKey)}}"
            cursor = match.range.location + match.range.length
        }
        result += ns.substring(from: cursor)
        return result
    }

    private func value(from localizations: [String: Any], sourceLanguage: String?) -> String? {
        let ordered = [preferredLanguage, sourceLanguage].compactMap { $0 } + Array(localizations.keys)
        for language in ordered {
            if let stringUnit = (localizations[language] as? [String: Any])?["stringUnit"] as? [String: Any],
               let value = stringUnit["value"] as? String {
                return value
            }
        }
        return nil
    }
}
