import Foundation

struct Variable: Equatable {
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

        let words = rawKey.split(separator: " ").map(String.init)
        if words.count == 1 {
            return words[0].lowercaseFirst
        }

        var result = ""
        for (i, var str) in words.enumerated() {
            if i > 0 {
                str = str.capitalized
            }
            result += str
        }

        return result
    }

    init(rawKey: String) {
        self.rawKey = rawKey
        self.type = VariableType(string: rawKey)
    }

    static func == (lhs: Variable, rhs: Variable) -> Bool {
        lhs.type == rhs.type && lhs.rawKey == rhs.rawKey
    }
}
