//
//  BlogDecoderTests.swift
//  CoreDataBrowserTests
//
//  Created by Turdesan Csaba on 2026. 03. 17..
//

import Testing
import Foundation
@testable import CoreDataBrowser

struct BlogDecoderTests {

    @Test("Decode returns string from NSKeyedArchiver encoded NSString")
    func decodeReturnsStringFromNSKeyedArchiveerEncodedNSString() async throws {
        let decoder = await BlobDecoder()
        let original = "Hello, World!"
        let data = try NSKeyedArchiver.archivedData(withRootObject: original, requiringSecureCoding: true)
        
        let result = await decoder.decode(from: data)
        #expect(result == original)
    }
    
    @Test("Decode returns number from NSKEyedArchiver encoded NSNumber")
    func decodeReturnsNumberFromArchivedNSNumber() async throws {
        let decoder = await BlobDecoder()
        let data = try NSKeyedArchiver.archivedData(withRootObject: NSNumber(value: 45), requiringSecureCoding: true)
        
        let result = await decoder.decode(from: data)
        #expect(result == "45")
    }
    
    @Test("Decode returns formatted dict from archived NSDictionary")
    func decodeReturnsFormattedDictFromArchivedNSDictionary() async throws {
        let decoder = await BlobDecoder()
        let dict: NSDictionary = ["key": "value"]
        let data = try NSKeyedArchiver.archivedData(withRootObject: dict, requiringSecureCoding: false)
        
        let result = await decoder.decode(from: data)
        #expect(result != nil)
        #expect(result?.contains("key") == true)
        #expect(result?.contains("value") == true)
    }
    
    @Test("Decode returns ISO8601 date string from NSKeyedArchiver encoded NSDate")
    func decodeReturnsISO8601DateStringFromArchivedNSDate() async throws {
        let decoder = await BlobDecoder()
        let date = Date(timeIntervalSince1970: 0)
        let data = try NSKeyedArchiver.archivedData(withRootObject: date as Date, requiringSecureCoding: true)
        
        let result = await decoder.decode(from: data)
        #expect(result != nil)
        #expect(result?.contains("1970") == true)
    }
    
    @Test("Decode returns URL string from NSKeyedArchiver encoded NSURL")
    func decodeReturnsURLStringFromArchivedNSURL() async throws {
        let decoder = await BlobDecoder()
        let url = URL(string: "https://www.example.com")!
        let data = try NSKeyedArchiver.archivedData(withRootObject: url as NSURL, requiringSecureCoding: true)
        
        let result = await decoder.decode(from: data)
        #expect(result == "https://www.example.com")
    }
    
    @Test("Decode returns pretty printed JSON for string")
    func decodeReturnsPrettyPrintedJSON() async throws {
        let decoder = await BlobDecoder()
        let json: [String: Any] = ["key": "value", "number": 42]
        let data = try JSONSerialization.data(withJSONObject: json)
        
        let result = await decoder.decode(from: data)
        #expect(result != nil)
        #expect(result?.contains("key") == true)
        #expect(result?.contains("value") == true)
    }
    
    @Test("Decode returns pretty printed JSON for array")
    func decodeReturnsPrettyPrintedJSONForArray() async throws {
        let decoder = await BlobDecoder()
        let json: [Any] = ["one", "two", "three"]
        let data = try JSONSerialization.data(withJSONObject: json)
        
        let result = await decoder.decode(from: data)
        #expect(result != nil)
        #expect(result?.contains("one") == true)
        #expect(result?.contains("two") == true)
    }
    
    @Test("Decode returns plain UTF-8 string")
    func decodeReturnsPlainUTF8String() async throws {
        let decoder = await BlobDecoder()
        let original = "Hello, World!"
        let data = original.data(using: .utf8)!
        
        let result = await decoder.decode(from: data)
        #expect(result == original)
    }
    
    @Test("Decode returns nil for undecodable binary data")
    func decodeReturnsNilForUndecodableBinaryData() async throws {
        let decoder = await BlobDecoder()
        let data = Data([0x00, 0xFF, 0xAB])
        
        let result = await decoder.decode(from: data)
        #expect(result == nil)
    }
    
    @Test("Decode returns nil for empty data")
    func decodeReturnsNilForEmptyData() async throws {
        let decoder = await BlobDecoder()
        let data = Data()
        
        let result = await decoder.decode(from: data)
        #expect(result?.isEmpty == true)
    }
}
