//
//  SchemaGraphViewModel.swift
//  CoreDataBrowser
//
//  Created by Turdesan Csaba on 2026. 09. 06..
//

import Foundation
import CoreData
internal import CoreGraphics
import Observation
import SwiftUI

enum GraphViewType {
    case coreData
    case swiftData
}

@Observable
@MainActor
final class SchemaGraphViewModel {

    private(set) var graph: SchemaGraph

    /// Node positions keyed by the node's stable `name` (rather than its `id`, which is regenerated
    /// on every rebuild) so dragged/laid-out positions survive graph refreshes without nodes jumping
    /// around or piling up on top of each other.
    var nodePositions: [String: CGPoint] = [:]

    /// The node currently highlighted in the graph, typically the entity the user has selected
    /// in the CoreData table list. `nil` means no particular node is focused.
    private(set) var focusedNodeID: UUID?
    
    var isSchemaGraphPresented: Bool = false
    let connectorPalette: [Color] = [.blue, .teal, .purple, .orange, .pink, .indigo, .mint, .cyan]
    
    /// Maps a node's transient `id` (regenerated on every graph rebuild) back to its stable `name`,
    /// which is what `nodePositions` is keyed by.
    private var nameByNodeID: [UUID: String] {
        Dictionary(uniqueKeysWithValues: graph.nodes.map { ($0.id, $0.name) })
    }
    
    var disableGraphView: Bool {
        return graph.nodes.isEmpty || graph.relationships.isEmpty
    }
    
    var selectedGraphViewType: GraphViewType = .coreData
    
    var zoomScale: CGFloat = 1.0
    let minZoom: CGFloat = 0.25
    let maxZoom: CGFloat = 2.0
    let zoomStep: CGFloat = 0.1
    
    init(entities: [NSEntityDescription]) {
        self.graph = Self.buildGraph(from: entities)
        setupInitialPositions()
    }

    /// Builds the graph directly from the SQLite-backed `DBDataTable` entities that the app already
    /// discovers on disk, using their real foreign key constraints (see `DBForeignKey`) to draw
    /// relationships. This lets the graph reflect the actual data without needing access to a
    /// compiled `.momd` Core Data model.
    /// - Parameters:
    ///   - tables: The entity tables to visualize (typically `DBDataViewModel.coreDataTables`).
    ///   - relationships: Foreign keys for each table, keyed by table name.
    init(tables: [DBDataTable], relationships: [String: [DBForeignKey]] = [:]) {
        self.graph = Self.buildGraph(tables: tables, relationships: relationships)
        setupInitialPositions()
    }

    func zoomIn() {
        zoomScale = min(zoomScale + zoomStep, maxZoom)
    }

    func zoomOut() {
        zoomScale = max(zoomScale - zoomStep, minZoom)
    }

    func resetZoom() {
        zoomScale = 1.0
    }
    
    /// Rebuilds the graph from the current set of Core Data tables and their foreign key relationships.
    /// Existing node positions are preserved where possible so the layout doesn't jump around on refresh.
    /// - Parameters:
    ///   - tables: The entity tables to visualize.
    ///   - relationships: Foreign keys for each table, keyed by table name.
    ///   - focusedTableName: The name of the table (if any) that should be highlighted, e.g. the entity
    ///     the user just selected in the CoreData table list.
    func update(tables: [DBDataTable], relationships: [String: [DBForeignKey]], focusedTableName: String? = nil) {
        let previousPositions = nodePositions
        graph = Self.buildGraph(tables: tables, relationships: relationships)
        setupInitialPositions(preserving: previousPositions)
        focusedNodeID = focusedTableName.flatMap { name in
            let displayName = FormattingHelper.pascalCased(from: FormattingHelper.removeZPrefix(from: name))
            return graph.nodes.first(where: { $0.name == displayName })?.id
        }
    }

    /// Highlights the node matching the given raw table name (e.g. `"ZFRUITENTITY"`) without rebuilding
    /// the whole graph. The name is normalized the same way node names are displayed before matching.
    func focusNode(named tableName: String?) {
        focusedNodeID = tableName.flatMap { name in
            let displayName = FormattingHelper.pascalCased(from: FormattingHelper.removeZPrefix(from: name))
            return graph.nodes.first(where: { $0.name == displayName })?.id
        }
    }

    /// Maps a raw SQLite storage type name to a friendlier, Swift-like display name (e.g. `VARCHAR`
    /// becomes `String`, `INTEGER` becomes `Int`), then normalizes the casing so system types always
    /// read like Swift type names (a capital first letter, lowercase afterwards, e.g. `Float`, `Date`).
    private static func displayTypeName(for rawType: String) -> String {
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
    
    /// Capitalizes only the first letter of a string, lowercasing the rest (e.g. `"FLOAT"` -> `"Float"`,
    /// `"String"` -> `"String"`).
    private static func capitalizeFirstLetterOnly(_ value: String) -> String {
        guard let first = value.first else { return value }
        return first.uppercased() + value.dropFirst().lowercased()
    }

    private static func buildGraph(tables: [DBDataTable], relationships: [String: [DBForeignKey]]) -> SchemaGraph {
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
                let destinationEntityName = FormattingHelper.pascalCased(
                    from: FormattingHelper.removeZPrefix(from: foreignKey.destinationTable)
                )
                destinationEntityNameByColumn[cleanColumn] = destinationEntityName
            }

            let fields = table.columns.enumerated().map { index, column -> SchemaField in
                let cleanName = FormattingHelper.removeZPrefix(from: column)
                let upperCleanName = cleanName.uppercased()
                let isRelationship = relationshipColumns.contains(upperCleanName)
                let rawType = index < table.types.count ? table.types[index] : ""
                let isOptional = index < table.isOptional.count ? table.isOptional[index] : false
                let type = isRelationship
                    ? (destinationEntityNameByColumn[upperCleanName] ?? displayTypeName(for: rawType))
                    : displayTypeName(for: rawType)
                return SchemaField(
                    id: UUID(),
                    name: FormattingHelper.camelCased(from: cleanName),
                    type: type,
                    isOptional: isOptional,
                    isRelationship: isRelationship
                )
            }
            nodes.append(
                SchemaNode(
                    id: nodeID,
                    name: FormattingHelper.pascalCased(from: FormattingHelper.removeZPrefix(from: table.name)),
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

    private static func buildGraph(from entities: [NSEntityDescription]) -> SchemaGraph {
        var nodes: [SchemaNode] = []
        var relationships: [SchemaRelationship] = []
        var nodeIDs: [String: UUID] = [:]

        // MARK: Nodes
        for entity in entities {
            guard let name = entity.name else { continue }
            let nodeID = UUID()
            nodeIDs[name] = nodeID

            let fields = entity.attributesByName.values.map { attribute in
                SchemaField(
                    id: UUID(),
                    name: attribute.name,
                    type: attributeTypeName(attribute.attributeType),
                    isOptional: attribute.isOptional
                )
            }
            
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

                relationships.append(
                    SchemaRelationship(
                        id: UUID(),
                        sourceNodeID: sourceNodeID,
                        sourceProperty: relationship.name,
                        destinationNodeID: destinationNodeID,
                        destinationProperty:relationship.inverseRelationship?.name,
                        cardinality: cardinality
                    )
                )
            }
        }
        return SchemaGraph(nodes: nodes, relationships: relationships)
    }

    // MARK: Positions

    /// The fixed width used for every node card. Keeping this constant (rather than letting cards
    /// size to their content) is what allows the layout math below to guarantee non-overlapping columns.
    static let nodeWidth: CGFloat = 240
    /// Vertical space occupied by a card's header (name) row, including its divider.
    private static let headerHeight: CGFloat = 34
    /// Vertical space occupied by a single field row.
    private static let fieldRowHeight: CGFloat = 20
    /// Combined top/bottom card padding not accounted for by the header/field rows.
    private static let verticalPadding: CGFloat = 26

    private func setupInitialPositions(preserving previousPositions: [String: CGPoint] = [:]) {
        let columns = 3

        let columnGap: CGFloat = 80
        let rowGap: CGFloat = 60
        let columnStride = Self.nodeWidth + columnGap

        var newPositions: [String: CGPoint] = [:]

        // Group nodes into rows of `columns` and size each row by its tallest node, so entities
        // with more fields (and therefore taller cards) never overlap the row below them.
        var yOffset: CGFloat = 150

        for rowStart in stride(from: 0, to: graph.nodes.count, by: columns) {
            let rowEnd = min(rowStart + columns, graph.nodes.count)
            let rowNodes = graph.nodes[rowStart..<rowEnd]
            let rowHeight = rowNodes.map(Self.estimatedHeight(for:)).max() ?? 160

            for (offset, node) in rowNodes.enumerated() {
                if let existing = previousPositions[node.name] {
                    newPositions[node.name] = existing
                    continue
                }

                newPositions[node.name] = CGPoint(
                    x: CGFloat(offset) * columnStride + 180,
                    y: yOffset + rowHeight / 2
                )
            }
            yOffset += rowHeight + rowGap
        }
        nodePositions = newPositions
    }

    /// Estimates the rendered height of a node card based on its field count, so rows can be spaced
    /// far enough apart to avoid vertical overlap regardless of how many attributes an entity has.
    private static func estimatedHeight(for node: SchemaNode) -> CGFloat {
        headerHeight + verticalPadding + CGFloat(max(node.fields.count, 1)) * fieldRowHeight
    }

    /// The on-screen frame (position + estimated size) for the node with the given name, used to
    /// anchor relationship connector lines to a card's actual edges rather than just its center.
    func frame(forNodeNamed name: String) -> CGRect? {
        guard let center = nodePositions[name],
              let node = graph.nodes.first(where: { $0.name == name }) else {
            return nil
        }
        
        let height = Self.estimatedHeight(for: node)
        return CGRect(
            x: center.x - Self.nodeWidth / 2,
            y: center.y - height / 2,
            width: Self.nodeWidth,
            height: height
        )
    }

    /// The vertical offset (from a node card's top edge) of the row displaying the given field name,
    /// so a relationship connector can leave from the exact row it originates from, just like Xcode's
    /// Model Diagram. Falls back to the vertical center of the card if the field can't be found.
    static func fieldRowOffset(fieldName: String, in node: SchemaNode) -> CGFloat {
        guard let index = node.fields.firstIndex(where: { $0.name.caseInsensitiveCompare(fieldName) == .orderedSame }) else {
            return estimatedHeight(for: node) / 2
        }
        return headerHeight + CGFloat(index) * fieldRowHeight + fieldRowHeight / 2
    }

    /// The total size needed to fit every node in the graph, used to size the scrollable canvas so
    /// it never clips or forces entities to be squeezed together.
    func contentSize() -> CGSize {
        guard !graph.nodes.isEmpty else {
            return CGSize(width: 900, height: 600)
        }
        let columns = 3
        let columnGap: CGFloat = 80
        let rowGap: CGFloat = 60
        let columnStride = Self.nodeWidth + columnGap

        let width = CGFloat(min(columns, graph.nodes.count)) * columnStride + 200

        var height: CGFloat = 150
        for rowStart in stride(from: 0, to: graph.nodes.count, by: columns) {
            let rowEnd = min(rowStart + columns, graph.nodes.count)
            let rowHeight = graph.nodes[rowStart..<rowEnd].map(Self.estimatedHeight(for:)).max() ?? 160
            height += rowHeight + rowGap
        }
        return CGSize(width: width, height: height)
    }

    func moveNode(_ name: String, to position: CGPoint) {
        nodePositions[name] = position
    }

    // MARK: Helpers
    private static func attributeTypeName(_ type: NSAttributeType) -> String {
        switch type {
        case .undefinedAttributeType:
            return "Undefined"

        case .integer16AttributeType:
            return "Int16"

        case .integer32AttributeType:
            return "Int32"

        case .integer64AttributeType:
            return "Int64"

        case .decimalAttributeType:
            return "Decimal"

        case .doubleAttributeType:
            return "Double"

        case .floatAttributeType:
            return "Float"

        case .stringAttributeType:
            return "String"

        case .booleanAttributeType:
            return "Bool"

        case .dateAttributeType:
            return "Date"

        case .binaryDataAttributeType:
            return "Data"

        case .UUIDAttributeType:
            return "UUID"

        case .URIAttributeType:
            return "URL"

        case .transformableAttributeType:
            return "Transformable"

        case .objectIDAttributeType:
            return "ObjectID"

        case .compositeAttributeType:
            return "Composite"
        @unknown default:
            return "Unknown"
        }
    }
    
    
    
    /// Computes an elbow-routed polyline connecting the exact field row that owns a relationship
    /// (on the source entity) to the edge of the destination entity's card.
    func connectorPoints(for relationship: SchemaRelationship) -> [CGPoint]? {
        guard let sourceName = nameByNodeID[relationship.sourceNodeID],
              let destinationName = nameByNodeID[relationship.destinationNodeID],
              let sourceNode = graph.nodes.first(where: { $0.name == sourceName }),
              let sourceFrame = frame(forNodeNamed: sourceName),
              let destinationFrame = frame(forNodeNamed: destinationName) else { return nil }

        let rowOffset = SchemaGraphViewModel.fieldRowOffset(fieldName: relationship.sourceProperty, in: sourceNode)
        let sourceY = sourceFrame.minY + rowOffset
        let goesRight = destinationFrame.midX >= sourceFrame.midX
        let sourcePoint = CGPoint(x: goesRight ? sourceFrame.maxX : sourceFrame.minX, y: sourceY)

        let verticalGap = destinationFrame.midY - sourceFrame.midY
        let sameRow = abs(verticalGap) < max(sourceFrame.height, destinationFrame.height) / 2

        if sameRow {
            // Roughly the same row: connect edge-to-edge with a single horizontal jog.
            let destX = goesRight ? destinationFrame.minX : destinationFrame.maxX
            let destinationPoint = CGPoint(x: destX, y: destinationFrame.midY)
            let midX = (sourcePoint.x + destinationPoint.x) / 2
            return [
                sourcePoint,
                CGPoint(x: midX, y: sourcePoint.y),
                CGPoint(x: midX, y: destinationPoint.y),
                destinationPoint
            ]
        } else {
            // Different rows: drop/rise from the source's side edge, then travel into the
            // destination's top or bottom edge.
            let destY = verticalGap > 0 ? destinationFrame.minY : destinationFrame.maxY
            let destinationPoint = CGPoint(x: destinationFrame.midX, y: destY)
            let midY = (sourcePoint.y + destinationPoint.y) / 2
            return [
                sourcePoint,
                CGPoint(x: sourcePoint.x, y: midY),
                CGPoint(x: destinationPoint.x, y: midY),
                destinationPoint
            ]
        }
    }
}
