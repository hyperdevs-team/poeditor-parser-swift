import Foundation

protocol TranslationParser {
    func parse() throws -> [Translation]
}

public class StringTranslationParser: TranslationParser {
    let typeName: String
    let translation: String
    let keysFormat: KeysFormat

    public init(typeName: String, translation: String, keysFormat: KeysFormat) {
        self.typeName = typeName
        self.translation = translation
        self.keysFormat = keysFormat
    }

    public func parse() throws -> [Translation] {
        var translations = [Translation]()

        let str = Scanner(string: translation)
        let charSet = NSMutableCharacterSet.whitespaceAndNewline()
        charSet.formUnion(with: CharacterSet(charactersIn: ";"))
        str.charactersToBeSkipped = charSet as CharacterSet

        while true {
            let commentFound = str.scanString("/*", into: nil)
            if commentFound {
                // skip comment
                str.scanUpTo("*/", into: nil)
                str.scanLocation += 2
            }

            if str.isAtEnd {
                break
            }

            let translationFound = str.scanString("\"", into: nil)

            if translationFound {
                var key: NSString?
                str.scanUpTo("\"", into: &key)
                str.scanLocation += 1

                str.scanUpTo("\"", into: nil)
                str.scanLocation += 1

                var value: NSString?
                str.scanUpTo("\";", into: &value)
                str.scanLocation += 2
                var finalValue: NSString?
                if let value = value {
                    finalValue = value.substring(to: value.length) as NSString
                }

                translations.append(try Translation(typeName: typeName,
                                                    key: key! as String,
                                                    rawValue: finalValue as String? ?? "",
                                                    keysFormat: keysFormat))
            }
            if str.isAtEnd {
                break
            }
        }

        return translations
    }
}
