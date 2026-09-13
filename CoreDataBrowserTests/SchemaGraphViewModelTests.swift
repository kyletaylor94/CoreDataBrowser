//
//  SchemaGraphViewModelTests.swift
//  CoreDataBrowserTests
//
//  Created by Turdesan Csaba on 2026. 09. 13..
//

import Testing
import CoreData
internal import CoreGraphics
@testable import CoreDataBrowser

@MainActor
struct SchemaGraphViewModelTests {
    
    private func makeViewModel(tables: [DBDataTable] = [], relationships: [String: [DBForeignKey]] = [:]) -> SchemaGraphViewModel {
        let repository = SchemaGraphRepositoryImpl()
        let useCase = SchemaGraphUseCaseImpl(repository: repository)
        return SchemaGraphViewModel(tables: tables, relationships: relationships, usecase: useCase)
    }
    
    private func makeFruitTable() -> DBDataTable {
        DBDataTable(name: "ZFRUITENTITY", columns: ["Z_PK"], rows: [], types: ["INTEGER"], fileSize: 0, isOptional: [false])
    }
    
    @Test("shouldShowEmptyView is true when the graph has no nodes")
    func shouldShowEmptyViewIsTrueForEmptyGraph() {
        let viewModel = makeViewModel(tables: [])
        #expect(viewModel.shouldShowEmptyView == true)
    }
    
    @Test("shouldShowEmptyView is false when the graph has nodes")
    func shouldShowEmptyViewIsFalseWhenGraphHasNodes() {
        let viewModel = makeViewModel(tables: [makeFruitTable()])
        #expect(viewModel.shouldShowEmptyView == false)
    }
    
    @Test("disableButtonStack is true while content is loading, even if the graph has nodes")
    func disableButtonStackIsTrueWhileLoading() {
        let viewModel = makeViewModel(tables: [makeFruitTable()])
        viewModel.isLoadingContent = true
        #expect(viewModel.disableButtonStack == true)
    }
    
    @Test("disableButtonStack is false once loaded and the graph has nodes")
    func disableButtonStackIsFalseWhenLoadedAndNotEmpty() {
        let viewModel = makeViewModel(tables: [makeFruitTable()])
        viewModel.isLoadingContent = false
        #expect(viewModel.disableButtonStack == false)
    }
    
    @Test("zoomIn increases the zoom scale up to the maximum")
    func zoomInIncreasesUpToMaximum() {
        let viewModel = makeViewModel()
        viewModel.zoomScale = viewModel.maxZoom - viewModel.zoomStep / 2
        viewModel.zoomIn()
        #expect(viewModel.zoomScale == viewModel.maxZoom)
    }
    
    @Test("zoomOut decreases the zoom scale down to the minimum")
    func zoomOutDecreasesDownToMinimum() {
        let viewModel = makeViewModel()
        viewModel.zoomScale = viewModel.minZoom + viewModel.zoomStep / 2
        viewModel.zoomOut()
        #expect(viewModel.zoomScale == viewModel.minZoom)
    }
    
    @Test("resetZoom sets the zoom scale back to 1.0")
    func resetZoomSetsScaleToOne() {
        let viewModel = makeViewModel()
        viewModel.zoomScale = 1.8
        viewModel.resetZoom()
        #expect(viewModel.zoomScale == 1.0)
    }
    
    @Test("moveNode updates the stored position for that node")
    func moveNodeUpdatesStoredPosition() {
        let viewModel = makeViewModel(tables: [makeFruitTable()])
        let newPosition = CGPoint(x: 42, y: 84)
        
        viewModel.moveNode("FruitEntity", to: newPosition)
        
        #expect(viewModel.nodePositions["FruitEntity"] == newPosition)
    }
    
    @Test("focusNode highlights the node matching the given raw table name")
    func focusNodeHighlightsMatchingNode() {
        let viewModel = makeViewModel(tables: [makeFruitTable()])
        
        viewModel.focusNode(named: "ZFRUITENTITY")
        
        #expect(viewModel.focusedNodeID != nil)
    }
    
    @Test("focusNode clears the highlight when given a name that matches no node")
    func focusNodeClearsHighlightForUnknownName() {
        let viewModel = makeViewModel(tables: [makeFruitTable()])
        viewModel.focusNode(named: "ZFRUITENTITY")
        #expect(viewModel.focusedNodeID != nil)
        
        viewModel.focusNode(named: "ZUNKNOWNENTITY")
        
        #expect(viewModel.focusedNodeID == nil)
    }
    
    @Test("updateCoreData rebuilds the graph with the new tables once loading finishes")
    func updateCoreDataRebuildsGraph() async throws {
        let viewModel = makeViewModel(tables: [])
        #expect(viewModel.shouldShowEmptyView == true)
        
        viewModel.updateCoreData(tables: [makeFruitTable()], relationships: [:])
        try await Task.sleep(for: .milliseconds(400))
        
        #expect(viewModel.shouldShowEmptyView == false)
    }
    
    @Test("updateSwiftData is ignored while the coreData tab is selected")
    func updateSwiftDataIgnoredWhileCoreDataSelected() async throws {
        let viewModel = makeViewModel(tables: [])
        #expect(viewModel.selectedGraphViewType == .coreData)
        
        viewModel.updateSwiftData(tables: [makeFruitTable()], relationships: [:])
        try await Task.sleep(for: .milliseconds(400))
        
        #expect(viewModel.shouldShowEmptyView == true)
    }
    
    @Test("setGraphViewType is a no-op when selecting the currently active type")
    func setGraphViewTypeIsNoOpForSameType() {
        let viewModel = makeViewModel(tables: [makeFruitTable()])
        let positionsBefore = viewModel.nodePositions
        
        viewModel.setGraphViewType(.coreData)
        
        #expect(viewModel.selectedGraphViewType == .coreData)
        #expect(viewModel.nodePositions.keys == positionsBefore.keys)
    }
}
