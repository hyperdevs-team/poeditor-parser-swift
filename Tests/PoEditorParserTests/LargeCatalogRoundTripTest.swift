import Foundation
@testable import PoEditorParser
import Testing

/// Builds a large, realistic catalog in memory (many keys, several languages,
/// comments and extraction states) so the round-trip is exercised at scale
/// without depending on any external `.xcstrings` file.
private func makeLargeCatalog(keys: Int) -> StringCatalog {
    let languages = ["ca", "en", "es", "eu", "gl"]
    var strings: [String: StringCatalog.Entry] = [:]

    for index in 0..<keys {
        // Deliberately unsorted key names so serialization has to sort them.
        let key = "key_\(String(format: "%04d", (index * 7919) % keys))_text"
        let localizations = languages.reduce(into: [String: StringCatalog.Localization]()) { result, language in
            result[language] = .init(value: "value {{name}} for \(key) in \(language)", state: "translated")
        }
        strings[key] = .init(
            localizations: localizations,
            comment: index.isMultiple(of: 3) ? "comment for \(key)" : nil,
            extractionState: index.isMultiple(of: 5) ? "manual" : nil
        )
    }

    return StringCatalog(sourceLanguage: "es", version: "1.0", strings: strings)
}

@Test
func largeCatalogRoundTripIsByteIdentical() throws {
    let canonical = try makeLargeCatalog(keys: 500).serialized()
    // Re-parsing and re-serializing the canonical form must reproduce it exactly.
    let roundTripped = try StringCatalog(jsonString: canonical).serialized()
    #expect(canonical == roundTripped)
}

@Test
func largeCatalogSerializationIsFullySorted() throws {
    let serialized = try makeLargeCatalog(keys: 500).serialized()
    // Keys and nested objects are sorted, so the whole file must be stable and
    // its top-level "strings" keys must appear in ascending order.
    let keyLines = serialized
        .split(separator: "\n")
        .compactMap { line -> String? in
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            guard trimmed.hasPrefix("\"key_"), trimmed.hasSuffix("_text\" : {") else { return nil }
            return trimmed
        }

    #expect(keyLines == keyLines.sorted())
    #expect(keyLines.count == 500)
}
