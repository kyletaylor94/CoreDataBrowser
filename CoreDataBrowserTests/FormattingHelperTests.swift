//
//  FormattingHelperTests.swift
//  CoreDataBrowserTests
//
//  Created by Turdesan Csaba on 2026. 03. 22..
//

import Testing
@testable import CoreDataBrowser

struct FormattingHelperTests {
    
    @Test("Formatted file size returns bytes for values under 1 kB")
    func formattedFileSizeReturnsBytesForSmallValues() async throws {
        #expect(FormattingHelper.formattedFileSize(0) == "0 bytes")
        #expect(FormattingHelper.formattedFileSize(1) == "1 bytes")
        #expect(FormattingHelper.formattedFileSize(512) == "512 bytes")
        #expect(FormattingHelper.formattedFileSize(1023) == "1023 bytes")
    }
    
    @Test("Formatted file size returns kB for values between 1 kB and 1 MB")
    func formattedFileSizeReturnsKiloBytes() async throws {
        #expect(FormattingHelper.formattedFileSize(1024) == "1.00 KB")
        #expect(FormattingHelper.formattedFileSize(2048) == "2.00 KB")
        #expect(FormattingHelper.formattedFileSize(1536) == "1.50 KB")
        #expect(FormattingHelper.formattedFileSize(1_048_575) == "1024.00 KB")
    }
    
    @Test("Formatted file size returns MB for values between 1 MB and above")
    func formattedFileSizeReturnsMegaBytes() async throws {
        #expect(FormattingHelper.formattedFileSize(1_048_576) == "1.00 MB")
        #expect(FormattingHelper.formattedFileSize(2_097_152) == "2.00 MB")
        #expect(FormattingHelper.formattedFileSize(1_572_864) == "1.50 MB")
        #expect(FormattingHelper.formattedFileSize(10_485_760) == "10.00 MB")
    }
    
    @Test("Formatted file size handles exact boundary between bytes and kB")
    func formattedFileSizeHandlesBoundaryBetweenBytesAndKiloBytes() async throws {
        #expect(FormattingHelper.formattedFileSize(1023) == "1023 bytes")
        #expect(FormattingHelper.formattedFileSize(1024) == "1.00 KB")
    }
    
    @Test("Formatted file size handles exacct boundary between KB and MB")
    func formattedFileSizeHandlesKBToMBBoundary() async throws {
        #expect(FormattingHelper.formattedFileSize(1_048_575) == "1024.00 KB")
        #expect(FormattingHelper.formattedFileSize(1_048_576) == "1.00 MB")
    }
}
