import Foundation
import Commander

let main = command(
    Option<String>("stringfile", default: "Localizable.strings", description: "The input POEditor strings file directory."),
    Option<String>("swiftfile", default: "Literals.swift", description: "The output Swift file directory.")
) { (stringfile: String, swiftfile: String) in
    let translationString = try! String(contentsOfFile: stringfile)
    let parser = StringTranslationParser(translation: translationString)
    let translations = parser.parse()
    FileManager.default.createFile(atPath: swiftfile, contents: nil, attributes: nil)
    let handle = FileHandle(forWritingAtPath: swiftfile)!
    let fileCodeGenerator = FileCodeGenerator(fileHandle: handle)
    fileCodeGenerator.generateCode(translations: translations)
}.run()