//
//  DetailType.swift
//  CoreDataBrowser
//
//  Created by Turdesan Csaba on 2026. 09. 08..
//

import Foundation

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
