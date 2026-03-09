//
//  Extensions.swift
//  CoreDataBrowser
//
//  Created by Turdesan Csaba on 2026. 03. 09..
//

import Foundation
import SwiftUI

enum FormattingHelper {
    private static let bytesPerKB = 1024.0
    private static let bytesPerMB = bytesPerKB * 1024.0
    
    static func formattedFileSize(_ bytes: Int64) -> String {
        let bytesDouble = Double(bytes)
        let kb = bytesDouble / bytesPerKB
        let mb = bytesDouble / bytesPerMB
        
        if mb >= 1.0 {
            return String(format: "%.2f MB", mb)
        } else if kb >= 1.0 {
            return String(format: "%.2f KB", kb)
        } else {
            return "\(bytes) bytes"
        }
    }
}

extension Notification.Name {
    static let tableDidRefresh = Notification.Name(Constants.tableDidRefresh)
}

extension Alert {
     func createAlert(message: String?, action: @escaping () -> Void) -> Alert {
        Alert(
            title: Text("Error!"),
            message: Text(message ?? "Unknown Error"),
            dismissButton: .default(Text("OK")) {
                action()
            }
        )
    }
}
