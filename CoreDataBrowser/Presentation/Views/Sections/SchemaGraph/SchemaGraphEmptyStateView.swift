//
//  SchemaGraphEmptyStateView.swift
//  CoreDataBrowser
//
//  Created by Turdesan Csaba on 2026. 09. 06..
//

import Foundation
import SwiftUI

struct SchemaGraphEmptyStateView: View {
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "point.3.connected.trianglepath.dotted")
                .font(.system(size: 36))
                .foregroundStyle(.secondary)
            Text("No schema data available")
                .font(.headline)
            Text("Select a booted simulator, then choose a CoreData or SwiftData data source to visualize its entities and relationships.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .multilineTextAlignment(.center)
        .padding()
    }
}
