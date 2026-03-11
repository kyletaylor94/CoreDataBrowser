//
//  CoreDataTableView.swift
//  CoreDataBrowser
//
//  Created by Turdesan Csaba on 2026. 03. 08..
//

import Foundation
import SwiftUI

struct DBDetailsView: View {
    @Environment(SearchViewModel.self) var searchVM
    let table: DBDataTable
    @State private var selectedRow: DBDataRow?
    @State private var isMoreDetailSheetPresented: Bool = false
    @State private var isLoadingSheet: Bool = false
    
    var body: some View {
        let rows = makeTableRows(from: table)
        Table(of: DBDataRow.self, selection: Binding(
            get: { selectedRow.map { Set([$0.id]) } ?? [] },
            set: { newSelection in
                if let firstID = newSelection.first,
                   let row = rows.first(where: { $0.id == firstID }) {
                    selectedRow = row
                    isLoadingSheet = true
                    Task {
                        try? await Task.sleep(nanoseconds: 100_000_000)
                        isLoadingSheet = false
                        isMoreDetailSheetPresented = true
                    }
                }
            }
        )) {
            TableColumnForEach(table.formattedColumns.indices, id: \.self) { index in
                TableColumn(table.formattedColumns[index]) { row in
                    let cellValue = row.values.count > index ? row.values[index] : ""
                    searchVM.highlightMatch(in: cellValue)
                }
            }
        } rows: {
            ForEach(rows) { row in
                TableRow(row)
            }
        }
        .overlay {
            if isLoadingSheet {
                ZStack {
                    Color.black.opacity(0.3)
                    ProgressView()
                        .progressViewStyle(.circular)
                        .scaleEffect(1.5)
                        .padding()
                        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 10))
                }
                .ignoresSafeArea()
            }
        }
        .sheet(isPresented: $isMoreDetailSheetPresented) {
            if let row = selectedRow {
                DBMoreDetailSheetView(row: row, columns: table.formattedColumns)
            }
        }
    }
    
    private func makeTableRows(from table: DBDataTable) -> [DBDataRow] {
        table.rows.map { row in
            DBDataRow(values: row)
        }
    }
}
