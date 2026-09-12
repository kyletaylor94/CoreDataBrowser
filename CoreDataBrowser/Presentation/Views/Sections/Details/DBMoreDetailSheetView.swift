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
                        MoreDetailSheetCellView(columns: columns, row: row, index: index)
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Row Details")
        .toolbar {
            CustomToolBarButton(helpText: "Dismiss the row details view",placement: .confirmationAction, text: "Done") {
                dismiss()
            }
        }
    }
}
