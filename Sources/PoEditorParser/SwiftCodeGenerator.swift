import Foundation

public protocol SwiftCodeGenerator {
    func generateCode(translations: [Translation])
}

class StructCodeGenerator: SwiftCodeGenerator {
    let writer: any CodeWriter
    let typeName: String
    let tableName: String?
    let outputFormat: OutputFormat

    init(
        writer: any CodeWriter,
        typeName: String,
        tableName: String?,
        outputFormat: OutputFormat
    ) {
        self.writer = writer
        self.typeName = typeName
        self.tableName = tableName
        self.outputFormat = outputFormat
    }

    func generateCode(translations: [Translation]) {
        // File Header
        writer.append(POEConstants.fileHeader)
        writer.append(POEConstants.methodOrVariableSeparator)

        // File contents
        writer.append(
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

        writer.append(POEConstants.methodOrVariableSeparator)
        writer.append(POEConstants.methodOrVariableSeparator)
        writer.append("public extension \(typeName) {")
        writer.append(POEConstants.methodOrVariableSeparator)

        for (index, translation) in translations.enumerated() {
            writer.append(translation.swiftStaticFuncCode)
            if index < translations.count - 1 {
                writer.append(POEConstants.methodOrVariableSeparator)
            }
        }

        writer.append(POEConstants.methodOrVariableSeparator)
        writer.append("}") // Close extension

        // File close
        writer.append(POEConstants.fileFooter)
    }
}

class EnumCodeGenerator: SwiftCodeGenerator {
    let writer: any CodeWriter
    let typeName: String
    let tableName: String?
    let outputFormat: OutputFormat

    init(
        writer: any CodeWriter,
        typeName: String,
        tableName: String?,
        outputFormat: OutputFormat
    ) {
        self.writer = writer
        self.typeName = typeName
        self.tableName = tableName
        self.outputFormat = outputFormat
    }

    func generateCode(translations: [Translation]) {
        // File Header
        writer.append(POEConstants.fileHeader)

        // File contents
        writer.append(POEConstants.literalsEnumHeader(keysName: typeName))
        for (index, translation) in translations.enumerated() {
            writer.append(translation.swiftEnumCaseCode)
            if index < translations.count - 1 {
                writer.append(POEConstants.methodOrVariableSeparator)
            }
        }
        writer.append(POEConstants.methodOrVariableSeparator)
        writer.append(POEConstants.methodOrVariableSeparator)

        writer.append(POEConstants.literalsEnumValueFuncStart)
        for translation in translations {
            writer.append(translation.swiftEnumCaseForValue)
            writer.append(POEConstants.methodOrVariableSeparator)
        }
        if translations.count > 1_000 {
            writer.append(POEConstants.literalsEnumDefaultCase)
        }
        writer.append(POEConstants.literalsEnumValueFuncEnd)

        writer.append(POEConstants.methodOrVariableSeparator)

        writer.append(POEConstants.literalsEnumStringKeyStart)
        for translation in translations {
            writer.append(translation.swiftEnumCaseForKey)
            writer.append(POEConstants.methodOrVariableSeparator)
        }
        if translations.count > 1_000 {
            writer.append(POEConstants.literalsEnumDefaultCase)
        }
        writer.append(POEConstants.literalsEnumStringKeyEnd)

        writer.append(POEConstants.literalsEnumFooter)

        // File close
        writer.append(POEConstants.fileFooter)
    }
}

public class StringCodeGenerator: SwiftCodeGenerator {
    let writer: any CodeWriter
    let typeName: String
    let tableName: String?
    let outputFormat: OutputFormat

    var codeGenerator: any SwiftCodeGenerator {
        switch outputFormat {
        case .struct:
            return StructCodeGenerator(
                writer: writer,
                typeName: typeName,
                tableName: tableName,
                outputFormat: outputFormat
            )

        case .enum:
            return EnumCodeGenerator(
                writer: writer,
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
        writer = StringCodeWriter()
        self.typeName = typeName
        self.tableName = tableName
        self.outputFormat = outputFormat
    }

    public func generateCode(translations: [Translation]) {
        codeGenerator.generateCode(translations: translations)
    }
}

public class FileCodeGenerator: SwiftCodeGenerator {
    let writer: any CodeWriter
    let typeName: String
    let tableName: String?
    let outputFormat: OutputFormat

    var codeGenerator: any SwiftCodeGenerator {
        switch outputFormat {
        case .struct:
            return StructCodeGenerator(
                writer: writer,
                typeName: typeName,
                tableName: tableName,
                outputFormat: outputFormat
            )

        case .enum:
            return EnumCodeGenerator(
                writer: writer,
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
        writer = FileCodeWriter(handle: fileHandle)
        self.typeName = typeName
        self.tableName = tableName
        self.outputFormat = outputFormat
    }

    public func generateCode(translations: [Translation]) {
        codeGenerator.generateCode(translations: translations)
    }
}
