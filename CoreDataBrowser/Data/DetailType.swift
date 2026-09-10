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
    
    var displayedInfo: (title: String, icon: String) {
        switch self {
        case .coreData:
            (title: "CoreData", icon: "cylinder.split.1x2")
        case .swiftData:
            (title: "SwiftData", icon: "externaldrive.badge.checkmark")
        case .userDefaults:
            (title: "UserDefaults", icon: "gearshape.2")
        }
    }
}
