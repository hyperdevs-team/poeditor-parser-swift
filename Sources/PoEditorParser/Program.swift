import Commander
import Foundation
import Rainbow

public class Program {
    public init() {}

    public func run(
        token: String?,
        id: Int?,
        language: String?,
        onlyGenerate: Bool,
        swiftFile: String,
        stringsFile: String,
        typeName: String,
        tableName: String?,
        outputFormat: OutputFormat,
        keysFormat: KeysFormat,
        format: TranslationFormat,
        exportAll: Bool,
        poEditorApiUrl: String
    ) throws {
        do {
            // For xcstrings the translations file lives at a `.xcstrings` path
            // (defaulting to the stringsFile path with the extension swapped).
            let translationsFile = format == .xcstrings
                ? (stringsFile as NSString).deletingPathExtension + ".xcstrings"
                : stringsFile

            print("🚀  Starting PoEditor Parser v\(POEConstants.version)".blue)
            print("-  Only Generate: \(onlyGenerate)".white)
            print("-  Translation format: \(format)".white)
            print("-  Export all languages: \(exportAll)".white)
            print("-  Generating Swift: \(swiftFile)".white)
            print("-  Generating translations: \(translationsFile)".white)
            print("-  Type name: \(typeName)".white)
            print("-  Table name: \(tableName ?? "NOT SET")".white)
            print("-  Output format: \(outputFormat)".white)
            print("-  Keys format: \(keysFormat)".white)

            let translationStringContent: String

            if !onlyGenerate {
                guard let token else { throw AppError.missingOptionApiToken }
                guard let id else { throw AppError.missingOptionProjectId }
                guard let language else { throw AppError.missingOptionProjectLanguage }
                print("ℹ️ Fetching contents of strings at POEditor...".blue)
                print("🔄 Querying POEditor for the latest strings file...".magenta)
                var request = URLRequest(url: URL(string: "\(poEditorApiUrl)/projects/export")!)
                request.httpMethod = "POST"
                var parameters = ""
                    + "api_token=\(token)&"
                    + "id=\(id)&"
                    + "language=\(language)&"
                    + "type=\(format.apiType)"

                if exportAll {
                    let options = "[{\"export_all\": 1}]"
                        .addingPercentEncoding(withAllowedCharacters: .alphanumerics) ?? ""
                    parameters += "&options=\(options)"
                }
                request.httpBody = parameters.data(using: .utf8)
                let data = try URLSession.shared.syncDataTask(with: request)
                guard
                    let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                    let result = json["result"] as? [String: Any],
                    let urlString = result["url"] as? String,
                    let url = URL(string: urlString)
                else {
                    throw AppError.apiConnectError
                }
                print("✅ Successfully got the latest URL for the strings file from POEditor".green)

                print("🔄 Downloading the latest strings file from POEditor...".magenta)
                print("URL: \(urlString)".lightWhite)
                let downloadRequest = URLRequest(url: url)
                let downloadData = try URLSession.shared.syncDataTask(with: downloadRequest)
                guard let translationString = NSString(data: downloadData, encoding: String.Encoding.utf8.rawValue) as String? else {
                    throw AppError.apiDownloadTermsError
                }
                print("✅ Successfully downloaded the latest strings file from POEditor!".green)
                translationStringContent = translationString
            } else {
                print("✅ Fetching content from passed strings path".green)
                print("ℹ️ Reading content from: \(translationsFile)".green)
                guard let data = FileManager.default.contents(atPath: translationsFile) else {
                    throw AppError.fileNotFound(file: translationsFile)
                }
                guard let content = String(data: data, encoding: .utf8) else {
                    throw AppError.fileOpenError(file: translationsFile)
                }

                translationStringContent = content
            }

            print("ℹ️ Parsing translations file...".blue)
            let parser: TranslationParser
            switch format {
            case .strings:
                parser = StringTranslationParser(typeName: typeName,
                                                 translation: translationStringContent,
                                                 keysFormat: keysFormat)

            case .xcstrings:
                parser = XCStringsTranslationParser(typeName: typeName,
                                                    translation: translationStringContent,
                                                    keysFormat: keysFormat,
                                                    preferredLanguage: language)
            }
            let translations = try parser.parse().sorted()

            FileManager.default.createFile(atPath: swiftFile, contents: nil, attributes: nil)
            guard let swiftHandle = FileHandle(forWritingAtPath: swiftFile) else {
                throw AppError.writeFileError(file: swiftFile)
            }
            let fileCodeGenerator = FileCodeGenerator(fileHandle: swiftHandle,
                                                      typeName: typeName,
                                                      tableName: tableName,
                                                      outputFormat: outputFormat)
            fileCodeGenerator.generateCode(translations: translations)
            print("✅ Success! Literals generated at \(swiftFile)".green)

            switch format {
            case .strings:
                FileManager.default.createFile(atPath: translationsFile, contents: nil, attributes: nil)
                guard let stringsHandle = FileHandle(forWritingAtPath: translationsFile) else {
                    throw AppError.writeFileError(file: translationsFile)
                }
                let stringsFileGenerator = StringsFileGenerator(fileHandle: stringsHandle)
                stringsFileGenerator.generateCode(translations: translations)
                print("✅ Success! Strings generated at \(translationsFile)".green)

            case .xcstrings:
                if !onlyGenerate {
                    let normalized = XCStringsTranslationParser.normalizingPlaceholders(in: translationStringContent)
                    try normalized.write(toFile: translationsFile, atomically: true, encoding: .utf8)
                }
                print("✅ Success! String catalog written at \(translationsFile)".green)
            }
        } catch let error {
            print("❌ [ERROR] \(error.localizedDescription)".red)
            throw error
        }
    }
}
