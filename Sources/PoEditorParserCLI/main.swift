import Commander
import Foundation
import PoEditorParser
import Rainbow

let POEditorAPIURL = "https://api.poeditor.com/v2"

private func processingClosure(
    token: String?,
    id: Int?,
    language: String?,
    onlyGenerate: Bool,
    swiftFile: String,
    stringsFile: String,
    typeName: String,
    tableName: String?,
    outputFormat: OutputFormat,
    keysFormat: KeysFormat
) throws {
    let program = Program()
    try program.run(
        token: token,
        id: id,
        language: language,
        onlyGenerate: onlyGenerate,
        swiftFile: swiftFile,
        stringsFile: stringsFile,
        typeName: typeName,
        tableName: tableName,
        outputFormat: outputFormat,
        keysFormat: keysFormat,
        poEditorApiUrl: POEditorAPIURL
    )
}

command(
    Option<String?>("apitoken", default: nil, description: "The POEditor API token"),
    Option<Int?>("projectid", default: nil, description: "The id of the project in POEditor"),
    Option<String?>("projectlanguage", default: nil, description: "The language code in POEditor"),
    Option<Bool>("onlygenerate", default: false, description: ""),
    Option<String>("swiftfile", default: "Sources/Literals.swift", description: "The output Swift file directory."),
    Option<String>("stringsfile", default: "Sources/Localizable.strings", description: "The output Strings file directory."),
    Option<String>("typename", default: "Literals", description: "The type name that store all localized vars"),
    Option<String?>("tablename", default: nil, description: "The tableName value for NSLocalizedString"),
    Option<OutputFormat>("outputformat", default: .struct, description: "The output format for swift file (enum or struct)"),
    Option<KeysFormat>("keysformat", default: .upperCamelCase, description: "The format for the localized key"),
    processingClosure
).run()
