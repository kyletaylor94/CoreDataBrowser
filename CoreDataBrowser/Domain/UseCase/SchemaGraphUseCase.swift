//
//  SchemaGraphUseCase.swift
//  CoreDataBrowser
//
//  Created by Turdesan Csaba on 2026. 09. 11..
//

import Foundation
import CoreData
internal import CoreGraphics

protocol SchemaGraphUseCase {
    func displayTypeName(for rawType: String) -> String
    func displayTypeName(for attributeType: NSAttributeType) -> String
    func displayEntityName(from rawName: String) -> String
    func displayPropertyName(from rawName: String) -> String
    func fieldMapper(from entity: NSEntityDescription) -> [SchemaField]

    /// Builds a `SchemaGraph` directly from the SQLite-backed `DBDataTable` entities that the app
    /// already discovers on disk, using their real foreign key constraints (see `DBForeignKey`) to
    /// draw relationships.
    /// - Parameters:
    ///   - tables: The entity tables to visualize (typically `DBDataViewModel.coreDataTables`).
    ///   - relationships: Foreign keys for each table, keyed by table name.
    func buildGraph(tables: [DBDataTable], relationships: [String: [DBForeignKey]]) -> SchemaGraph

    /// Builds a `SchemaGraph` from a compiled Core Data model's entity descriptions.
    func buildGraph(from entities: [NSEntityDescription]) -> SchemaGraph

    /// The fixed width used for every node card.
    var nodeWidth: CGFloat { get }

    /// Computes initial (or preserved) node positions for every node in the given graph.
    func initialPositions(for graph: SchemaGraph, preserving previousPositions: [String: CGPoint]) -> [String: CGPoint]

    /// The on-screen frame (position + estimated size) for the node with the given name.
    func frame(forNodeNamed name: String, in graph: SchemaGraph, positions: [String: CGPoint]) -> CGRect?

    /// The vertical offset (from a node card's top edge) of the row displaying the given field name.
    func fieldRowOffset(fieldName: String, in node: SchemaNode) -> CGFloat

    /// The total size needed to fit every node in the graph.
    func contentSize(for graph: SchemaGraph) -> CGSize

    /// Computes an elbow-routed polyline connecting a relationship's source field row to its
    /// destination entity's card edge.
    func connectorPoints(for relationship: SchemaRelationship, in graph: SchemaGraph, positions: [String: CGPoint]) -> [CGPoint]?

    /// Resolves the node id matching the given raw table/entity name (e.g. `"ZFRUITENTITY"`), for
    /// highlighting the entity the user has selected elsewhere in the app. The name is normalized the
    /// same way node names are displayed before matching.
    func focusedNodeID(forRawName rawName: String?, in graph: SchemaGraph) -> UUID?
}

class SchemaGraphUseCaseImpl: SchemaGraphUseCase {

    private let repository: SchemaGraphRepository

    init(repository: SchemaGraphRepository) {
        self.repository = repository
    }

    var nodeWidth: CGFloat {
        repository.nodeWidth
    }

    /// Maps a raw SQLite storage type name to a friendlier, Swift-like display name (e.g. `VARCHAR`
    /// becomes `String`, `INTEGER` becomes `Int`), then normalizes the casing so system types always
    /// read like Swift type names (a capital first letter, lowercase afterwards, e.g. `Float`, `Date`).
    func displayTypeName(for rawType: String) -> String {
        let normalized: String
        switch rawType.uppercased() {
        case "VARCHAR":
            normalized = "String"
        case "INTEGER":
            normalized = "Int"
        default:
            normalized = rawType
        }
        return capitalizeFirstLetterOnly(normalized)
    }
    
    func displayTypeName(for attributeType: NSAttributeType) -> String {
         switch attributeType {
         case .undefinedAttributeType:
             "Undefined"
         case .integer16AttributeType:
             "Int16"
         case .integer32AttributeType:
             "Int32"
         case .integer64AttributeType:
             "Int64"
         case .decimalAttributeType:
             "Decimal"
         case .doubleAttributeType:
             "Double"
         case .floatAttributeType:
             "Float"
         case .stringAttributeType:
             "String"
         case .booleanAttributeType:
             "Bool"
         case .dateAttributeType:
             "Date"
         case .binaryDataAttributeType:
             "Data"
         case .UUIDAttributeType:
             "UUID"
         case .URIAttributeType:
             "URL"
         case .transformableAttributeType:
             "Transformable"
         case .objectIDAttributeType:
             "ObjectID"
         case .compositeAttributeType:
             "Composite"
         @unknown default:
             "Unknown"
         }
     }
    
    func displayEntityName(from rawName: String) -> String {
        FormattingHelper.pascalCased(from: FormattingHelper.removeZPrefix(from: rawName))
    }
    
    func displayPropertyName(from rawName: String) -> String {
        FormattingHelper.camelCased(from: FormattingHelper.removeZPrefix(from: rawName))
    }

    // MARK: Graph building

    func buildGraph(tables: [DBDataTable], relationships: [String: [DBForeignKey]]) -> SchemaGraph {
        var nodes: [SchemaNode] = []
        var relationshipEdges: [SchemaRelationship] = []
        var nodeIDs: [String: UUID] = [:]

        // Column names (cleaned, uppercased) that act as relationship foreign keys, grouped by table,
        // so we can flag the matching fields below.
        let relationshipColumnsByTable: [String: Set<String>] = relationships.mapValues { foreignKeys in
            Set(foreignKeys.map { FormattingHelper.removeZPrefix(from: $0.column).uppercased() })
        }

        // MARK: Nodes

        for table in tables {
            let nodeID = UUID()
            nodeIDs[table.name] = nodeID

            let relationshipColumns = relationshipColumnsByTable[table.name] ?? []

            // For relationship (foreign key) columns, the field's "type" should show the destination
            // entity's name (a custom object) rather than the raw INTEGER storage type it's physically
            // stored as — otherwise a relationship like `basket: Int?` would misleadingly look like a
            // plain numeric attribute instead of a link to another entity.
            var destinationEntityNameByColumn: [String: String] = [:]
            for foreignKey in relationships[table.name] ?? [] {
                let cleanColumn = FormattingHelper.removeZPrefix(from: foreignKey.column).uppercased()
                let destinationEntityName = displayEntityName(from: foreignKey.destinationTable)
                destinationEntityNameByColumn[cleanColumn] = destinationEntityName
            }

            let fields = table.columns.enumerated().map { index, column -> SchemaField in
                let cleanName = FormattingHelper.removeZPrefix(from: column)
                let upperCleanName = cleanName.uppercased()
                let isRelationship = relationshipColumns.contains(upperCleanName)
                let rawType = index < table.types.count ? table.types[index] : ""
                let isOptional = index < table.isOptional.count ? table.isOptional[index] : false
                let type = isRelationship ? (destinationEntityNameByColumn[upperCleanName] ?? displayTypeName(for: rawType)) : displayTypeName(for: rawType)
                return SchemaField(
                    id: UUID(),
                    name: displayPropertyName(from: column),
                    type: type,
                    isOptional: isOptional,
                    isRelationship: isRelationship
                )
            }
            nodes.append(
                SchemaNode(
                    id: nodeID,
                    name: displayEntityName(from: table.name),
                    fields: fields,
                    type: .coreData
                )
            )
        }

        // MARK: Relationships
        for table in tables {
            guard let sourceNodeID = nodeIDs[table.name],
                  let foreignKeys = relationships[table.name] else { continue }

            for foreignKey in foreignKeys {
                guard let destinationNodeID = nodeIDs[foreignKey.destinationTable] else { continue }

                relationshipEdges.append(
                    SchemaRelationship(
                        id: UUID(),
                        sourceNodeID: sourceNodeID,
                        sourceProperty: FormattingHelper.removeZPrefix(from: foreignKey.column),
                        destinationNodeID: destinationNodeID,
                        destinationProperty: foreignKey.destinationColumn,
                        cardinality: .one
                    )
                )
            }
        }
        return SchemaGraph(nodes: nodes, relationships: relationshipEdges)
    }
    
    func fieldMapper(from entity: NSEntityDescription) -> [SchemaField] {
        return entity.attributesByName.values.map { attribute in
            SchemaField(
                id: UUID(),
                name: attribute.name,
                type: displayTypeName(for: attribute.attributeType),
                isOptional: attribute.isOptional
            )
        }
    }

    func buildGraph(from entities: [NSEntityDescription]) -> SchemaGraph {
        var nodes: [SchemaNode] = []
        var relationships: [SchemaRelationship] = []
        var nodeIDs: [String: UUID] = [:]

        // MARK: Nodes
        for entity in entities {
            guard let name = entity.name else { continue }
            let nodeID = UUID()
            nodeIDs[name] = nodeID

            let fields = fieldMapper(from: entity)
            
            let node = SchemaNode(
                id: nodeID,
                name: name,
                fields: fields,
                type: .coreData
            )

            nodes.append(node)
        }

        // MARK: Relationships
        for entity in entities {
            guard let sourceName = entity.name,
                  let sourceNodeID = nodeIDs[sourceName] else { continue }

            for relationship in entity.relationshipsByName.values {
                guard let destinationEntity = relationship.destinationEntity,
                      let destinationName = destinationEntity.name,
                      let destinationNodeID = nodeIDs[destinationName] else { continue }

                let cardinality: Cardinality = relationship.isToMany ? .many : .one
                let relationship = SchemaRelationship(
                    id: UUID(),
                    sourceNodeID: sourceNodeID,
                    sourceProperty: relationship.name,
                    destinationNodeID: destinationNodeID,
                    destinationProperty: relationship.inverseRelationship?.name,
                    cardinality: cardinality
                )
                relationships.append(relationship)
            }
        }
        return SchemaGraph(nodes: nodes, relationships: relationships)
    }

    // MARK: Layout (delegated to repository)

    func initialPositions(for graph: SchemaGraph, preserving previousPositions: [String: CGPoint]) -> [String: CGPoint] {
        repository.initialPositions(for: graph, preserving: previousPositions)
    }

    func frame(forNodeNamed name: String, in graph: SchemaGraph, positions: [String: CGPoint]) -> CGRect? {
        repository.frame(forNodeNamed: name, in: graph, positions: positions)
    }

    func fieldRowOffset(fieldName: String, in node: SchemaNode) -> CGFloat {
        repository.fieldRowOffset(fieldName: fieldName, in: node)
    }

    func contentSize(for graph: SchemaGraph) -> CGSize {
        repository.contentSize(for: graph)
    }

    func connectorPoints(for relationship: SchemaRelationship, in graph: SchemaGraph, positions: [String: CGPoint]) -> [CGPoint]? {
        repository.connectorPoints(for: relationship, in: graph, positions: positions)
    }

    func focusedNodeID(forRawName rawName: String?, in graph: SchemaGraph) -> UUID? {
        rawName.flatMap { name in
            let displayName = displayEntityName(from: name)
            return graph.nodes.first(where: { $0.name == displayName })?.id
        }
    }

    /// Capitalizes only the first letter of a string, lowercasing the rest (e.g. `"FLOAT"` -> `"Float"`,
    /// `"String"` -> `"String"`).
   private func capitalizeFirstLetterOnly(_ value: String) -> String {
        guard let first = value.first else { return value }
        return first.uppercased() + value.dropFirst().lowercased()
    }
}

