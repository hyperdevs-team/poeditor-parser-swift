import Foundation

/// Compiles POEditor-style key patterns into anchored regexes.
///
/// `*` -> any run of characters, `?` -> a single character.
/// Everything else is matched literally and the whole key must match.
public struct KeyMatcher {
    private let regexes: [NSRegularExpression]

    public init(patterns: [String]) {
        regexes = patterns
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
            .compactMap { pattern in
                let escaped = NSRegularExpression.escapedPattern(for: pattern)
                    .replacingOccurrences(of: "\\*", with: ".*")
                    .replacingOccurrences(of: "\\?", with: ".")

                return try? NSRegularExpression(pattern: "\\A\(escaped)\\z")
            }
    }

    public var isEmpty: Bool { regexes.isEmpty }

    public func matches(_ key: String) -> Bool {
        let range = NSRange(key.startIndex..., in: key)
        return regexes.contains { $0.firstMatch(in: key, range: range) != nil }
    }
}

extension StringCatalog {
    /// Splits a multi-value catalog into a single-value one.
    ///
    /// Keys may carry a suffix `key[suffix1|suffix2]`. suffix-specific keys
    /// win over the plain (common) key of the same base name:
    ///   `key[suffix]` matching the suffix -> base `key`, priority 1 (wins)
    ///   `key`                             -> common, priority 2 (only if no
    ///                                       suffix-specific version exists)
    /// Keys targeting other suffixes are dropped.
    public func distributed(toSuffix suffix: String) -> StringCatalog {
        let suffix = suffix.lowercased()
        var result: [String: Entry] = [:]
        var isSpecific: Set<String> = []

        for (key, entry) in strings {
            guard let (baseKey, suffixes) = Self.parseSuffix(key) else {
                // Common key: keep only if no suffix-specific version claimed it.
                if !isSpecific.contains(key) {
                    result[key] = entry
                }
                continue
            }

            guard suffixes.contains(suffix) else { continue }
            result[baseKey] = entry
            isSpecific.insert(baseKey)
        }

        return StringCatalog(sourceLanguage: sourceLanguage, version: version, strings: result)
    }

    /// Merges a working catalog onto a baseline, keeping only the changes
    /// (add/modify/delete) of keys that match `matcher`. Every other key is
    /// taken from the baseline. This is the git-diff filter made git-agnostic:
    /// `self` is the baseline (e.g. HEAD), `working` is the current tree.
    public func filtered(applying working: StringCatalog, keys matcher: KeyMatcher) -> StringCatalog {
        var result = strings
        for key in Set(strings.keys).union(working.strings.keys) where matcher.matches(key) {
            if let entry = working.strings[key] {
                result[key] = entry
            } else {
                result[key] = nil
            }
        }
        return StringCatalog(
            sourceLanguage: working.sourceLanguage,
            version: working.version,
            strings: result
        )
    }

    /// Removes every key matching `matcher`.
    public func removing(keys matcher: KeyMatcher) -> StringCatalog {
        let kept = strings.filter { !matcher.matches($0.key) }
        return StringCatalog(sourceLanguage: sourceLanguage, version: version, strings: kept)
    }

    /// `("key[a|b]")` -> `("key", ["a", "b"])`; `nil` when there is no suffix.
    static func parseSuffix(_ key: String) -> (baseKey: String, suffixes: Set<String>)? {
        guard key.hasSuffix("]"), let open = key.lastIndex(of: "[") else { return nil }
        let baseKey = String(key[key.startIndex..<open])
        guard !baseKey.isEmpty else { return nil }
        let inside = key[key.index(after: open)..<key.index(before: key.endIndex)]
        let suffixes = inside.split(separator: "|").map { $0.trimmingCharacters(in: .whitespaces).lowercased() }

        return (baseKey, Set(suffixes))
    }
}
