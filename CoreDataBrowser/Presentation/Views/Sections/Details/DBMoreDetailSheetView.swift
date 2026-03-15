//
//  DBMoreDetailSheetView.swift
//  CoreDataBrowser
//
//  Created by Turdesan Csaba on 2026. 03. 10..
//

import Foundation
import SwiftUI

struct DBMoreDetailSheetView: View {
    let row: DBDataRow
    let columns: [String]
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 16) {
                ForEach(columns.indices, id: \.self) { index in
                    if row.values.count > index {
                        createCell(columns: columns, row: row, index: index)
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Row Details")
        .toolbar { toolBarButton }
    }
    private func createCell(columns: [String], row: DBDataRow, index: Int) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(columns[index])
                .font(.headline)
            Text(row.values[index])
                .textSelection(.enabled)
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.secondary.opacity(0.1))
                .cornerRadius(8)
        }
    }
    
    @ToolbarContentBuilder
    var toolBarButton: some ToolbarContent {
        ToolbarItem(placement: .confirmationAction) {
            Button("Done") {
                dismiss()
            }
        }
    }
}
