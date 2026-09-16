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
    let table: DBDataTable
    
    @State private var jsonExportOption = false
    @State private var csvExportOption = false
    
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
                jsonExportOption.toggle()
            } label: {
                Label(AppConstants.SourceHeaderStrings.exportJson, systemImage: AppConstants.SourceHeaderIcons.exportJson)
            }
            .fileExporter(isPresented: $jsonExportOption, document: ExportDocument(table: table, format: .json), contentType: .json) { result in
                debugPrint(result)
            }
            
            Button {
                csvExportOption.toggle()
            } label: {
                Label(AppConstants.SourceHeaderStrings.exportCsv, systemImage: AppConstants.SourceHeaderIcons.exportCsv)
            }
            .fileExporter(isPresented: $csvExportOption, document: ExportDocument(table: table, format: .commaSeparatedText),
                contentType: .commaSeparatedText) { result in
                    debugPrint(result)
                }
        }
        .padding()
        .background(Color(nsColor: .controlBackgroundColor))
        Divider()
    }
}

private extension SourceHeaderView {
    func debugPrint(_ result: Result<URL, Error>) {
        switch result {
        case .success(let url):
            print("Exported to \(url)")
        case .failure(let error):
            print("Failed to export: \(error)")
        }
    }
}
