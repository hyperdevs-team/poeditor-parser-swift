import Foundation
@testable import PoEditorParser
import Testing

private func catalog(_ keys: [String: String]) -> StringCatalog {
    StringCatalog(
        sourceLanguage: "es",
        version: "1.0",
        strings: keys.mapValues { StringCatalog.Entry(localizations: ["es": .init(value: $0)]) }
    )
}

private func values(_ c: StringCatalog) -> [String: String] {
    c.strings.compactMapValues { $0.localizations["es"]?.value }
}

// MARK: - KeyMatcher

@Test
func matcherWildcards() {
    #expect(KeyMatcher(patterns: ["about*"]).matches("about_us"))
    #expect(!KeyMatcher(patterns: ["about*"]).matches("profile"))
    #expect(KeyMatcher(patterns: ["*profile*"]).matches("edit_profile_title"))
    #expect(KeyMatcher(patterns: ["user?info"]).matches("user_info"))
    #expect(!KeyMatcher(patterns: ["user?info"]).matches("user__info"))
    // Anchored: partial literal doesn't match the whole key.
    #expect(!KeyMatcher(patterns: ["about"]).matches("about_us"))
    #expect(KeyMatcher(patterns: ["a", "b"]).matches("b"))
    #expect(KeyMatcher(patterns: []).isEmpty)
}

// MARK: - distribute

@Test
func distributeVariantSpecificWinsOverCommon() {
    let source = catalog([
        "title": "común",
        "title[yoigo]": "yoigo",
        "title[masmovil]": "masmovil",
        "only_common": "común",
        "other[jazztel]": "jazztel"
    ])
    let yoigo = values(source.distributed(toSuffix: "yoigo"))
    #expect(yoigo["title"] == "yoigo")          // variant-specific wins
    #expect(yoigo["only_common"] == "común")    // common kept
    #expect(yoigo["other"] == nil)              // other variant dropped
    #expect(yoigo.count == 2)
}

@Test
func distributeCommonKeptWhenNoVariantSpecific() {
    let source = catalog(["title": "común", "title[masmovil]": "mm"])
    let yoigo = values(source.distributed(toSuffix: "yoigo"))
    #expect(yoigo["title"] == "común")
    #expect(yoigo.count == 1)
}

@Test
func distributeMultiVariantSuffix() {
    let source = catalog(["greeting[yoigo|guuk]": "hola"])
    #expect(values(source.distributed(toSuffix: "guuk"))["greeting"] == "hola")
    #expect(values(source.distributed(toSuffix: "lebara")).isEmpty)
}

// MARK: - filter

@Test
func filterOnlyMatchingKeysTakeWorkingChanges() {
    let baseline = catalog(["about_title": "old", "profile_title": "old", "keep": "base"])
    let working = catalog(["about_title": "new", "profile_title": "new", "keep": "changed_but_ignored"])
    let result = values(baseline.filtered(applying: working, keys: KeyMatcher(patterns: ["about*"])))
    #expect(result["about_title"] == "new")     // matched → working
    #expect(result["profile_title"] == "old")   // unmatched → baseline
    #expect(result["keep"] == "base")           // unmatched → baseline
}

@Test
func filterAppliesAddsAndDeletesForMatchingKeys() {
    let baseline = catalog(["gone": "x", "stay": "base"])
    let working = catalog(["added": "y", "stay": "base"])
    let result = values(baseline.filtered(applying: working, keys: KeyMatcher(patterns: ["gone", "added"])))
    #expect(result["gone"] == nil)      // deleted in working, matched → removed
    #expect(result["added"] == "y")     // added in working, matched → added
    #expect(result["stay"] == "base")   // unmatched → baseline
}

// MARK: - remove

@Test
func removeMatchingKeys() {
    let source = catalog(["about_a": "1", "about_b": "2", "profile": "3"])
    let result = values(source.removing(keys: KeyMatcher(patterns: ["about*"])))
    #expect(result == ["profile": "3"])
}
