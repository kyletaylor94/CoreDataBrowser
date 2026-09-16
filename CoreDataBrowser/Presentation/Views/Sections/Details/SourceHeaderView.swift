//
//  SourceHeaderView.swift
//  CoreDataBrowser
//
//  Created by Turdesan Csaba on 2026. 09. 06..
//

import Foundation
import SwiftUI
import UniformTypeIdentifiers

struct SourceHeaderView: View {
    let displayedInfo: (title: String, icon: String)
    let action: () -> Void
    let copyAction: () -> Void
    let isCopied: Bool
    @State private var showExportOptions = false
    @State private var showCSVExportOptions = false
    let table: DBDataTable
    var body: some View {
        HStack {
            Image(systemName: displayedInfo.icon)
                .font(.title2)
                .foregroundStyle(.secondary)
            Text(displayedInfo.title)
                .font(.largeTitle)
                .fontWeight(.bold)
            Button(AppConstants.SourceHeaderStrings.remove) {
                action()
            }
            
            Spacer()
            
            Button(action: copyAction) {
                Label(
                    isCopied ? AppConstants.SourceHeaderStrings.copied : AppConstants.SourceHeaderStrings.copyPath,
                    systemImage: isCopied ? AppConstants.SourceHeaderIcons.checkmark : AppConstants.SourceHeaderIcons.docOnDoc
                )
            }
            .animation(.easeInOut(duration: 0.15), value: isCopied)
            
            Button {
                showExportOptions.toggle()
            } label: {
                Label("Export JSON", systemImage: "curlybraces.square")
            }
            .fileExporter(isPresented: $showExportOptions, document: ExportDocument(table: table, format: .json), contentType: .json) { result in
                switch result {
                case .success(let url):
                    print("Exported to \(url)")
                case .failure(let error):
                    print("Failed to export: \(error)")
                }
            }
            
            Button {
                showCSVExportOptions.toggle()
            } label: {
                Label("Export CSV", systemImage: "tablecells")
            }
            .fileExporter(
                isPresented: $showCSVExportOptions,
                document: ExportDocument(table: table, format: .commaSeparatedText),
                contentType: .commaSeparatedText) { result in
                    switch result {
                    case .success(let url):
                        print("Exported to \(url)")
                    case .failure(let error):
                        print("Failed to export: \(error)")
                    }
                }
        }
        .padding()
        .background(Color(nsColor: .controlBackgroundColor))
        Divider()
    }
}
