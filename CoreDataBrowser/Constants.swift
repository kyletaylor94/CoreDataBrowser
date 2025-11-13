//
//  Constants.swift
//  CoreDataBrowser
//
//  Created by Turdesan Csaba on 2025. 11. 10..
//

import Foundation

class Constants {
    static let shared = Constants()
    
    let SIMULATOR_PATH = "Library/Developer/CoreSimulator/Devices"
    let SIMULATOR_APPS_PATH = "data/Containers/Data/Application"
    
    let excludedTables = ["Z_METADATA", "Z_PRIMARYKEY", "Z_MODELCACHE"]
    let excludedColumns = ["Z_PK", "Z_ENT", "Z_OPT"]
    
    
    //Notification names
    let tableDidRefresh = "tableDidRefresh"
    let userDefaultsTableDidRefresh = "userDefaultsTableDidRefresh"
}
