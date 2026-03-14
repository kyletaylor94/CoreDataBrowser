//
//  BlobDecoder.swift
//  CoreDataBrowser
//
//  Created by Turdesan Csaba on 2026. 03. 14..
//

import Foundation

final class BlobDecoder {
    /// Decodes the given data into a human-readable string representation.
    /// - Parameter data: The binary data to decode.
    /// - Returns: A `String` representing the decoded data, or `nil` if the data could not be decoded.
    func decode(from data: Data) -> String? {
        if let object = try? NSKeyedUnarchiver.unarchivedObject(ofClasses: [
            NSString.self,
            NSNumber.self,
            NSArray.self,
            NSDictionary.self,
            NSData.self,
            NSURL.self,
            NSDate.self
        ], from: data) {
            return formatDecodedObject(object)
        }
        
        if let json = try? JSONSerialization.jsonObject(with: data),
           let jsonData = try? JSONSerialization.data(withJSONObject: json, options: .prettyPrinted),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            return jsonString
        }
        
        if let plist = try? PropertyListSerialization.propertyList(from: data, format: nil) {
            return "\(plist)"
        }
        
        if let string = String(data: data, encoding: .utf8) {
            return string
        }
        
        return nil
    }
    
    /// Formats a decoded object into a human-readable string representation.
    /// - Parameter object: The decoded object to format.
    /// - Returns: A `String` representing the formatted object.
    private func formatDecodedObject(_ object: Any) -> String {
        switch object {
        case let dict as [AnyHashable: Any]:
            let pairs = dict.map { "\($0): \($1)" }.joined(separator: ", ")
            return "{\(pairs)}"
            
        case let array as [Any]:
            let items = array.map { "\($0)" }.joined(separator: ", ")
            return "[\(items)]"
            
        case let date as Date:
            let formatter = ISO8601DateFormatter()
            return formatter.string(from: date)
            
        case let url as URL:
            return url.absoluteString
            
        default:
            return "\(object)"
        }
    }
}
