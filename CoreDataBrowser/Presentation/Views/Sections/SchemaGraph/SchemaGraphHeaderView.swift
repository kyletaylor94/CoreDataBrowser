//
//  SchemaGraphHeaderView.swift
//  CoreDataBrowser
//
//  Created by Turdesan Csaba on 2026. 09. 06..
//

import Foundation
import SwiftUI

struct SchemaGraphHeaderView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(SchemaGraphViewModel.self) var viewModel
    var body: some View {
        HStack {
            Image(systemName: AppConstants.SchemaGraphIcons.schemaGraph)
                .foregroundStyle(.secondary)
            
            Text(AppConstants.SchemaGraphStrings.schemaGraph)
                .font(.headline)
            
            Picker(AppConstants.emptyString, selection: Binding(
                get: { viewModel.selectedGraphViewType },
                set: { viewModel.setGraphViewType($0) }
            )) {
                Text(AppConstants.SchemaGraphStrings.coreData)
                    .tag(GraphViewType.coreData)
                
                Text(AppConstants.SchemaGraphStrings.swiftData)
                    .tag(GraphViewType.swiftData)
            }
            .pickerStyle(.segmented)
            .fixedSize()
                        
            Button {
                dismiss()
            } label: {
                Image(systemName: AppConstants.SchemaGraphIcons.dismiss)
                    .font(.system(size: 18))
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
            .buttonStyle(.plain)
            .keyboardShortcut(.cancelAction)
            .help(AppConstants.SchemaGraphStrings.close)
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
    }
}
