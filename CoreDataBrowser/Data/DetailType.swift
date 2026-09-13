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
            (title: AppConstants.DataSourceName.coreData, icon: AppConstants.DataSourceIcons.coreData)
        case .swiftData:
            (title: AppConstants.DataSourceName.swiftData, icon: AppConstants.DataSourceIcons.swiftData)
        case .userDefaults:
            (title: AppConstants.DataSourceName.userDefaults, icon: AppConstants.DataSourceIcons.userDefaults)
        }
    }
}
