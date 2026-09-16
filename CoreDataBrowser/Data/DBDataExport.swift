//
//  DBDataExport.swift
//  CoreDataBrowser
//
//  Created by Turdesan Csaba on 2026. 09. 16..
//

import Foundation

nonisolated struct DBDataExport: Encodable {
    let name: String
    let columns: [DBDataExportColumn]
    let rows: [[String]]
}

nonisolated struct DBDataExportColumn: Encodable {
    let name: String
    let type: String
    let isOptional: Bool
}


extension DBDataExport {
    init(table: DBDataTable) {
        name = table.name

        columns = table.columns.indices.map { index in
            DBDataExportColumn(
                name: FormattingHelper.removeZPrefix(from: table.columns[index]),
                type: table.types[index],
                isOptional: table.isOptional.indices.contains(index)
                    ? table.isOptional[index]
                    : false
            )
        }

        rows = table.rows
    }
}
