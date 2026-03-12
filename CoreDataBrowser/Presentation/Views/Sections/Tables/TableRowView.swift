//
//  TableRowView.swift
//  CoreDataBrowser
//
//  Created by Turdesan Csaba on 2026. 03. 09..
//

import Foundation
import SwiftUI

struct TableRowView: View {
    let table: DBDataTable
    let showHighlight: Bool
    let searchVM: SearchViewModel
    var body: some View {
        HStack {
            tableNameText
            Spacer()
            Text(FormattingHelper.formattedFileSize(table.fileSize))
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
    @ViewBuilder
    private var tableNameText: some View {
        showHighlight ? searchVM.highlightMatch(in: table.name) : Text(table.name)
    }
}
