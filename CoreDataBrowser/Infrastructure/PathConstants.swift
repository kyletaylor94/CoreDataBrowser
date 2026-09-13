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
    static let grantAccess = "Grant Access"
    static let accessPanelMessage = "CoreDataBrowser needs access to your Simulator devices to browse their app data. Select the top-level “Devices” folder itself — do not open it and select one of the simulator folders inside."
    static let simulatorBookMarkKey = "simulatorRootBookmarkData"
}
