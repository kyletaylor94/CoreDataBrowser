//
//  SchemaGraphTests.swift
//  CoreDataBrowserTests
//
//  Created by Turdesan Csaba on 2026. 09. 13..
//

import Testing
import CoreData
internal import CoreGraphics
@testable import CoreDataBrowser

@MainActor
struct SchemaGraphRepositoryTests {

    private func makeNode(name: String, fieldCount: Int) -> SchemaNode {
        SchemaNode(
            id: UUID(),
            name: name,
            fields: (0..<fieldCount).map { SchemaField(id: UUID(), name: "field\($0)", type: "String", isOptional: false) },
            type: .coreData
        )
    }

    @Test("estimatedHeight grows with field count")
    func estimatedHeightGrowsWithFieldCount() {
        let repository = SchemaGraphRepositoryImpl()
        let small = makeNode(name: "Small", fieldCount: 1)
        let large = makeNode(name: "Large", fieldCount: 10)

        #expect(repository.estimatedHeight(for: large) > repository.estimatedHeight(for: small))
    }

    @Test("estimatedHeight treats zero fields the same as one field")
    func estimatedHeightTreatsZeroFieldsAsOne() {
        let repository = SchemaGraphRepositoryImpl()
        let empty = makeNode(name: "Empty", fieldCount: 0)
        let single = makeNode(name: "Single", fieldCount: 1)

        #expect(repository.estimatedHeight(for: empty) == repository.estimatedHeight(for: single))
    }

    @Test("initialPositions lays out every node and preserves existing positions")
    func initialPositionsPreservesExistingPositions() {
        let repository = SchemaGraphRepositoryImpl()
        let nodeA = makeNode(name: "A", fieldCount: 2)
        let nodeB = makeNode(name: "B", fieldCount: 3)
        let graph = SchemaGraph(nodes: [nodeA, nodeB], relationships: [])

        let preserved = CGPoint(x: 999, y: 999)
        let positions = repository.initialPositions(for: graph, preserving: ["A": preserved])

        #expect(positions.count == 2)
        #expect(positions["A"] == preserved)
        #expect(positions["B"] != nil)
        #expect(positions["B"] != preserved)
    }

    @Test("initialPositions places nodes in the same row at the same y, in increasing columns")
    func initialPositionsArrangesNodesInAGrid() {
        let repository = SchemaGraphRepositoryImpl()
        let nodes = (0..<3).map { makeNode(name: "Node\($0)", fieldCount: 2) }
        let graph = SchemaGraph(nodes: nodes, relationships: [])

        let positions = repository.initialPositions(for: graph, preserving: [:])

        let y0 = positions["Node0"]!.y
        let y1 = positions["Node1"]!.y
        let y2 = positions["Node2"]!.y
        #expect(y0 == y1)
        #expect(y1 == y2)

        let x0 = positions["Node0"]!.x
        let x1 = positions["Node1"]!.x
        let x2 = positions["Node2"]!.x
        #expect(x0 < x1)
        #expect(x1 < x2)
    }

    @Test("frame(forNodeNamed:) returns nil for an unknown node")
    func frameReturnsNilForUnknownNode() {
        let repository = SchemaGraphRepositoryImpl()
        let graph = SchemaGraph(nodes: [], relationships: [])
        #expect(repository.frame(forNodeNamed: "Missing", in: graph, positions: [:]) == nil)
    }

    @Test("frame(forNodeNamed:) is centered on the stored position with the fixed node width")
    func frameIsCenteredOnStoredPosition() {
        let repository = SchemaGraphRepositoryImpl()
        let node = makeNode(name: "Node", fieldCount: 2)
        let graph = SchemaGraph(nodes: [node], relationships: [])
        let center = CGPoint(x: 100, y: 200)

        let frame = repository.frame(forNodeNamed: "Node", in: graph, positions: ["Node": center])

        #expect(frame != nil)
        #expect(frame!.width == repository.nodeWidth)
        #expect(frame!.midX == center.x)
        #expect(frame!.midY == center.y)
    }

    @Test("fieldRowOffset increases for later fields")
    func fieldRowOffsetIncreasesForLaterFields() {
        let repository = SchemaGraphRepositoryImpl()
        let node = makeNode(name: "Node", fieldCount: 3)

        let firstOffset = repository.fieldRowOffset(fieldName: "field0", in: node)
        let secondOffset = repository.fieldRowOffset(fieldName: "field1", in: node)

        #expect(secondOffset > firstOffset)
    }

    @Test("fieldRowOffset falls back to the vertical center for an unknown field")
    func fieldRowOffsetFallsBackForUnknownField() {
        let repository = SchemaGraphRepositoryImpl()
        let node = makeNode(name: "Node", fieldCount: 3)

        let offset = repository.fieldRowOffset(fieldName: "doesNotExist", in: node)

        #expect(offset == repository.estimatedHeight(for: node) / 2)
    }

    @Test("fieldRowOffset matches field names case-insensitively")
    func fieldRowOffsetIsCaseInsensitive() {
        let repository = SchemaGraphRepositoryImpl()
        let node = makeNode(name: "Node", fieldCount: 3)

        let lower = repository.fieldRowOffset(fieldName: "field1", in: node)
        let upper = repository.fieldRowOffset(fieldName: "FIELD1", in: node)

        #expect(lower == upper)
    }

    @Test("contentSize falls back to a default size for an empty graph")
    func contentSizeFallsBackForEmptyGraph() {
        let repository = SchemaGraphRepositoryImpl()
        let size = repository.contentSize(for: SchemaGraph(nodes: [], relationships: []))
        #expect(size == CGSize(width: 900, height: 600))
    }

    @Test("contentSize grows taller as more rows of nodes are added")
    func contentSizeGrowsWithMoreRows() {
        let repository = SchemaGraphRepositoryImpl()
        let threeNodes = (0..<3).map { makeNode(name: "N\($0)", fieldCount: 2) }
        let sixNodes = (0..<6).map { makeNode(name: "N\($0)", fieldCount: 2) }

        let smallSize = repository.contentSize(for: SchemaGraph(nodes: threeNodes, relationships: []))
        let largeSize = repository.contentSize(for: SchemaGraph(nodes: sixNodes, relationships: []))

        #expect(largeSize.height > smallSize.height)
    }

    @Test("connectorPoints returns nil when the relationship references a missing node")
    func connectorPointsReturnsNilForMissingNode() {
        let repository = SchemaGraphRepositoryImpl()
        let node = makeNode(name: "Source", fieldCount: 2)
        let graph = SchemaGraph(nodes: [node], relationships: [])
        let relationship = SchemaRelationship(
            id: UUID(),
            sourceNodeID: node.id,
            sourceProperty: "field0",
            destinationNodeID: UUID(),
            destinationProperty: nil,
            cardinality: .one
        )

        let points = repository.connectorPoints(for: relationship, in: graph, positions: [node.name: .zero])
        #expect(points == nil)
    }

    @Test("connectorPoints returns a routed polyline between two valid nodes")
    func connectorPointsReturnsPolylineBetweenValidNodes() {
        let repository = SchemaGraphRepositoryImpl()
        let source = makeNode(name: "Source", fieldCount: 2)
        let destination = makeNode(name: "Destination", fieldCount: 2)
        let graph = SchemaGraph(nodes: [source, destination], relationships: [])
        let relationship = SchemaRelationship(
            id: UUID(),
            sourceNodeID: source.id,
            sourceProperty: "field0",
            destinationNodeID: destination.id,
            destinationProperty: nil,
            cardinality: .one
        )
        let positions: [String: CGPoint] = [
            "Source": CGPoint(x: 0, y: 0),
            "Destination": CGPoint(x: 400, y: 0)
        ]

        let points = repository.connectorPoints(for: relationship, in: graph, positions: positions)

        #expect(points != nil)
        #expect((points?.count ?? 0) >= 2)
    }
}
