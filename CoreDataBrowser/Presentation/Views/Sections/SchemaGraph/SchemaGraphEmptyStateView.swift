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
            Image(systemName: AppConstants.SchemaGraphIcons.schemaGraph)
                .font(.system(size: 36))
                .foregroundStyle(.secondary)
            Text(AppConstants.SchemaGraphStrings.dataNotAvailableTitle)
                .font(.headline)
            Text(AppConstants.SchemaGraphStrings.dataNotAvailableSubtitle)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .multilineTextAlignment(.center)
        .padding()
    }
}
