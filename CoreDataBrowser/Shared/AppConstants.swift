//
//  AppConstants.swift
//  CoreDataBrowser
//
//  Created by Turdesan Csaba on 2026. 03. 12..
//

import Foundation
import SwiftUI

enum AppConstants {
    static let runtimeReplacing = "com.apple.CoreSimulator.SimRuntime."
    static let questionMark = "?"
    static let bytes = "bytes"
    static let error = "Error!"
    static let unknownError = "Unknown Error"
    static let ok = "OK"
    static let emptyString = ""
    
    enum DataSourceName {
        static let coreData = "CoreData"
        static let swiftData = "SwiftData"
        static let userDefaults = "UserDefaults"
    }
    
    enum DataSourceIcons {
        static let coreData = "cylinder.split.1x2"
        static let swiftData = "externaldrive.badge.checkmark"
        static let userDefaults = "gearshape.2"
    }
    
    enum SimulatorStrings {
        static let booted = "Booted"
        static let name = "name"
        static let na = "N/A"
        static let runtime = "runtime"
        static let unknown = "Unknown"
        static let state = "state"
        static let shutdown = "Shutdown"
        static let cannotAccessDeviceFolder = "Could not access the Simulator devices folder."
        static let cannotReadPList = "Could not read the simulator's device.plist file."
        static let invalidPListFormat = "The device.plist file has an invalid format."
        static let accessNotGranted = "Access to the Simulator devices folder was not granted. Please select the folder to continue."
        static let selectedSpecificSimulatorFolder = "You selected a specific simulator's folder instead of the top-level “Devices” folder that contains all of them. Please grant access again and select “Devices” itself (Library/Developer/CoreSimulator/Devices), not one of the folders inside it."
        static let simulatorAccessNeeded = "Simulator Access Needed"
        static let noSimulatorsFound = "No Simulators Found"
        static let noSimulatorsFoundSubtitle = "No simulator devices are available. Please check your Xcode installation or start a simulator."
        static let unknownError = "An unknown error occurred."
    }
    
    enum SimulatorIcons {
        static let lock = "lock.fill"
        static let iphoneSlash = "iphone.slash"
    }
    
    /// The set of storage/attribute type names this app can encounter that are actually declared by
    /// Apple (Foundation attribute types, or raw SQLite storage classes Core Data maps them to).
    static let systemDeclaredTypeNames: Set<String> = [
        "STRING", "INT", "INT16", "INT32", "INT64", "DECIMAL", "DOUBLE", "FLOAT", "BOOL", "BOOLEAN",
        "DATE", "DATA", "UUID", "URL", "TRANSFORMABLE", "OBJECTID",
        "INTEGER", "VARCHAR", "TIMESTAMP", "BLOB", "TEXT", "DATETIME", "NUMERIC", "CHAR", "CLOB", "REAL"
    ]
    
    /// A curated list of common, generic word fragments used to greedily split a fully-uppercased,
    /// delimiter-less identifier (e.g. Core Data's SQLite column/table names, which are always
    /// uppercased) back into a readable `camelCase` form. Only generic/common words are included
    /// (not app-specific vocabulary) so this works reasonably well across different Core Data models.
    static let camelCaseWordFragments: [String] = [
        "Entity", "Description", "Duration", "Currency", "Quantity", "Category", "Settings",
        "Content", "Address", "Config", "Object", "Status", "Active", "Custom", "Height",
        "Length", "Number", "Amount", "Default", "Enabled", "Visible", "Parent", "Source",
        "Target", "Weight", "Version", "Percent", "Ratio", "Width", "Price", "Value", "Title",
        "Image", "Color", "Count", "Array", "State", "Owner", "Child", "Group", "Start", "Total",
        "Index", "Email", "Phone", "Text", "Time", "Rate", "Size", "Path", "Code", "Item", "Info",
        "Meta", "List", "Type", "Data", "Name", "Icon", "Unit", "End", "Min", "Max", "Sum", "Key",
        "Url", "Id", "At", "On", "In", "To"
    ]
    
    enum AppFolderStrings {
        static let title = "Would you like to change the app folder paths?"
        static let resetDefaults = "Reset to Defaults"
        static let cancel = "Cancel"
        static let save = "Save"
    }
    
    enum PathRowIcon {
        static let folder = "folder"
    }
    
    enum PathTypeStrings {
        static let simulator = "Simulators Path"
        static let coreData = "CoreData Path"
        static let swiftData = "SwiftData Path"
        static let userDefaults = "UserDefaults Path"
    }
    
    enum UserDefaultDetailSheetStrings {
        static let value = "Value"
        static let navTitle = "Value Details"
        static let done = "Done"
    }
    
    enum DBMoreDetailSheetStrings {
        static let navTitle = "Row Details"
        static let helpText = "Dismiss the row details view"
        static let done = "Done"
    }
    
    enum SourceHeaderStrings {
        static let remove = "Remove from the board"
        static let copied = "Copied"
        static let copyPath = "Copy Path"
        static let exportJson = "Export JSON"
        static let exportCsv = "Export CSV"
    }
    
    enum SourceHeaderIcons {
        static let checkmark = "checkmark"
        static let docOnDoc = "doc.on.doc"
        static let exportJson = "curlybraces.square"
        static let exportCsv = "tablecells"
    }
    
    enum SchemaGraphStrings {
        static let resetZoom = "Reset Zoom"
        static let zoomOut = "Zoom Out"
        static let zoomIn = "Zoom In"
        static let dataNotAvailableTitle = "No schema data available"
        static let dataNotAvailableSubtitle = "Select a booted simulator, then choose a CoreData or SwiftData data source to visualize its entities and relationships."
        static let schemaGraph = "Schema Graph"
        static let coreData = "CoreData"
        static let swiftData = "SwiftData"
        static let close = "Close"
    }
    
    enum SchemaGraphIcons {
        static let resetZoom = "arrow.trianglehead.counterclockwise"
        static let zoomOut = "minus.magnifyingglass"
        static let zoomIn = "plus.magnifyingglass"
        static let schemaGraph = "point.3.connected.trianglepath.dotted"
        static let dismiss = "xmark.circle.fill"
    }
    
    enum FileSizeStringFormat {
        static let mb = "%.2f MB"
        static let kb = "%.2f KB"
    }
    
    enum SchemaNodeIcons {
        static let arrowshapeTurnUpRightFill = "arrowshape.turn.up.right.fill"
    }
    
    enum Colors {
        static let nodeEntityColor = Color("nodeEntityColor")
        static let nodeEntityBackgroundColor = Color("nodeEntityBackgroundColor")
        static let nodeAttributeColor = Color("nodeAttributeColor")
        static let nodeSwiftTypeColor = Color("nodeSwiftTypeColor")
        static let nodeCustomObjectColor = Color("nodeCustomObjectColor")
        static let nodeAttributeBackgroundColor = Color("nodeAttributeBackgroundColor")
    }
    
    enum ToolBarStrings {
        static let refresh = "Refresh all data"
        static let schemaGraph = "Toggle schema graph presentation"
        static let settings = "Open settings"
    }
    
    enum ToolBarIcons {
        static let refresh = "arrow.trianglehead.2.clockwise"
        static let schemaGraph = "point.3.connected.trianglepath.dotted"
        static let settings = "gearshape"
    }
}

enum UserDefaultsKeys {
    static let simulatorPath = "simulatorPath"
    static let coreDataPath = "coreDataPath"
    static let swiftDataPath = "swiftDataPath"
    static let userDefaultsPath = "userDefaultsPath"
}
