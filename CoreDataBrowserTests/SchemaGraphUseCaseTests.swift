//
//  SchemaGraphUseCaseTests.swift
//  CoreDataBrowserTests
//
//  Created by Turdesan Csaba on 2026. 09. 13..
//

import Testing
import CoreData
internal import CoreGraphics
@testable import CoreDataBrowser

@MainActor
struct SchemaGraphUseCaseTests {
    private func makeUseCase() -> SchemaGraphUseCaseImpl {
        SchemaGraphUseCaseImpl(repository: SchemaGraphRepositoryImpl())
    }

    // MARK: Display name mapping
    @Test("displayTypeName maps SQLite storage types to friendlier Swift-like names")
    func displayTypeNameMapsRawSQLiteTypes() {
        let useCase = makeUseCase()
        #expect(useCase.displayTypeName(for: "VARCHAR") == "String")
        #expect(useCase.displayTypeName(for: "INTEGER") == "Int")
    }

    @Test("displayTypeName normalizes casing for unmapped raw types")
    func displayTypeNameNormalizesCasingForUnmappedTypes() {
        let useCase = makeUseCase()
        #expect(useCase.displayTypeName(for: "FLOAT") == "Float")
        #expect(useCase.displayTypeName(for: "date") == "Date")
    }

    @Test("displayTypeName maps NSAttributeType cases to their Swift names")
    func displayTypeNameMapsAttributeTypes() {
        let useCase = makeUseCase()
        #expect(useCase.displayTypeName(for: .stringAttributeType) == "String")
        #expect(useCase.displayTypeName(for: .integer32AttributeType) == "Int32")
        #expect(useCase.displayTypeName(for: .booleanAttributeType) == "Bool")
        #expect(useCase.displayTypeName(for: .UUIDAttributeType) == "UUID")
    }

    @Test("displayEntityName strips the Z prefix and pascal-cases the raw table name")
    func displayEntityNameStripsZPrefixAndPascalCases() {
        let useCase = makeUseCase()
        #expect(useCase.displayEntityName(from: "ZFRUITENTITY") == "FruitEntity")
    }

    @Test("displayPropertyName strips the Z prefix and camel-cases the raw column name")
    func displayPropertyNameStripsZPrefixAndCamelCases() {
        let useCase = makeUseCase()
        #expect(useCase.displayPropertyName(from: "ZNAME") == "name")
    }

    // MARK: buildGraph(tables:relationships:)
    @Test("buildGraph(tables:relationships:) creates one node per table with matching field counts")
    func buildGraphFromTablesCreatesNodesForEachTable() {
        let useCase = makeUseCase()
        let tables = [
            DBDataTable(name: "ZFRUITENTITY", columns: ["Z_PK", "ZNAME"], rows: [], types: ["INTEGER", "VARCHAR"], fileSize: 0, isOptional: [false, true]),
            DBDataTable(name: "ZBASKETENTITY", columns: ["Z_PK", "ZCAPACITY"], rows: [], types: ["INTEGER", "INTEGER"], fileSize: 0, isOptional: [false, false])
        ]

        let graph = useCase.buildGraph(tables: tables, relationships: [:])

        #expect(graph.nodes.count == 2)
        #expect(graph.nodes.contains(where: { $0.name == "FruitEntity" }))
        #expect(graph.nodes.contains(where: { $0.name == "BasketEntity" }))
        #expect(graph.nodes.first(where: { $0.name == "FruitEntity" })?.fields.count == 2)
    }

    @Test("buildGraph(tables:relationships:) marks foreign key columns as relationships typed as the destination entity")
    func buildGraphFromTablesMarksForeignKeyFieldsAsRelationships() {
        let useCase = makeUseCase()
        let tables = [
            DBDataTable(name: "ZFRUITENTITY", columns: ["Z_PK", "ZBASKET"], rows: [], types: ["INTEGER", "INTEGER"], fileSize: 0, isOptional: [false, true]),
            DBDataTable(name: "ZBASKETENTITY", columns: ["Z_PK"], rows: [], types: ["INTEGER"], fileSize: 0, isOptional: [false])
        ]
        let relationships = [
            "ZFRUITENTITY": [DBForeignKey(column: "ZBASKET", destinationTable: "ZBASKETENTITY", destinationColumn: "Z_PK")]
        ]

        let graph = useCase.buildGraph(tables: tables, relationships: relationships)

        let fruitNode = graph.nodes.first(where: { $0.name == "FruitEntity" })
        let basketField = fruitNode?.fields.first(where: { $0.name == "basket" })

        #expect(basketField?.isRelationship == true)
        #expect(basketField?.type == "BasketEntity")
    }

    @Test("buildGraph(tables:relationships:) creates a relationship edge between the source and destination nodes")
    func buildGraphFromTablesCreatesRelationshipEdges() {
        let useCase = makeUseCase()
        let tables = [
            DBDataTable(name: "ZFRUITENTITY", columns: ["Z_PK", "ZBASKET"], rows: [], types: ["INTEGER", "INTEGER"], fileSize: 0, isOptional: [false, true]),
            DBDataTable(name: "ZBASKETENTITY", columns: ["Z_PK"], rows: [], types: ["INTEGER"], fileSize: 0, isOptional: [false])
        ]
        let relationships = [
            "ZFRUITENTITY": [DBForeignKey(column: "ZBASKET", destinationTable: "ZBASKETENTITY", destinationColumn: "Z_PK")]
        ]

        let graph = useCase.buildGraph(tables: tables, relationships: relationships)

        #expect(graph.relationships.count == 1)
        let edge = graph.relationships[0]
        let fruitNode = graph.nodes.first(where: { $0.name == "FruitEntity" })
        let basketNode = graph.nodes.first(where: { $0.name == "BasketEntity" })

        #expect(edge.sourceNodeID == fruitNode?.id)
        #expect(edge.destinationNodeID == basketNode?.id)
        #expect(edge.sourceProperty == "BASKET")
        if case .one = edge.cardinality {
            // expected
        } else {
            Issue.record("Expected cardinality to be .one for a foreign key relationship")
        }
    }

    @Test("buildGraph(tables:relationships:) skips foreign keys whose destination table isn't present")
    func buildGraphFromTablesSkipsDanglingForeignKeys() {
        let useCase = makeUseCase()
        let tables = [
            DBDataTable(name: "ZFRUITENTITY", columns: ["Z_PK", "ZBASKET"], rows: [], types: ["INTEGER", "INTEGER"], fileSize: 0, isOptional: [false, true])
        ]
        let relationships = [
            "ZFRUITENTITY": [DBForeignKey(column: "ZBASKET", destinationTable: "ZMISSINGENTITY", destinationColumn: "Z_PK")]
        ]

        let graph = useCase.buildGraph(tables: tables, relationships: relationships)

        #expect(graph.relationships.isEmpty)
    }

    // MARK: buildGraph(from: entities:)
    private func makeEntities() -> (fruit: NSEntityDescription, basket: NSEntityDescription) {
        let fruitEntity = NSEntityDescription()
        fruitEntity.name = "Fruit"

        let nameAttribute = NSAttributeDescription()
        nameAttribute.name = "name"
        nameAttribute.attributeType = .stringAttributeType
        nameAttribute.isOptional = true

        let basketEntity = NSEntityDescription()
        basketEntity.name = "Basket"

        let capacityAttribute = NSAttributeDescription()
        capacityAttribute.name = "capacity"
        capacityAttribute.attributeType = .integer32AttributeType
        capacityAttribute.isOptional = false

        let basketRelationship = NSRelationshipDescription()
        basketRelationship.name = "basket"
        basketRelationship.destinationEntity = basketEntity
        basketRelationship.maxCount = 1
        basketRelationship.minCount = 0

        let fruitsRelationship = NSRelationshipDescription()
        fruitsRelationship.name = "fruits"
        fruitsRelationship.destinationEntity = fruitEntity
        fruitsRelationship.maxCount = 0
        fruitsRelationship.minCount = 0

        basketRelationship.inverseRelationship = fruitsRelationship
        fruitsRelationship.inverseRelationship = basketRelationship

        fruitEntity.properties = [nameAttribute, basketRelationship]
        basketEntity.properties = [capacityAttribute, fruitsRelationship]

        return (fruitEntity, basketEntity)
    }

    @Test("buildGraph(from:) creates one node per entity with its attributes as fields")
    func buildGraphFromEntitiesCreatesNodesWithFields() {
        let useCase = makeUseCase()
        let (fruit, basket) = makeEntities()

        let graph = useCase.buildGraph(from: [fruit, basket])

        #expect(graph.nodes.count == 2)
        let fruitNode = graph.nodes.first(where: { $0.name == "Fruit" })
        #expect(fruitNode?.fields.contains(where: { $0.name == "name" && $0.type == "String" }) == true)
    }

    @Test("buildGraph(from:) creates relationship edges with the correct cardinality in both directions")
    func buildGraphFromEntitiesCreatesRelationshipEdgeWithCardinality() {
        let useCase = makeUseCase()
        let (fruit, basket) = makeEntities()

        let graph = useCase.buildGraph(from: [fruit, basket])

        let basketToFruits = graph.relationships.first(where: { $0.sourceProperty == "fruits" })
        #expect(basketToFruits != nil)
        if case .many = basketToFruits?.cardinality {
            // expected
        } else {
            Issue.record("Expected cardinality to be .many for the to-many relationship")
        }

        let fruitToBasket = graph.relationships.first(where: { $0.sourceProperty == "basket" })
        #expect(fruitToBasket != nil)
        if case .one = fruitToBasket?.cardinality {
            // expected
        } else {
            Issue.record("Expected cardinality to be .one for the to-one relationship")
        }
    }

    @Test("buildGraph(from:) skips entities without a name")
    func buildGraphFromEntitiesSkipsUnnamedEntities() {
        let useCase = makeUseCase()
        let unnamed = NSEntityDescription()

        let graph = useCase.buildGraph(from: [unnamed])

        #expect(graph.nodes.isEmpty)
    }

    // MARK: focusedNodeID
    @Test("focusedNodeID matches a node by normalizing the raw table name")
    func focusedNodeIDMatchesNormalizedRawName() {
        let useCase = makeUseCase()
        let node = SchemaNode(id: UUID(), name: "FruitEntity", fields: [], type: .coreData)
        let graph = SchemaGraph(nodes: [node], relationships: [])

        let focusedID = useCase.focusedNodeID(forRawName: "ZFRUITENTITY", in: graph)

        #expect(focusedID == node.id)
    }

    @Test("focusedNodeID returns nil when the raw name is nil")
    func focusedNodeIDReturnsNilForNilRawName() {
        let useCase = makeUseCase()
        let graph = SchemaGraph(nodes: [], relationships: [])

        #expect(useCase.focusedNodeID(forRawName: nil, in: graph) == nil)
    }

    @Test("focusedNodeID returns nil when no node matches the raw name")
    func focusedNodeIDReturnsNilWhenNoMatch() {
        let useCase = makeUseCase()
        let node = SchemaNode(id: UUID(), name: "FruitEntity", fields: [], type: .coreData)
        let graph = SchemaGraph(nodes: [node], relationships: [])

        #expect(useCase.focusedNodeID(forRawName: "ZUNKNOWNENTITY", in: graph) == nil)
    }
}
