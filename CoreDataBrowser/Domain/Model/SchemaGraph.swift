//
//  SchemaGraph.swift
//  CoreDataBrowser
//
//  Created by Turdesan Csaba on 2026. 09. 06..
//

import Foundation
import SwiftUI

struct SchemaGraph {
    var nodes: [SchemaNode]
    var relationships: [SchemaRelationship]
}

struct SchemaNode: Identifiable {
    let id: UUID
    let name: String
    let fields: [SchemaField]
    let type: DataModelType
}

struct SchemaField: Identifiable {
    let id: UUID
    let name: String
    let type: String
    let isOptional: Bool
    /// Whether this field is actually a to-one relationship foreign key (as opposed to a plain
    /// attribute), so the UI can mark it with a small relationship indicator.
    var isRelationship: Bool = false
}

struct SchemaRelationship: Identifiable {
    let id: UUID
    let sourceNodeID: UUID
    let sourceProperty: String
    let destinationNodeID: UUID
    let destinationProperty: String?
    let cardinality: Cardinality
}

enum Cardinality {
    case one
    case many
}

enum DataModelType {
    case coreData
    case swiftData
    case userDefaults
}
