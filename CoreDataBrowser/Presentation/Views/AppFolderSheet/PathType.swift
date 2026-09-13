//
//  PathType.swift
//  CoreDataBrowser
//
//  Created by Turdesan Csaba on 2026. 03. 14..
//

import Foundation
import SwiftUI

enum PathType: CaseIterable, Hashable {
    case simulator, coreData, swiftData, userDefaults
    
    var attributes: (title: String, placeholder: String) {
        switch self {
        case .simulator:
            return (title: AppConstants.PathTypeStrings.simulator, placeholder: PathConstants.simulatorPath)
        case .coreData:
            return (title: AppConstants.PathTypeStrings.coreData, placeholder: PathConstants.libraryApplicationSupportPath)
        case .swiftData:
            return (title: AppConstants.PathTypeStrings.swiftData, placeholder: PathConstants.libraryApplicationSupportPath)
        case .userDefaults:
            return (title: AppConstants.PathTypeStrings.userDefaults, placeholder: PathConstants.libraryPreferencesPath)
        }
    }
    func binding(from pathManager: PathManagerImpl) -> Binding<String> {
        switch self {
        case .simulator: return Binding.from(pathManager, keyPath: \.simulatorPath)
        case .coreData: return Binding.from(pathManager, keyPath: \.coreDataPath)
        case .swiftData: return Binding.from(pathManager, keyPath: \.swiftDataPath)
        case .userDefaults: return Binding.from(pathManager, keyPath: \.userDefaultsPath)
        }
    }
}
