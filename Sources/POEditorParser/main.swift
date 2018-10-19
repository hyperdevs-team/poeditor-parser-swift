import Foundation
import Commander
import Rainbow

let main = command(
    Argument<String>("strings", description: "The input POEditor strings file directory."),
    Option<String>("swiftfile", default: "${SRCROOT}/${TARGET_NAME}/Literals.swift", description: "The output Swift file directory."),
    Option<String>("stringsfile", default: "${SRCROOT}/${TARGET_NAME}/Localizable.strings", description: "The output Strings file directory.")
) { (strings: String, swiftfile: String, stringsfile: String) in
    print("Reading contents of \(strings)...".blue)
    let translationString = try! String(contentsOfFile: strings)
    print("Parsing strings file...".blue)
    let parser = StringTranslationParser(translation: translationString)
    let translations = parser.parse()

    FileManager.default.createFile(atPath: swiftfile, contents: nil, attributes: nil)
    guard let swiftHandle = FileHandle(forWritingAtPath: swiftfile) else {
        print("Fatal error: Couldn't write to file located at \(swiftfile)".red)
        return
    }
    let fileCodeGenerator = FileCodeGenerator(fileHandle: swiftHandle)
    fileCodeGenerator.generateCode(translations: translations)
    print("Success! Literals generated at \(swiftfile)".green)

    FileManager.default.createFile(atPath: stringsfile, contents: nil, attributes: nil)
    guard let stringsHandle = FileHandle(forWritingAtPath: stringsfile) else {
        print("Fatal error: Couldn't write to file located at \(stringsfile)".red)
        return
    }
    let stringsFileGenerator = StringsFileGenerator(fileHandle: stringsHandle)
    stringsFileGenerator.generateCode(translations: translations)
    print("Success! Strings generated at \(stringsfile)".green)

}.run()
