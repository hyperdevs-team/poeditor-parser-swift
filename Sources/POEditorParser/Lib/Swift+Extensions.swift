//
//  Swift+Extensions.swift
//  POEditorParser
//
//  Created by Jorge Revuelta on 24/10/18.
//

import Foundation

extension String {
    func replacingRegexMatches(of pattern: String, with replacing: String) throws -> String {
        let regex = try NSRegularExpression(pattern: pattern, options: NSRegularExpression.Options.caseInsensitive)
        let range = NSMakeRange(0, self.count)
        return regex.stringByReplacingMatches(in: self, options: [], range: range, withTemplate: replacing)
    }
    
    var unescaped: String {
        let entities = ["\0", "\t", "\n", "\r", "\"", "\'", "\\"]
        var current = self
        for entity in entities {
            let descriptionCharacters = entity.debugDescription.dropFirst().dropLast()
            current = current.replacingOccurrences(of: descriptionCharacters, with: entity)
        }
        return current
    }
}
