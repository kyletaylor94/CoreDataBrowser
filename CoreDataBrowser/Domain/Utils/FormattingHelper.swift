//
//  FormattingHelper.swift
//  CoreDataBrowser
//
//  Created by Turdesan Csaba on 2026. 03. 12..
//

import Foundation

enum FormattingHelper {
    private static let bytesPerKB = 1024.0
    private static let bytesPerMB = bytesPerKB * 1024.0
    
    /// Formats a file size in bytes into a human-readable string with appropriate units (bytes, KB, MB).
    /// - Parameter bytes: The file size in bytes.
    /// - Returns: A string representing the formatted file size with appropriate units.
    static func formattedFileSize(_ bytes: Int64) -> String {
        let bytesDouble = Double(bytes)
        let kb = bytesDouble / bytesPerKB
        let mb = bytesDouble / bytesPerMB
        
        if mb >= 1.0 {
            return String(format: AppConstants.FileSizeStringFormat.mb, mb)
        } else if kb >= 1.0 {
            return String(format: AppConstants.FileSizeStringFormat.kb, kb)
        } else {
            return "\(bytes) \(AppConstants.bytes)"
        }
    }
    
    /// Removes the "Z" prefix from a Core Data SQLite column/table name if it exists and is followed by an uppercase letter.
    /// Example: "ZNAME" becomes "NAME", but "Zname" remains "Zname".
    /// - Parameter name: The column or table name to strip the prefix from.
    /// - Returns: The name without the leading "Z" prefix, or the original name if the prefix isn't present.
    static func removeZPrefix(from name: String) -> String {
        guard name.count >= 2,
              name.first == "Z",
              name.dropFirst().first?.isUppercase == true else {
            return name
        }
        return String(name.dropFirst())
    }
    
    /// Converts a fully-uppercased, delimiter-less identifier (like the ones Core Data generates for
    /// its SQLite tables/columns, e.g. `"CREATEDAT"` or `"FRUITENTITY"`) into a readable `camelCase`
    /// string (e.g. `"createdAt"`, `"fruitEntity"`).
    ///
    /// Since the original mixed-case boundaries aren't recoverable from the uppercased SQL identifier
    /// alone, this greedily peels known common word fragments off the end of the string (longest match
    /// first) and treats whatever's left over as a single leading word. This correctly handles common
    /// patterns (e.g. an `"Entity"` suffix, or compound words like `"sugarContent"`/`"arrayData"`)
    /// while safely falling back to a single lowercase word when nothing recognizable matches.
    /// - Parameter identifier: The raw, uppercased identifier to convert.
    /// - Returns: A best-effort `camelCase` version of the identifier.
    static func camelCased(from identifier: String) -> String {
        guard !identifier.isEmpty else { return identifier }
        
        var remaining = identifier.uppercased()
        var words: [String] = []
        let sortedFragments = AppConstants.camelCaseWordFragments.sorted { $0.count > $1.count }
        
        var didStrip = true
        while didStrip, !remaining.isEmpty {
            didStrip = false
            for fragment in sortedFragments {
                let upperFragment = fragment.uppercased()
                if remaining == upperFragment {
                    words.append(fragment)
                    remaining = AppConstants.emptyString
                    didStrip = true
                    break
                } else if remaining.count > upperFragment.count, remaining.hasSuffix(upperFragment) {
                    words.append(fragment)
                    remaining.removeLast(upperFragment.count)
                    didStrip = true
                    break
                }
            }
        }
        
        if !remaining.isEmpty {
            words.append(remaining.capitalized)
        }
        
        guard !words.isEmpty else {
            return identifier.lowercased()
        }
        
        words.reverse()
        let firstWord = words[0].lowercased()
        let restWords = words.dropFirst().map { $0.prefix(1).uppercased() + $0.dropFirst().lowercased() }
        return ([firstWord] + restWords).joined()
    }
    
    /// Same as `camelCased(from:)`, but capitalizes the first letter too (i.e. `PascalCase` instead of
    /// `camelCase`). Used for entity/type names, which conventionally start with an uppercase letter.
    /// - Parameter identifier: The raw, uppercased identifier to convert.
    /// - Returns: A best-effort `PascalCase` version of the identifier.
    static func pascalCased(from identifier: String) -> String {
        let camel = camelCased(from: identifier)
        guard let first = camel.first else { return camel }
        return first.uppercased() + camel.dropFirst()
    }
}
