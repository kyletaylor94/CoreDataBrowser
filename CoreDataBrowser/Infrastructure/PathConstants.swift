//
//  PathConstants.swift
//  CoreDataBrowser
//
//  Created by Turdesan Csaba on 2026. 03. 12..
//

import Foundation

enum PathConstants {
    static let simulatorPath = "Library/Developer/CoreSimulator/Devices"
    static let simulatorAppsPath = "data/Containers/Data/Application"
    static let library = "Library"
    static let libraryPreferencesPath = "\(library)/Preferences"
    static let libraryApplicationSupportPath = "\(library)/Application Support"
    static let plistExtension = "plist"
    static let devicePlist = "device.\(plistExtension)"
}
