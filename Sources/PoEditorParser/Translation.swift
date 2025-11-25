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
            return "\tcase \(prettyKey)"
        }
        let parameters = variables
            .map { $0.type.swiftParameter(key: $0.parameterKey) }
            .joined(separator: ", ")

        return "\tcase \(prettyKey)(\(parameters))"
    }

    public var swiftEnumCaseForValue: String {
        if variables.isEmpty {
            return generateEnumCaseWithoutVariables()
        } else {
            return generateEnumCaseWithVariables()
        }
    }

    public var swiftEnumCaseForKey: String {
        "\t\tcase .\(prettyKey): return \"\(key)\""
    }

    private var prettyKey: String {
        switch keysFormat {
        case .upperCamelCase:
            return key.capitalized.replacingOccurrences(of: "_", with: "")

        case .lowerCamelCase:
            return (key.prefix(1).lowercased() + key.capitalized.dropFirst())
                .replacingOccurrences(of: "_", with: "")
        }
    }

    private func generateEnumCaseWithoutVariables() -> String {
        "\t\tcase .\(prettyKey): return value"
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
        return "\t\tcase .\(prettyKey)(\(parameters)): return value\n\t\t\t\(localizedArguments)"
    }

    private func generateFuncWithoutVariables() -> String {
        /*
         static let key: StringsUIKey = StringsUIKey(key: "key_id")
         */
        "\tstatic let \(prettyKey): \(typeName) = \(typeName)(key: \"\(key)\")"
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
                    value: variable.toParamterValue()
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
            static func \(prettyKey)(\(parameters)) -> \(typeName) {
                .init(key: \"\(key)\", parameters: \(localizedArgumentsString))
            }
        """
    }

    public static func < (lhs: Translation, rhs: Translation) -> Bool {
        lhs.prettyKey < rhs.prettyKey
    }

    public static func == (lhs: Translation, rhs: Translation) -> Bool {
        lhs.prettyKey == rhs.prettyKey
    }
}

private extension Variable {
    func toParamterValue() -> String {
        switch type {
        case .textual:
            return parameterKey.snakeCased()
        case .numeric:
            let value = "String(format: \"\(type.localizedRepresentation)\", \(parameterKey.snakeCased()))"
            return value
        }
    }
}
