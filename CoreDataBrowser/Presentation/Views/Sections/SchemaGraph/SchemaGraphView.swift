//
//  SchemaGraphView.swift
//  CoreDataBrowser
//
//  Created by Turdesan Csaba on 2026. 09. 06..
//

import SwiftUI

/// Displays the Core Data model as an interactive, draggable node graph.
/// Nodes represent entities, connector lines represent relationships between them, routed from the
/// exact relationship field row (like Xcode's Model Diagram viewer).
struct SchemaGraphView: View {
    @Environment(SchemaGraphViewModel.self) var viewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        let size = viewModel.contentSize()
        VStack(spacing: 0) {
            SchemaGraphHeaderView()
            Divider()
            //MARK: - Canvas
            ScrollView([.horizontal, .vertical]) {
                ZStack(alignment: .topLeading) {
                   /// RelationshipLines
                    ForEach(Array(viewModel.graph.relationships.enumerated()), id: \.element.id) { index, relationship in
                        if let points = viewModel.connectorPoints(for: relationship) {
                            RelationshipConnector(points: points, color: viewModel.connectorPalette[index % viewModel.connectorPalette.count])
                        }
                    }
                    
                    ForEach(viewModel.graph.nodes) { node in
                        SchemaNodeView(node: node, isFocused: node.id == viewModel.focusedNodeID)
                            .position(viewModel.nodePositions[node.name] ?? .zero)
                            .gesture(
                                DragGesture()
                                    .onChanged { value in
                                        viewModel.moveNode(node.name, to: value.location)
                                    }
                            )
                    }
                }
                .padding(60)
                .frame(minWidth: size.width, minHeight: size.height, alignment: .topLeading)
            }
            .background(Color(nsColor: .textBackgroundColor))
            .overlay {
                if viewModel.graph.nodes.isEmpty {
                    SchemaGraphEmptyStateView()
                }
            }
        }
        .onExitCommand { dismiss() }
    }
}
