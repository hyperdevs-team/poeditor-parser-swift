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
}
