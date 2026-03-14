//
//  AppFolderSheet.swift
//  CoreDataBrowser
//
//  Created by Turdesan Csaba on 2026. 03. 09..
//

import Foundation
import SwiftUI

struct AppFolderSheet: View {
    @Bindable var pathManager: PathManagerImpl
    @FocusState private var focusedField: PathType?
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Would you like to change the app folder paths?")
                .font(.headline)
            
            VStack(spacing: 16) {
                ForEach(PathType.allCases, id: \.self) { pathType in
                    pathRow(title: pathType.attributes.title, placeholder: pathType.attributes.placeholder, text: pathType.binding(from: pathManager), field: pathType)
                }
            }
           buttonSection
        }
        .padding()
        .frame(width: 500)
    }
    @ViewBuilder
    private func pathRow(title: String, placeholder: String, text: Binding<String>, field: PathType) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            
            HStack {
                TextField(placeholder, text: text)
                    .textFieldStyle(.roundedBorder)
                    .focused($focusedField, equals: field)
                Button {
                    pathManager.selectFolder(for: text)
                } label: {
                    Image(systemName: "folder")
                }
            }
        }
    }
    var buttonSection: some View {
        HStack {
            Button("Reset to Defaults") {
                focusedField = nil
                pathManager.resetPaths()
            }
            Spacer()
            Button("Cancel") {
                pathManager.isSheetPresented = false
            }
            .keyboardShortcut(.cancelAction)
            Button("Save") {
                pathManager.isSheetPresented = false
            }
            .keyboardShortcut(.defaultAction)
        }
    }
}
