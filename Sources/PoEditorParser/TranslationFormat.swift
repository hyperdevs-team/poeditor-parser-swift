import Commander
import Foundation

public enum TranslationFormat: String, ArgumentConvertible {
    case strings
    case xcstrings

    public var apiType: String {
        switch self {
        case .strings:
            return "apple_strings"

        case .xcstrings:
            return "xcstrings"
        }
    }

    public init(parser: Commander.ArgumentParser) throws {
        guard let value = parser.shift() else {
            throw ArgumentError.missingValue(argument: nil)
        }

        guard let format = TranslationFormat(rawValue: value) else {
            throw ArgumentError.invalidType(value: value, type: "translation format", argument: nil)
        }

        self = format
    }

    public var description: String {
        rawValue
    }
}
