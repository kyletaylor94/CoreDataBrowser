//
//  DataSourceListView.swift
//  CoreDataBrowser
//
//  Created by Turdesan Csaba on 2026. 09. 06..
//

import Foundation
import SwiftUI

struct DataSourceListView: View {
    @Environment(SearchViewModel.self) var searchVM
    let title: String
    let tables: [DBDataTable]
    let selectedTable: DBDataTable?
    var showHighlight: Bool? = true
    let action: (DBDataTable) -> Void
    var body: some View {
        VStack {
            Text(title)
                .font(.headline)
                .padding()
            
            List(tables) { table in
                Button {
                    action(table)
                } label: {
                    TableRowView(table: table, showHighlight: showHighlight!, searchVM: searchVM)
                }
            }
        }
    }
}
