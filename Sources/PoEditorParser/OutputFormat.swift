import Commander
import Foundation

public enum OutputFormat: String, ArgumentConvertible {
    case `enum`
    case `struct`

    public init(parser: Commander.ArgumentParser) throws {
        guard let value = parser.shift() else {
            throw ArgumentError.missingValue(argument: nil)
        }

        guard let keysFormat = OutputFormat(rawValue: value) else {
            throw ArgumentError.invalidType(value: value, type: "output format", argument: nil)
        }

        self = keysFormat
    }

    public var description: String {
        switch self {
        case .enum:
            return "Enum"

        case .struct:
            return "Struct"
        }
    }
}
