//
//  MoreDetailSheetCellView.swift
//  CoreDataBrowser
//
//  Created by Turdesan Csaba on 2026. 09. 06..
//

import Foundation
import SwiftUI

struct MoreDetailSheetCellView: View {
    let columns: [String]
    let row: DBDataRow
    let index: Int
    var body: some View {
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
}
