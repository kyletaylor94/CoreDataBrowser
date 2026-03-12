//
//  CoreDataTableView.swift
//  CoreDataBrowser
//
//  Created by Turdesan Csaba on 2026. 03. 08..
//

import Foundation
import SwiftUI

struct DBDetailsView: View {
    @Environment(DBDataViewModel.self) var dbDataViewModel
    @Environment(SearchViewModel.self) var searchVM
    let table: DBDataTable
    let isSwiftDataContent: Bool
    
    var body: some View {
        let rows = makeTableRows(from: table)
        Table(of: DBDataRow.self, selection: Binding(
            get: { dbDataViewModel.selectedRow.map { Set([$0.id]) } ?? [] },
            set: { newSelection in
                if let firstID = newSelection.first,
                   let row = rows.first(where: { $0.id == firstID }) {
                    dbDataViewModel.selectedRow = row
                    if isSwiftDataContent == true {
                        dbDataViewModel.isLoadingSwiftDataSheet = true
                    } else {
                        dbDataViewModel.isLoadingCoreDataSheet = true
                    }
                    Task {
                        try? await Task.sleep(nanoseconds: 100_000_000)
                        if isSwiftDataContent == true {
                            dbDataViewModel.isLoadingSwiftDataSheet = false
                        } else {
                            dbDataViewModel.isLoadingCoreDataSheet = false
                        }
                        dbDataViewModel.isMoreDetailSheetPresented = true
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
            if (isSwiftDataContent && dbDataViewModel.isLoadingSwiftDataSheet) ||
                (!isSwiftDataContent && dbDataViewModel.isLoadingCoreDataSheet) {
                createModifiedProgressView()
            }
        }
        .sheet(isPresented: bindingIsMoreDetailsSheet) {
            if let row = dbDataViewModel.selectedRow {
                DBMoreDetailSheetView(row: row, columns: table.formattedColumns)
            }
        }
    }
    
    private func makeTableRows(from table: DBDataTable) -> [DBDataRow] {
        table.rows.map { row in
            DBDataRow(values: row)
        }
    }
    
    private var bindingIsMoreDetailsSheet: Binding<Bool> {
        Binding(
            get: { dbDataViewModel.isMoreDetailSheetPresented },
            set: { dbDataViewModel.isMoreDetailSheetPresented = $0 }
        )
    }
}
