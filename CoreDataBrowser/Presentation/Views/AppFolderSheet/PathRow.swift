//
//  PathRow.swift
//  CoreDataBrowser
//
//  Created by Turdesan Csaba on 2026. 09. 06..
//

import Foundation
import SwiftUI

struct PathRow: View {
    @Bindable var pathManager: PathManagerImpl
    @Binding var text: String
    @FocusState private var focusedField: PathType?
    let title: String
    let placeholder: String
    let field: PathType
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            
            HStack {
                TextField(placeholder, text: $text)
                    .textFieldStyle(.roundedBorder)
                    .focused($focusedField, equals: field)
                Button {
                    if field == .simulator {
                        pathManager.selectSimulatorFolder(for: $text)
                    } else {
                        pathManager.selectFolder(for: $text)
                    }
                } label: {
                    Image(systemName: "folder")
                }
            }
        }
    }
}
