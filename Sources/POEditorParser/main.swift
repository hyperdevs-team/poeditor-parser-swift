import Foundation
import Commander
import Rainbow
import PerfectCURL

let POEditorAPIURL = "https://api.poeditor.com/v2"

command(
    Argument<String>("APITOKEN", description: "The POEditor API token"),
    Argument<Int>("id", description: "The id of the project"),
    Argument<String>("language", description: "The language code"),
    Option<String>("swiftfile", default: "${SRCROOT}/${TARGET_NAME}/Literals.swift", description: "The output Swift file directory."),
    Option<String>("stringsfile", default: "${SRCROOT}/${TARGET_NAME}/Localizable.strings", description: "The output Strings file directory.")
) { (token: String, id: Int, language: String, swiftfile: String, stringsfile: String) in

    print("Fetching contents of strings at POEditor...".blue)
    
    do {
        let json = try CURLRequest("\(POEditorAPIURL)/projects/export", .failOnError,
                                   .postField(.init(name: "api_token", value: token)),
                                   .postField(.init(name: "id", value: "\(id)")),
                                   .postField(.init(name: "language", value: language)),
                                   .postField(.init(name: "type", value: "apple_strings")))
            .perform()
            .bodyJSON
            
        print("Querying POEditor for the latest strings file...".magenta)

        if let result = json["result"] as? [String: Any], let url = result["url"] as? String {
            print("Successfully got the latest URL for the strings file from POEditor".green)
            print("Downloading the latest strings file from POEditor...".magenta)
            let translationString = try CURLRequest(url, .failOnError)
                .perform()
                .bodyString
            
            print("Successfully downloaded the latest strings file from POEditor!".green)
            print("Checking for changes in the downloaded strings file...".blue)

            if FileManager.default.fileExists(atPath: stringsfile) {
                print("Found previous strings file at \(stringsfile)".blue)
                if let localStringsfile = FileHandle(forReadingAtPath: stringsfile) {
                    print("Reading contents of strings file at \(stringsfile)".blue)
                    if let localStringsfileContent = String(data: localStringsfile.readDataToEndOfFile(), encoding: .utf8) {
                        let removedInts = try translationString.replacingRegexMatches(of: "\\{[0-9]*\\{\\w+number\\}\\}", with: "%d")
                        let parsedRemoteString = try removedInts.replacingRegexMatches(of: "\\{[0-9]*\\{\\w+\\}\\}", with: "%@")
                        if localStringsfileContent.replacingOccurrences(of: "\\n", with: "") == parsedRemoteString.replacingOccurrences(of: "\\n", with: "") {
                            print("No changes detected between local and remote strings file".green)
                            print("Exiting!".green)
                            return
                        }
                    }
                }
            }
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
        }
    } catch let error {
        print("Error found: \(error.localizedDescription)".red)
    }
}.run()
