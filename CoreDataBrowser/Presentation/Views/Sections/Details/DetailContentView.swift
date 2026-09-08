//
//  DetailContentView.swift
//  CoreDataBrowser
//
//  Created by Turdesan Csaba on 2026. 03. 09..
//

import Foundation
import SwiftUI

enum DetailType {
    case coreData
    case swiftData
    case userDefaults
    
    var title: String {
        switch self {
        case .coreData:
            "CoreData"
        case .swiftData:
            "SwiftData"
        case .userDefaults:
            "UserDefaults"
        }
    }
    
    var icon: String {
        switch self {
        case .coreData:
            "cylinder.split.1x2"
        case .swiftData:
            "externaldrive.badge.checkmark"
        case .userDefaults:
            "gearshape.2"
        }
    }
}

struct DetailContentView: View {
    let table: DBDataTable
    let isLoading: Bool
    let type: DetailType
    @Binding var hasError: Bool
    let errorMessage: String?
    let onDismiss: () -> Void
    let onErrorDismiss: () -> Void
    
    var body: some View {
        Group {
            if isLoading {
                ProgressView()
            } else {
                SourceHeaderView(icon: type.icon, title: type.title, action: onDismiss)
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

