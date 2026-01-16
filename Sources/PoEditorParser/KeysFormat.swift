import Commander
import Foundation

public enum KeysFormat: String, ArgumentConvertible {
    case lowerCamelCase
    case upperCamelCase

    public init(parser: Commander.ArgumentParser) throws {
        guard let value = parser.shift() else {
            throw ArgumentError.missingValue(argument: nil)
        }

        guard let keysFormat = KeysFormat(rawValue: value) else {
            throw ArgumentError.invalidType(value: value, type: "key format", argument: nil)
        }

        self = keysFormat
    }

    public var description: String {
        switch self {
        case .lowerCamelCase:
            return "LowerCamelCase"

        case .upperCamelCase:
            return "UpperCamelCase"
        }
    }
}
