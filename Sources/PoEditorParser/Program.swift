import Commander
import Foundation
import Rainbow

public class Program {
    public init() {}

    /// Download a String Catalog (`.xcstrings`) from POEditor and write it to
    /// `out`, normalizing placeholders (`{1{var}}` -> `{{var}}`) in a single
    /// pass. All languages are always exported: a `.xcstrings` is inherently
    /// multi-language.
    public func download(
        token: String,
        id: Int,
        language: String,
        out: String,
        poEditorApiUrl: String
    ) throws {
        do {
            guard !token.isEmpty else { throw AppError.missingOptionApiToken }
            guard id != 0 else { throw AppError.missingOptionProjectId }

            print("🚀  Starting PoEditor Parser v\(POEConstants.version)".blue)
            print("-  Downloading translations: \(out)".white)

            print("🔄 Querying POEditor for the latest strings file...".magenta)
            var request = URLRequest(url: URL(string: "\(poEditorApiUrl)/projects/export")!)
            request.httpMethod = "POST"
            let options = "[{\"export_all\": 1}]"
                .addingPercentEncoding(withAllowedCharacters: .alphanumerics) ?? ""
            let parameters = ""
                + "api_token=\(token)&"
                + "id=\(id)&"
                + "language=\(language)&"
                + "type=xcstrings&"
                + "options=\(options)"
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
            print("✅ Got the latest URL for the strings file from POEditor".green)

            print("🔄 Downloading the latest strings file from POEditor...".magenta)
            let downloadData = try URLSession.shared.syncDataTask(with: URLRequest(url: url))
            guard let downloaded = String(data: downloadData, encoding: .utf8) else {
                throw AppError.apiDownloadTermsError
            }
            print("✅ Downloaded the latest strings file from POEditor!".green)

            let normalized = XCStringsTranslationParser.normalizingPlaceholders(in: downloaded)
            try normalized.write(toFile: out, atomically: true, encoding: .utf8)
            print("✅ Success! String catalog written at \(out)".green)
        } catch let error {
            print("❌ [ERROR] \(error.localizedDescription)".red)
            throw error
        }
    }

    /// Generate the Swift literals file from a local `.xcstrings`.
    public func generate(
        input: String,
        swiftFile: String,
        typeName: String,
        tableName: String?,
        outputFormat: OutputFormat,
        keysFormat: KeysFormat,
        language: String?
    ) throws {
        do {
            print("🚀  Starting PoEditor Parser v\(POEConstants.version)".blue)
            print("-  Reading translations: \(input)".white)
            print("-  Generating Swift: \(swiftFile)".white)
            print("-  Type name: \(typeName)".white)
            print("-  Output format: \(outputFormat)".white)
            print("-  Keys format: \(keysFormat)".white)

            guard let data = FileManager.default.contents(atPath: input) else {
                throw AppError.fileNotFound(file: input)
            }
            guard let content = String(data: data, encoding: .utf8) else {
                throw AppError.fileOpenError(file: input)
            }

            let parser = XCStringsTranslationParser(typeName: typeName,
                                                    translation: content,
                                                    keysFormat: keysFormat,
                                                    preferredLanguage: language)
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
        } catch let error {
            print("❌ [ERROR] \(error.localizedDescription)".red)
            throw error
        }
    }

    /// Split a multi-brand `.xcstrings` into a single-brand one.
    public func distribute(input: String, out: String, brand: String) throws {
        do {
            guard !brand.isEmpty else { throw AppError.missingRequiredOption(option: "brand") }
            let source = try StringCatalog(contentsOfFile: input)
            let result = source.distributed(toSuffix: brand)
            try result.write(toFile: out)
            print("✅ Distributed \(brand): \(result.strings.count) keys → \(out)".green)
        } catch let error {
            print("❌ [ERROR] \(error.localizedDescription)".red)
            throw error
        }
    }

    /// Keep only the changes of keys matching `keys` between a baseline and a
    /// working `.xcstrings`; every other key falls back to the baseline.
    public func filter(baseline: String, working: String, out: String, keys: [String]) throws {
        do {
            let matcher = KeyMatcher(patterns: keys)
            guard !matcher.isEmpty else { return }
            // Baseline may be absent/empty on the first migration (file not yet in
            // HEAD): treat it as an empty catalog so every key shows up as an add
            // and only filter-matching keys survive.
            let base = (try? StringCatalog(contentsOfFile: baseline))
                ?? StringCatalog(sourceLanguage: "es", version: "1.0", strings: [:])
            let work = try StringCatalog(contentsOfFile: working)
            let result = base.filtered(applying: work, keys: matcher)
            try result.write(toFile: out)
            print("✅ Filtered \(out) (\(result.strings.count) keys)".green)
        } catch let error {
            print("❌ [ERROR] \(error.localizedDescription)".red)
            throw error
        }
    }

    /// Remove every key matching `keys` from a `.xcstrings`.
    public func remove(input: String, out: String, keys: [String], dryRun: Bool) throws {
        do {
            let matcher = KeyMatcher(patterns: keys)
            guard !matcher.isEmpty else { throw AppError.missingRequiredOption(option: "keys") }
            let source = try StringCatalog(contentsOfFile: input)
            let removed = source.strings.keys.filter { matcher.matches($0) }.sorted()

            if dryRun {
                print("Dry-run: would remove \(removed.count) keys from \(input):".yellow)
                removed.forEach { print("  - \($0)") }
                return
            }
            try source.removing(keys: matcher).write(toFile: out)
            print("✅ Removed \(removed.count) keys → \(out)".green)
        } catch let error {
            print("❌ [ERROR] \(error.localizedDescription)".red)
            throw error
        }
    }
}
