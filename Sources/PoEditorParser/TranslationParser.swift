import Foundation

protocol TranslationParser {
    func parse() throws -> [Translation]
}
