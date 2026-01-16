import Foundation

public struct Translation: Comparable {
    public let typeName: String
    public let key: String
    public let value: String
    private let rawValue: String
    private let keysFormat: KeysFormat
    private let variables: [Variable]

    public init(typeName: String, key: String, rawValue: String, keysFormat: KeysFormat) throws {
        self.typeName = typeName
        self.key = key
        self.rawValue = rawValue
        self.keysFormat = keysFormat

        // Parse translationValue
        (value, variables) = try TranslationValueParser.parseTranslationValue(term: key, translationValue: rawValue)
    }

    public var hasVariables: Bool {
        !variables.isEmpty
    }

    public var hasMoreThanOneVariable: Bool {
        variables.count > 1
    }

    public var swiftStaticFuncCode: String {
        if variables.isEmpty {
            return generateFuncWithoutVariables()
        } else {
            return generateFuncWithVariables()
        }
    }

    public var swiftEnumCaseCode: String {
        if variables.isEmpty {
            return "\tcase \(keySafeForCodeMethod)"
        }
        let parameters = variables
            .map { $0.type.swiftParameter(key: $0.parameterKey) }
            .joined(separator: ", ")

        return "\tcase \(keySafeForCodeMethod)(\(parameters))"
    }

    public var swiftEnumCaseForValue: String {
        if variables.isEmpty {
            return generateEnumCaseWithoutVariables()
        } else {
            return generateEnumCaseWithVariables()
        }
    }

    public var swiftEnumCaseForKey: String {
        "\t\tcase .\(keySafeForCodeMethod): return \"\(key)\""
    }

    private var keySafeForCodeMethod: String {
        switch keysFormat {
        case .upperCamelCase:
            return key.capitalized
                .replacingOccurrences(of: "_", with: "")
                .replacingOccurrences(of: "[", with: "")
                .replacingOccurrences(of: "]", with: "")
                .replacingOccurrences(of: "|", with: "")

        case .lowerCamelCase:
            return (key.prefix(1).lowercased() + key.capitalized.dropFirst())
                .replacingOccurrences(of: "_", with: "")
                .replacingOccurrences(of: "[", with: "")
                .replacingOccurrences(of: "]", with: "")
                .replacingOccurrences(of: "|", with: "")
        }
    }

    private func generateEnumCaseWithoutVariables() -> String {
        "\t\tcase .\(keySafeForCodeMethod): return value"
    }

    private func generateEnumCaseWithVariables() -> String {
        let parameters = variables
            .map { $0.type.swiftCaseParameter(key: $0.parameterKey) }
            .joined(separator: ", ")
        let localizedArguments = variables
            .map { variable in
                if variable.type != .textual {
                    let value = "String(format: \"\(variable.type.localizedRepresentation)\", \(variable.parameterKey.snakeCased()))"
                    return ".replacingOccurrences(of: \"{{\(variable.parameterKey)}}\", with: \(value))"
                }

                return ".replacingOccurrences(of: \"{{\(variable.parameterKey)}}\", with: \(variable.parameterKey.snakeCased()))"
            }
            .joined(separator: "\n\t\t\t")
        return "\t\tcase .\(keySafeForCodeMethod)(\(parameters)): return value\n\t\t\t\(localizedArguments)"
    }

    private func generateFuncWithoutVariables() -> String {
        /*
         static let key: StringsUIKey = StringsUIKey(key: "key_id")
         */
        """
        \(commentKey(maxLength: 700))
            static let \(keySafeForCodeMethod): \(typeName) = \(typeName)(key: \"\(key)\")
        """
    }

    private func generateFuncWithVariables() -> String {
        /*
         static func key(parameter1: String) -> StringsUIKey {
         .init(key: "key", parameters: ["parameter1": parameter1])
         }
         */
        let parameters = variables
            .map { $0.type.swiftParameter(key: $0.parameterKey) }
            .joined(separator: ", ")

        let localizedArguments = variables
            .map { variable in
                (
                    key: "\"\(variable.parameterKey)\"",
                    value: variable.toParameterValue()
                )
            }

        var localizedArgumentsString: String {
            var result: [String] = []
            for (key, value) in localizedArguments {
                result.append("\(key): \(value)")
            }
            return "[\(result.joined(separator: ", "))]"
        }

        return """
        \(commentKey(maxLength: 700))
            static func \(keySafeForCodeMethod)(\(parameters)) -> \(typeName) {
                .init(key: \"\(key)\", parameters: \(localizedArgumentsString))
            }
        """
    }

    public static func < (lhs: Translation, rhs: Translation) -> Bool {
        lhs.keySafeForCodeMethod < rhs.keySafeForCodeMethod
    }

    public static func == (lhs: Translation, rhs: Translation) -> Bool {
        lhs.keySafeForCodeMethod == rhs.keySafeForCodeMethod
    }

    private func commentKey(maxLength: Int) -> String {
        let truncatedValue: String = {
            if value.count <= maxLength {
                return value
            }
            let truncated = String(value.prefix(maxLength - 3))
            return "\(truncated)..."
        }()

        if variables.isEmpty {
            return """
                /// Returns Literal instance for `\(key)` key.
                /// - Example: \(truncatedValue)
            """
        } else {
            let parameters = variables
                .map { "    ///     - \($0.parameterKey): Replace *{{\($0.parameterKey)}}* with the given value in \($0.type.swiftType)" }
                .joined(separator: "\n")
            return """
                /// Returns Literal instance for `\(key)` key.
                /// - Parameters:
            \(parameters)
                /// - Example: \(truncatedValue)
            """
        }
    }
}

private extension Variable {
    func toParameterValue() -> String {
        switch type {
        case .textual:
            return parameterKey.snakeCased()

        case .numeric:
            let value = "String(format: \"\(type.localizedRepresentation)\", \(parameterKey.snakeCased()))"
            return value
        }
    }
}
