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
            showHighlight ? searchVM.highlightMatch(in: table.name) : Text(table.name)
            Spacer()
            Text(FormattingHelper.formattedFileSize(table.fileSize))
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}
