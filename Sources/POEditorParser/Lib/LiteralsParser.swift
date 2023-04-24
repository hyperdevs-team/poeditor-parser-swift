//
//  Swift+Extensions.swift
//  POEditorParser
//
//  Created by Jorge Revuelta on 24/10/18.
//

import Foundation

enum Literals {
    static var Welcome: String {
        return ""
    }
    static func ReadBooksKey(readNumber: Int) -> String {
        return ""
    }
}

struct Variable {
    let type: VariableType
    let rawKey: String
    
    // iOS (Used from TRANSLATION)
    var parameterKey: String {
        /*
         We need to do some herustics here since the format is not standarized
         Examples:
         - paginas del libro
         - alreadyReadPages <- this should not be captialized (or we'll lose the Read and Pages capital letters)
         */
        
        let words = rawKey.components(separatedBy: .alphanumerics.inverted)
        if words.count == 1 {
            return words[0].lowercaseFirst
        }
        
        var result = ""
        for (i, var s) in words.enumerated() {
            if i > 0 {
                s = s.capitalized
            }
            result += s
        }
        
        return result
    }
    
    init(rawKey: String) {
        self.rawKey = rawKey
        self.type = VariableType(string: rawKey)
    }
}

enum VariableType {
    case numeric
    case textual
}

extension VariableType {
    var localizedRepresentation: String {
        switch self {
        case .numeric: return "%d"
        case .textual: return "%@"
        }
    }
    
    // Analyzes the string to match an appropriate VariableType
    init(string: String) {
        let s = string.lowercased()
        let tests = [{s.contains("number")}]
        
        for t in tests where t() {
            self = .numeric
            return
        }
        
        self = .textual
    }
}
extension VariableType {
    private var swiftType: String {
        switch self {
        case .numeric: return "Int" // TODO: Decimal types?
        case .textual: return "String"
        }
    }
    
    func swiftParameter(key: String) -> String {
        return key.snakeCased() + ": " + swiftType
    }
}


let localizedStringFunction = "NSLocalizedString"
public struct Translation {
    let rawKey: String
    let rawValue: String
    
    let localizedValue: String
    let variables: [Variable]
    
    init(rawKey: String, rawValue: String) {
        self.rawKey = rawKey
        self.rawValue = rawValue
        
        // Parse translationValue
        (localizedValue, variables) = TranslationValueParser.parseTranslationValue(translationValue: rawValue)
    }
    
    private var prettyKey: String {
        return rawKey.capitalized.replacingOccurrences(of: "_", with: "")
    }
    
    func swiftCode(accessModifier: AccessModifier = .public, bundleModifier: BundleModifier = .main) -> String {
        if variables.isEmpty {
            return generateVariableLessSwiftCode(accessModifier: accessModifier, bundleModifier: bundleModifier)
        } else {
            return generateVariableSwiftCode(accessModifier: accessModifier, bundleModifier: bundleModifier)
        }
    }
    
    private func generateVariableLessSwiftCode(
        accessModifier: AccessModifier,
        bundleModifier: BundleModifier
    ) -> String {
        /*
         static var Welcome: String {
         return NSLocalizedString()
         }
         */
        return "\t\(accessModifier.rawValue) static var \(prettyKey): String {\n\t\treturn \(localizedStringFunction)(\"\(rawKey)\", bundle: .\(bundleModifier.rawValue), comment: \"\")\n\t}\n"
    }
    
    private func generateVariableSwiftCode(
        accessModifier: AccessModifier,
        bundleModifier: BundleModifier
    ) -> String {
        /*
         static func ReadBooksKey(readNumber: Int) -> String {
         return ""
         }
         */
        let uniqueKeyVariables: [Variable] = {
            guard variables.count > 1 else {
                return variables
            }

            return variables
                .enumerated()
                .map { (index, variable) in
                    return .init(rawKey: variable.rawKey + "_\(index)")
                }
        }()

        let parameters = uniqueKeyVariables
            .map { $0.type.swiftParameter(key: $0.parameterKey) }
            .joined(separator: ", ")
        let localizedArguments = uniqueKeyVariables
            .map { $0.parameterKey }
            .map { $0.snakeCased() }
            .joined(separator: ", ")
        return "\t\(accessModifier.rawValue) static func \(prettyKey)(\(parameters)) -> String {\n\t\treturn String(format: \(localizedStringFunction)(\"\(rawKey)\", bundle: .\(bundleModifier.rawValue), comment: \"\"), \(localizedArguments))\n\t}"
    }
    
}

enum SwiftCodeGeneratorConstants {
    static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .iso8601)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        return formatter
    }()
    
    static func rootObjectHeader(accessModifier: AccessModifier = .public) -> String {
        """
        // Generated using POEditorParser
        // DO NOT EDIT
        // Generated: \(SwiftCodeGeneratorConstants.dateFormatter.string(from: Date()))
        
        // swiftlint:disable all

        import Foundation
        
        \(accessModifier.rawValue) enum Literals {
        """
    }
    static let rootObjectFooter = "\n}\n// swiftlint:enable all\n"
    
    static let methodOrVariableHeader = "\n"
}

public protocol SwiftCodeGenerator {
    func generateCode(translations: [Translation])
}

public class FileCodeGenerator: SwiftCodeGenerator {
    
    let fileHandle: FileHandle
    let accessModifier: AccessModifier
    let bundleModifier: BundleModifier
    public init(
        fileHandle: FileHandle,
        access: String,
        bundle: String
    ) {
        self.fileHandle = fileHandle
        self.accessModifier = .init(accessString: access)
        self.bundleModifier = .init(bundleName: bundle)
    }
    
    // TODO: Generalize!!! += (same code as in string)
    public func generateCode(translations: [Translation]) {
        fileHandle += SwiftCodeGeneratorConstants.rootObjectHeader(accessModifier: accessModifier)
        
        for t in translations {
            fileHandle += SwiftCodeGeneratorConstants.methodOrVariableHeader
            fileHandle += t.swiftCode(accessModifier: accessModifier, bundleModifier: bundleModifier)
        }
        
        fileHandle += SwiftCodeGeneratorConstants.rootObjectFooter
        
        fileHandle.closeFile()
    }
}

public class StringsFileGenerator {
    let fileHandle: FileHandle
    
    public init(fileHandle: FileHandle) {
        self.fileHandle = fileHandle
    }
    
    public func generateCode(translations: [Translation]) {
        for t in translations {
            fileHandle += "\"\(t.rawKey)\" = \"\(t.localizedValue)\";\n"
        }
    }
}

public func +=(lhs: FileHandle, rhs: String) {
    lhs.write(rhs.data(using: .utf8)!)
}

protocol TranslationParser {
    func parse() -> [Translation]
}

public class StringTranslationParser: TranslationParser {
    
    let translation: String
    public init(translation: String) {
        self.translation = translation
    }
    
    public func parse() -> [Translation] {
        var translations = [Translation]()
        
        let s = Scanner(string: translation)
        let charSet = NSMutableCharacterSet.whitespaceAndNewline()
        charSet.formUnion(with: CharacterSet(charactersIn: ";"))
        s.charactersToBeSkipped = charSet as CharacterSet
        
        while true {
            let commentFound = s.scanString("/*", into: nil)
            if commentFound {
                // skip comment
                s.scanUpTo("*/", into: nil)
                s.scanLocation += 2
            }
            
            if s.isAtEnd {
                break
            }
            
            let translationFound = s.scanString("\"", into: nil)
            
            if translationFound {
                var key: NSString?
                s.scanUpTo("\"", into: &key)
                s.scanLocation += 1
                
                s.scanUpTo("\"", into: nil)
                s.scanLocation += 1
                
                var value: NSString?
                s.scanUpTo("\";", into: &value)
                s.scanLocation += 2
                var finalValue: NSString?
                if let value = value {
                    finalValue = value.substring(to: value.length) as NSString
                }
                
                translations.append(Translation(rawKey: key! as String, rawValue: finalValue as String? ?? ""))
                
            }
            if s.isAtEnd {
                break
            }
        }
        
        
        return translations
    }
}



enum TranslationValueParser {
    static func parseTranslationValue(translationValue: String) -> (localizedDescription: String, variables: [Variable]) {
        let s = Scanner(string: translationValue)
        s.charactersToBeSkipped = nil
        
        /*
         Algorithm:
         
         1. Scan up to { into a buffer.
         ¿Scanned something?
         1.1 YES: Add that to the localizedString result
         2. Check if we are are at the end
         2.1 YES: we have finished. Go to END
         2.2 NO: Go to 3
         3. Scan for a number
         Found?
         3.1: YES: we need to take into account order. Go to 4
         3.2: NO: Go to 4
         4. Scan up to '}}' into a variable. Both adding it to the list and adding the localizedRepresentation to the localizedString result.
         5. Go to 1.
         
         END: Sort the variables array
         
         */
        var localizedString = ""
        var variables = [(order: Int, variable: Variable)]()
        
        while true {
            var out: NSString?
            s.scanUpTo("{", into: &out)
            
            if let o = out {
                localizedString += o as String
            }
            
            if s.isAtEnd {
                break
            }
            s.scanLocation += 1
            
            var intOut: Int32 = 0
            let intScanned = s.scanInt32(&intOut)
            
            if intScanned {
                // ordered var
            } else {
                //unordered var
            }
            
            s.scanLocation += 1
            
            var variableName: NSString?
            s.scanUpTo("}}", into: &variableName)
            
            // AssociateOrder if ordered
            let v = Variable(rawKey: variableName! as String)
            localizedString += v.type.localizedRepresentation
            variables.append((order: Int(intOut), variable: v))
            
            s.scanLocation += 2 // Advance the '}}'
        }
        
        variables.sort(by: { $0.order < $1.order })
        let orderedVariables = variables.map{ $0.variable }
        return (localizedString, orderedVariables)
    }
}


enum AccessModifier: String {
    case `public`, `private`, `open`, `internal`
    
    init(accessString: String) {
        self = AccessModifier(rawValue: accessString) ?? .public
    }
}

enum BundleModifier: String {
    case main
    case module
    
    init(bundleName: String) {
        self = BundleModifier(rawValue: bundleName) ?? .main
    }
}


extension String {
    var first: String {
        return String(prefix(1))
    }
    
    var lowercaseFirst: String {
        return first.lowercased() + String(dropFirst())
    }
    
    mutating func snakeCase() -> String {
        return self
            .split(separator: "_")  // split to components
            .map(String.init)   // convert subsequences to String
            .enumerated()  // get indices
            .map { $0.offset > 0 ? $0.element.capitalized : $0.element.lowercased() } // added lowercasing
            .joined()
    }
    
    func snakeCased() -> String {
        return self
            .split(separator: "_")  // split to components
            .map(String.init)   // convert subsequences to String
            .enumerated()  // get indices
            .map { $0.offset > 0 ? $0.element.capitalized : $0.element.lowercased() } // added lowercasing
            .joined()
    }
}

