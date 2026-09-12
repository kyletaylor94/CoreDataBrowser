//
//  DetailContentView.swift
//  CoreDataBrowser
//
//  Created by Turdesan Csaba on 2026. 03. 09..
//

import Foundation
import SwiftUI

struct DetailContentView: View {
    let table: DBDataTable
    let isLoading: Bool
    let type: DetailType
    @Binding var hasError: Bool
    let errorMessage: String?
    let onDismiss: () -> Void
    let onErrorDismiss: () -> Void
    let copyAction: () -> Void
    let isCopied: Bool
    
    var body: some View {
        Group {
            if isLoading {
                ProgressView()
            } else {
                SourceHeaderView(displayedInfo: type.displayedInfo, action: onDismiss, copyAction: copyAction, isCopied: isCopied)
                switch type {
                case .userDefaults:
                    UserDefaultsTableView(table: table)
                case .coreData:
                    DBDetailsView(table: table, isSwiftDataContent: false)
                case .swiftData:
                    DBDetailsView(table: table, isSwiftDataContent: true)
                }
            }
        }
        .createAlert(isPresented: $hasError, errorMessage: errorMessage, onDismiss: onErrorDismiss)
    }
}

