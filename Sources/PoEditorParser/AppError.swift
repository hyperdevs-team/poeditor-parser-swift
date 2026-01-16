import Foundation

public enum AppError: Error, LocalizedError {
    case misspelledTerm(term: String, translation: String)
    case writeFileError(file: String)
    case fileNotFound(file: String)
    case fileOpenError(file: String)
    case apiDownloadTermsError
    case apiConnectError
    case missingOptionApiToken
    case missingOptionProjectId
    case missingOptionProjectLanguage

    public var errorDescription: String? {
        switch self {
        case .misspelledTerm(let key, let value):
            return "Misspelled term: \(key) = \(value)"

        case .writeFileError(let file):
            return "Couldn't write to file located at: \(file)"

        case .fileNotFound(let file):
            return "Couldn't open file located at: \(file)"

        case .fileOpenError(let file):
            return "Couldn't read file located at: \(file)"

        case .apiDownloadTermsError:
            return "Could not download terms from API: Check internet connection"

        case .apiConnectError:
            return "Could not connect to PoEditor API: Check Token or internet connection"

        case .missingOptionApiToken:
            return "Missing API Token: If you set --onlygenerate to false you must pass --apitoken"

        case .missingOptionProjectId:
            return "Missing project Id: If you set --onlygenerate to false you must pass --projectid"

        case .missingOptionProjectLanguage:
            return "Missing project language: If you set --onlygenerate to false you must pass --projectlanguage"
        }
    }
}
