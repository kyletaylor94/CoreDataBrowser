//
//  SchemaGraphRepository.swift
//  CoreDataBrowser
//
//  Created by Turdesan Csaba on 2026. 09. 11..
//

import Foundation
internal import CoreGraphics

/// Provides the pure layout/geometry computations backing the schema graph canvas: initial node
/// placement, card sizing, and relationship connector routing. Kept separate from the use case so the
/// (business-rule-free) positioning math can be reused/tested independently of how the graph's nodes
/// and relationships were assembled.
protocol SchemaGraphRepository {
    /// The fixed width used for every node card. Keeping this constant (rather than letting cards
    /// size to their content) is what allows the layout math below to guarantee non-overlapping columns.
    var nodeWidth: CGFloat { get }

    /// Computes initial (or preserved) node positions for every node in the given graph, laying nodes
    /// out into rows/columns sized to avoid overlap. Positions already present in `previousPositions`
    /// (keyed by node name) are reused so dragged/laid-out positions survive graph refreshes.
    func initialPositions(for graph: SchemaGraph, preserving previousPositions: [String: CGPoint]) -> [String: CGPoint]

    /// Estimates the rendered height of a node card based on its field count.
    func estimatedHeight(for node: SchemaNode) -> CGFloat

    /// The on-screen frame (position + estimated size) for the node with the given name, used to
    /// anchor relationship connector lines to a card's actual edges rather than just its center.
    func frame(forNodeNamed name: String, in graph: SchemaGraph, positions: [String: CGPoint]) -> CGRect?

    /// The vertical offset (from a node card's top edge) of the row displaying the given field name,
    /// so a relationship connector can leave from the exact row it originates from.
    func fieldRowOffset(fieldName: String, in node: SchemaNode) -> CGFloat

    /// The total size needed to fit every node in the graph, used to size the scrollable canvas.
    func contentSize(for graph: SchemaGraph) -> CGSize

    /// Computes an elbow-routed polyline connecting the exact field row that owns a relationship
    /// (on the source entity) to the edge of the destination entity's card.
    func connectorPoints(for relationship: SchemaRelationship, in graph: SchemaGraph, positions: [String: CGPoint]) -> [CGPoint]?
}

final class SchemaGraphRepositoryImpl: SchemaGraphRepository {

    let nodeWidth: CGFloat = 240
    /// Vertical space occupied by a card's header (name) row, including its divider.
    private let headerHeight: CGFloat = 34
    /// Vertical space occupied by a single field row.
    private let fieldRowHeight: CGFloat = 20
    /// Combined top/bottom card padding not accounted for by the header/field rows.
    private let verticalPadding: CGFloat = 26

    private let columns = 3
    private let columnGap: CGFloat = 80
    private let rowGap: CGFloat = 60

    func initialPositions(for graph: SchemaGraph, preserving previousPositions: [String: CGPoint]) -> [String: CGPoint] {
        let columnStride = nodeWidth + columnGap

        var newPositions: [String: CGPoint] = [:]

        // Group nodes into rows of `columns` and size each row by its tallest node, so entities
        // with more fields (and therefore taller cards) never overlap the row below them.
        var yOffset: CGFloat = 150

        for rowStart in stride(from: 0, to: graph.nodes.count, by: columns) {
            let rowEnd = min(rowStart + columns, graph.nodes.count)
            let rowNodes = graph.nodes[rowStart..<rowEnd]
            let rowHeight = rowNodes.map(estimatedHeight(for:)).max() ?? 160

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
        return newPositions
    }

    func estimatedHeight(for node: SchemaNode) -> CGFloat {
        headerHeight + verticalPadding + CGFloat(max(node.fields.count, 1)) * fieldRowHeight
    }

    func frame(forNodeNamed name: String, in graph: SchemaGraph, positions: [String: CGPoint]) -> CGRect? {
        guard let center = positions[name],
              let node = graph.nodes.first(where: { $0.name == name }) else { return nil }

        let height = estimatedHeight(for: node)
        return CGRect(
            x: center.x - nodeWidth / 2,
            y: center.y - height / 2,
            width: nodeWidth,
            height: height
        )
    }

    func fieldRowOffset(fieldName: String, in node: SchemaNode) -> CGFloat {
        guard let index = node.fields.firstIndex(where: { $0.name.caseInsensitiveCompare(fieldName) == .orderedSame }) else {
            return estimatedHeight(for: node) / 2
        }
        return headerHeight + CGFloat(index) * fieldRowHeight + fieldRowHeight / 2
    }

    func contentSize(for graph: SchemaGraph) -> CGSize {
        guard !graph.nodes.isEmpty else {
            return CGSize(width: 900, height: 600)
        }
        
        let columnStride = nodeWidth + columnGap
        let width = CGFloat(min(columns, graph.nodes.count)) * columnStride + 200

        var height: CGFloat = 150
        for rowStart in stride(from: 0, to: graph.nodes.count, by: columns) {
            let rowEnd = min(rowStart + columns, graph.nodes.count)
            let rowHeight = graph.nodes[rowStart..<rowEnd].map(estimatedHeight(for:)).max() ?? 160
            height += rowHeight + rowGap
        }
        return CGSize(width: width, height: height)
    }

    func connectorPoints(for relationship: SchemaRelationship, in graph: SchemaGraph, positions: [String: CGPoint]) -> [CGPoint]? {
        let nameByNodeID: [UUID: String] = Dictionary(uniqueKeysWithValues: graph.nodes.map { ($0.id, $0.name) })

        guard let sourceName = nameByNodeID[relationship.sourceNodeID],
              let destinationName = nameByNodeID[relationship.destinationNodeID],
              let sourceNode = graph.nodes.first(where: { $0.name == sourceName }),
              let sourceFrame = frame(forNodeNamed: sourceName, in: graph, positions: positions),
              let destinationFrame = frame(forNodeNamed: destinationName, in: graph, positions: positions) else { return nil }

        let rowOffset = fieldRowOffset(fieldName: relationship.sourceProperty, in: sourceNode)
        let sourceY = sourceFrame.minY + rowOffset
        let goesRight = destinationFrame.midX >= sourceFrame.midX
        let sourcePoint = CGPoint(x: goesRight ? sourceFrame.maxX : sourceFrame.minX, y: sourceY)

        let verticalGap = destinationFrame.midY - sourceFrame.midY
        let isSameRow = abs(verticalGap) < max(sourceFrame.height, destinationFrame.height) / 2

        if isSameRow {
            return connectorPointsForSameRow(sourcePoint: sourcePoint, destinationFrame: destinationFrame, goesRight: goesRight)
        } else {
            return connectorPointsForDifferentRows(sourcePoint: sourcePoint, destinationFrame: destinationFrame, verticalGap: verticalGap)
        }
    }
        
    private func connectorPointsForSameRow(sourcePoint: CGPoint, destinationFrame: CGRect, goesRight: Bool) -> [CGPoint] {
        let destinationPoint = CGPoint(
            x: goesRight ? destinationFrame.minX : destinationFrame.maxX,
            y: destinationFrame.midY
        )

        let midX = (sourcePoint.x + destinationPoint.x) / 2
        return [
            sourcePoint,
            CGPoint(x: midX, y: sourcePoint.y),
            CGPoint(x: midX, y: destinationPoint.y),
            destinationPoint
        ]
    }

    private func connectorPointsForDifferentRows(sourcePoint: CGPoint, destinationFrame: CGRect, verticalGap: CGFloat) -> [CGPoint] {
        let destinationPoint = CGPoint(
            x: destinationFrame.midX,
            y: verticalGap > 0
                ? destinationFrame.minY
                : destinationFrame.maxY
        )

        let midY = (sourcePoint.y + destinationPoint.y) / 2
        return [
            sourcePoint,
            CGPoint(x: sourcePoint.x, y: midY),
            CGPoint(x: destinationPoint.x, y: midY),
            destinationPoint
        ]
    }
}
