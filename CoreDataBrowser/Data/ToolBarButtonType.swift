//
//  ToolBarButtonType.swift
//  CoreDataBrowser
//
//  Created by Turdesan Csaba on 2026. 09. 08..
//

import Foundation
import SwiftUI

enum ToolBarButtonType: CaseIterable, Identifiable {
    case refresh
    case schemaGraph
    case settings
    
    var icon: String {
        switch self {
        case .refresh:
            return "arrow.trianglehead.2.clockwise"
        case .schemaGraph:
            return "point.3.connected.trianglepath.dotted"
        case .settings:
            return "gearshape"
        }
    }
    
    var text: String {
        switch self {
        case .refresh:
            return "Refresh"
        case .schemaGraph:
            return "Schema Graph"
        case .settings:
            return "Settings"
        }
    }
    
    var placement: ToolbarItemPlacement {
        switch self {
        case .refresh:
            return .navigation
        case .schemaGraph:
            return .primaryAction
        case .settings:
            return .primaryAction
        }
    }
    var id: String { return self.text }
}
