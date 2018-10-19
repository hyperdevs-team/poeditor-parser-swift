import Foundation
import Commander
import Rainbow

let main = command(
    Option<String>("stringfile", default: "Localizable.strings", description: "The input POEditor strings file directory."),
    Option<String>("swiftfile", default: "Literals.swift", description: "The output Swift file directory.")
) { (stringfile: String, swiftfile: String) in
    print("Reading contents of \(stringfile)...".blue)
    let translationString = try! String(contentsOfFile: stringfile)
    print("Parsing strings file...".blue)
    let parser = StringTranslationParser(translation: translationString)
    let translations = parser.parse()
    FileManager.default.createFile(atPath: swiftfile, contents: nil, attributes: nil)
    guard let handle = FileHandle(forWritingAtPath: swiftfile) else {
        print("Fatal error: Couldn't write to file located at \(swiftfile)".red)
        return
    }
    let fileCodeGenerator = FileCodeGenerator(fileHandle: handle)
    fileCodeGenerator.generateCode(translations: translations)
    print("Success! Literals generated at \(swiftfile)".green)
}.run()
