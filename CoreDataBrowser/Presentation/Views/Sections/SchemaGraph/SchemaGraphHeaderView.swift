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
            Image(systemName: "point.3.connected.trianglepath.dotted")
                .foregroundStyle(.secondary)
            
            Text("Schema Graph")
                .font(.headline)
            
            
            Picker("", selection: Binding(
                get: { viewModel.selectedGraphViewType },
                set: { viewModel.setGraphViewType($0) }
            )) {
                Text("CoreData")
                    .tag(GraphViewType.coreData)
                
                Text("SwiftData")
                    .tag(GraphViewType.swiftData)
            }
            .pickerStyle(.segmented)
            .fixedSize()
                        
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
            .buttonStyle(.plain)
            .keyboardShortcut(.cancelAction)
            .help("Close")
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
    }
}
