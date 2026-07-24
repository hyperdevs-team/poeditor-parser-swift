import Foundation
@testable import PoEditorParser
import Testing

// Exact on-disk format Xcode/String Catalog produces: `"key" : value`,
// 2-space indent, recursively sorted keys, no trailing newline.
private let sampleCatalog = """
{
  "sourceLanguage" : "es",
  "strings" : {
    "about_us_language_title_text" : {
      "extractionState" : "manual",
      "localizations" : {
        "en" : {
          "stringUnit" : {
            "state" : "translated",
            "value" : "Language"
          }
        },
        "es" : {
          "stringUnit" : {
            "state" : "translated",
            "value" : "Idioma"
          }
        }
      }
    },
    "with_comment" : {
      "comment" : "A greeting",
      "extractionState" : "manual",
      "localizations" : {
        "es" : {
          "stringUnit" : {
            "state" : "translated",
            "value" : "Hola"
          }
        }
      }
    }
  },
  "version" : "1.0"
}
"""

@Test
func serializationMatchesXcodeOnDiskFormat() throws {
    let catalog = try StringCatalog(jsonString: sampleCatalog)
    #expect(try catalog.serialized() == sampleCatalog)
}

@Test
func roundTripIsLossless() throws {
    let catalog = try StringCatalog(jsonString: sampleCatalog)
    #expect(catalog.sourceLanguage == "es")
    #expect(catalog.version == "1.0")
    #expect(catalog.strings["about_us_language_title_text"]?.extractionState == "manual")
    #expect(catalog.strings["about_us_language_title_text"]?.localizations["en"]?.value == "Language")
    #expect(catalog.strings["with_comment"]?.comment == "A greeting")
}

@Test
func serializationIsIdempotent() throws {
    let once = try StringCatalog(jsonString: sampleCatalog).serialized()
    let twice = try StringCatalog(jsonString: once).serialized()
    #expect(once == twice)
}
