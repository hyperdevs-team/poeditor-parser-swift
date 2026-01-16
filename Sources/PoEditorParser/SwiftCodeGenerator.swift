import Foundation

public protocol SwiftCodeGenerator {
    func generateCode(translations: [Translation])
}

class StructCodeGenerator: SwiftCodeGenerator {
    let keeper: any CodeKeeper
    let typeName: String
    let tableName: String?
    let outputFormat: OutputFormat

    init(
        keeper: any CodeKeeper,
        typeName: String,
        tableName: String?,
        outputFormat: OutputFormat
    ) {
        self.keeper = keeper
        self.typeName = typeName
        self.tableName = tableName
        self.outputFormat = outputFormat
    }

    func generateCode(translations: [Translation]) {
        // File Header
        keeper.append(POEConstants.fileHeader)
        keeper.append(POEConstants.methodOrVariableSeparator)

        // File contents
        keeper.append(
            """
        public struct \(typeName): Hashable, Equatable {
            public let key: String
            public let parameters: [String: String]

            public init(
                key: String,
                parameters: [String: String] = [:]
            ) {
                self.key = key
                self.parameters = parameters
            }

            public func hash(into hasher: inout Hasher) {
                hasher.combine(key)
                hasher.combine(parameters)
            }

            public func parsed(value: String) -> String {
                var result = value
                for (placeholder, replacement) in parameters {
                    result = result.replacingOccurrences(of: \"{{\\(placeholder)}}\", with: replacement)
                }
                return result
            }
        }
        """
        )

        keeper.append(POEConstants.methodOrVariableSeparator)
        keeper.append(POEConstants.methodOrVariableSeparator)
        keeper.append("public extension \(typeName) {")
        keeper.append(POEConstants.methodOrVariableSeparator)

        for (index, translation) in translations.enumerated() {
            keeper.append(translation.swiftStaticFuncCode)
            if index < translations.count - 1 {
                keeper.append(POEConstants.methodOrVariableSeparator)
            }
        }

        keeper.append(POEConstants.methodOrVariableSeparator)
        keeper.append("}") // Close extension

        // File close
        keeper.append(POEConstants.fileFooter)
    }
}

class EnumCodeGenerator: SwiftCodeGenerator {
    let keeper: any CodeKeeper
    let typeName: String
    let tableName: String?
    let outputFormat: OutputFormat

    init(
        keeper: any CodeKeeper,
        typeName: String,
        tableName: String?,
        outputFormat: OutputFormat
    ) {
        self.keeper = keeper
        self.typeName = typeName
        self.tableName = tableName
        self.outputFormat = outputFormat
    }

    func generateCode(translations: [Translation]) {
        // File Header
        keeper.append(POEConstants.fileHeader)

        // File contents
        keeper.append(POEConstants.literalsEnumHeader(keysName: typeName))
        for (index, translation) in translations.enumerated() {
            keeper.append(translation.swiftEnumCaseCode)
            if index < translations.count - 1 {
                keeper.append(POEConstants.methodOrVariableSeparator)
            }
        }
        keeper.append(POEConstants.methodOrVariableSeparator)
        keeper.append(POEConstants.methodOrVariableSeparator)

        keeper.append(POEConstants.literalsEnumValueFuncStart)
        for translation in translations {
            keeper.append(translation.swiftEnumCaseForValue)
            keeper.append(POEConstants.methodOrVariableSeparator)
        }
        if translations.count > 1_000 {
            keeper.append(POEConstants.literalsEnumDefaultCase)
        }
        keeper.append(POEConstants.literalsEnumValueFuncEnd)

        keeper.append(POEConstants.methodOrVariableSeparator)

        keeper.append(POEConstants.literalsEnumStringKeyStart)
        for translation in translations {
            keeper.append(translation.swiftEnumCaseForKey)
            keeper.append(POEConstants.methodOrVariableSeparator)
        }
        if translations.count > 1_000 {
            keeper.append(POEConstants.literalsEnumDefaultCase)
        }
        keeper.append(POEConstants.literalsEnumStringKeyEnd)

        keeper.append(POEConstants.literalsEnumFooter)

        // Filoe close
        keeper.append(POEConstants.fileFooter)
    }
}

public class StringCodeGenerator: SwiftCodeGenerator {
    let keeper: any CodeKeeper
    let typeName: String
    let tableName: String?
    let outputFormat: OutputFormat

    var codeGenerator: any SwiftCodeGenerator {
        switch outputFormat {
        case .struct:
            return StructCodeGenerator(
                keeper: keeper,
                typeName: typeName,
                tableName: tableName,
                outputFormat: outputFormat
            )

        case .enum:
            return EnumCodeGenerator(
                keeper: keeper,
                typeName: typeName,
                tableName: tableName,
                outputFormat: outputFormat
            )
        }
    }

    public init(
        typeName: String,
        tableName: String?,
        outputFormat: OutputFormat
    ) {
        keeper = StringKeeper()
        self.typeName = typeName
        self.tableName = tableName
        self.outputFormat = outputFormat
    }

    public func generateCode(translations: [Translation]) {
        codeGenerator.generateCode(translations: translations)
    }
}

public class FileCodeGenerator: SwiftCodeGenerator {
    let keeper: any CodeKeeper
    let typeName: String
    let tableName: String?
    let outputFormat: OutputFormat

    var codeGenerator: any SwiftCodeGenerator {
        switch outputFormat {
        case .struct:
            return StructCodeGenerator(
                keeper: keeper,
                typeName: typeName,
                tableName: tableName,
                outputFormat: outputFormat
            )

        case .enum:
            return EnumCodeGenerator(
                keeper: keeper,
                typeName: typeName,
                tableName: tableName,
                outputFormat: outputFormat
            )
        }
    }

    public init(
        fileHandle: FileHandle,
        typeName: String,
        tableName: String?,
        outputFormat: OutputFormat
    ) {
        keeper = FileHandleKeeper(handle: fileHandle)
        self.typeName = typeName
        self.tableName = tableName
        self.outputFormat = outputFormat
    }

    public func generateCode(translations: [Translation]) {
        codeGenerator.generateCode(translations: translations)
    }
}
