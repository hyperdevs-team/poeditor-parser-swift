import Foundation
@testable import PoEditorParser
import Testing

private let sampleCatalog = """
{
  "sourceLanguage" : "en",
  "strings" : {
    "welcome_message" : {
      "localizations" : {
        "es" : { "stringUnit" : { "state" : "translated", "value" : "Hola {{name}}!" } },
        "en" : { "stringUnit" : { "state" : "translated", "value" : "Hello {{name}}!" } }
      }
    },
    "plain_key" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "Just text" } }
      }
    },
    "no_translations" : {}
  },
  "version" : "1.0"
}
"""

@Test
func testXCStringsParsesKeysAndPrefersLanguage() throws {
    let parser = XCStringsTranslationParser(
        typeName: "Literals",
        translation: sampleCatalog,
        keysFormat: .upperCamelCase,
        preferredLanguage: "es"
    )

    let translations = try parser.parse().sorted()

    #expect(translations.map { $0.key } == ["no_translations", "plain_key", "welcome_message"])
    let welcome = try #require(translations.first { $0.key == "welcome_message" })
    #expect(welcome.value == "Hola {{name}}!")
    #expect(welcome.hasVariables)
}

@Test
func testXCStringsFallsBackToSourceLanguage() throws {
    let parser = XCStringsTranslationParser(
        typeName: "Literals",
        translation: sampleCatalog,
        keysFormat: .upperCamelCase,
        preferredLanguage: "fr" // not present -> falls back to sourceLanguage "en"
    )

    let translations = try parser.parse()
    let welcome = try #require(translations.first { $0.key == "welcome_message" })
    #expect(welcome.value == "Hello {{name}}!")
}

@Test
func testXCStringsNormalizesPlaceholderVariables() throws {
    let catalog = """
    { "value" : "Hola {1{name}}, tienes {2{item_count}} y {{plain}}" }
    """
    let normalized = XCStringsTranslationParser.normalizingPlaceholders(in: catalog)
    #expect(normalized == "{ \"value\" : \"Hola {{name}}, tienes {{item_count}} y {{plain}}\" }")
}

@Test
func testXCStringsInvalidJSONThrows() throws {
    let parser = XCStringsTranslationParser(
        typeName: "Literals",
        translation: "not json",
        keysFormat: .upperCamelCase,
        preferredLanguage: nil
    )

    #expect(throws: AppError.self) {
        _ = try parser.parse()
    }
}
