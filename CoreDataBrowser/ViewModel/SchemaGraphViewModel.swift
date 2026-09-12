//
//  SchemaGraphViewModel.swift
//  CoreDataBrowser
//
//  Created by Turdesan Csaba on 2026. 09. 06..
//

import Foundation
import Observation
import SwiftUI

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
    
    var isLoadingContent: Bool = false
    var selectedGraphViewType: GraphViewType = .coreData

    private var coreDataTables: [DBDataTable] = []
    private var coreDataRelationships: [String: [DBForeignKey]] = [:]
    private var swiftDataTables: [DBDataTable] = []
    private var swiftDataRelationships: [String: [DBForeignKey]] = [:]
    
    var zoomScale: CGFloat = 1.0
    let minZoom: CGFloat = 0.25
    let maxZoom: CGFloat = 2.0
    let zoomStep: CGFloat = 0.1
    var gestureStartZoom: CGFloat = 1.0
    
    private let usecase: SchemaGraphUseCase

    init(entities: [NSEntityDescription], usecase: SchemaGraphUseCase) {
        self.usecase = usecase
        self.graph = usecase.buildGraph(from: entities)
        setupInitialPositions()
    }

    /// Builds the graph directly from the SQLite-backed `DBDataTable` entities that the app already
    /// discovers on disk, using their real foreign key constraints (see `DBForeignKey`) to draw
    /// relationships. This lets the graph reflect the actual data without needing access to a
    /// compiled `.momd` Core Data model.
    /// - Parameters:
    ///   - tables: The entity tables to visualize (typically `DBDataViewModel.coreDataTables`).
    ///   - relationships: Foreign keys for each table, keyed by table name.
    init(tables: [DBDataTable], relationships: [String: [DBForeignKey]] = [:], usecase: SchemaGraphUseCase) {
        self.usecase = usecase
        self.graph = usecase.buildGraph(tables: tables, relationships: relationships)
        setupInitialPositions()
    }
    
    /// The fixed width used for every node card, sourced from the use case's layout engine.
    var nodeWidth: CGFloat {
        usecase.nodeWidth
    }
    
    /// A convenience property that returns `true` if the graph has no nodes to display. This can be used to show an empty state view.
    var shouldShowEmptyView: Bool {
        return graph.nodes.isEmpty
    }
    
    /// A convenience property that returns `true` if the graph is currently loading content or if it has no nodes to display. This can be used to disable UI elements  should not be interactive while the graph is in a loading state or empty.
    var disableButtonStack: Bool {
        isLoadingContent || shouldShowEmptyView
    }
    
    func setGraphViewType(_ type: GraphViewType) {
        guard selectedGraphViewType != type else { return }

        selectedGraphViewType = type
        updateGraph()
    }
    
    func loadInitialContent() {
        guard !isLoadingContent else { return }
        isLoadingContent = true

        Task { [weak self] in
            try? await Task.sleep(for: .milliseconds(500))
            self?.isLoadingContent = false
        }
    }
    
    private func updateGraph() {
        let previousPositions = nodePositions
        isLoadingContent = true

        Task {
            try? await Task.sleep(for: .milliseconds(300))

            switch selectedGraphViewType {
            case .coreData:
                graph = usecase.buildGraph(
                    tables: coreDataTables,
                    relationships: coreDataRelationships
                )

            case .swiftData:
                graph = usecase.buildGraph(
                    tables: swiftDataTables,
                    relationships: swiftDataRelationships
                )
            }
            setupInitialPositions(preserving: previousPositions)
            isLoadingContent = false
        }
    }
    
    func updateCoreData(tables: [DBDataTable], relationships: [String: [DBForeignKey]]) {
        coreDataTables = tables
        coreDataRelationships = relationships

        guard selectedGraphViewType == .coreData else { return }
        updateGraph()
    }

    func updateSwiftData(tables: [DBDataTable], relationships: [String: [DBForeignKey]]) {
        swiftDataTables = tables
        swiftDataRelationships = relationships

        guard selectedGraphViewType == .swiftData else { return }
        updateGraph()
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
    
    /// Highlights the node matching the given raw table name (e.g. `"ZFRUITENTITY"`) without rebuilding
    /// the whole graph. The name is normalized the same way node names are displayed before matching.
    func focusNode(named tableName: String?) {
        focusedNodeID = usecase.focusedNodeID(forRawName: tableName, in: graph)
    }

    // MARK: Positions
    private func setupInitialPositions(preserving previousPositions: [String: CGPoint] = [:]) {
        nodePositions = usecase.initialPositions(for: graph, preserving: previousPositions)
    }

    /// The on-screen frame (position + estimated size) for the node with the given name, used to
    /// anchor relationship connector lines to a card's actual edges rather than just its center.
    func frame(forNodeNamed name: String) -> CGRect? {
        usecase.frame(forNodeNamed: name, in: graph, positions: nodePositions)
    }

    /// The vertical offset (from a node card's top edge) of the row displaying the given field name,
    /// so a relationship connector can leave from the exact row it originates from, just like Xcode's
    /// Model Diagram. Falls back to the vertical center of the card if the field can't be found.
    func fieldRowOffset(fieldName: String, in node: SchemaNode) -> CGFloat {
        usecase.fieldRowOffset(fieldName: fieldName, in: node)
    }

    /// The total size needed to fit every node in the graph, used to size the scrollable canvas so
    /// it never clips or forces entities to be squeezed together.
    func contentSize() -> CGSize {
        usecase.contentSize(for: graph)
    }

    func moveNode(_ name: String, to position: CGPoint) {
        nodePositions[name] = position
    }
    
    /// Computes an elbow-routed polyline connecting the exact field row that owns a relationship
    /// (on the source entity) to the edge of the destination entity's card.
    func connectorPoints(for relationship: SchemaRelationship) -> [CGPoint]? {
        usecase.connectorPoints(for: relationship, in: graph, positions: nodePositions)
    }
}
