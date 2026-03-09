//
//  AppFolderSheet.swift
//  CoreDataBrowser
//
//  Created by Turdesan Csaba on 2026. 03. 09..
//

import Foundation
import SwiftUI

struct AppFolderSheet: View {
    //@Environment(PathManager.self) var pathManager
    @Bindable var pathManager: PathManager
    @FocusState private var focusedField: Field?
       
       private enum Field: Hashable {
           case simulator, coreData, swiftData, userDefaults
       }
    var body: some View {
        VStack(spacing: 20) {
            Text("Would you like to change the app folder paths?")
                .font(.headline)
            
            VStack(spacing: 16) {
                pathRow(
                    title: "Simulators Path",
                    placeholder: Constants.SIMULATOR_PATH,
                    text: Binding(
                        get: { pathManager.simulatorPath },
                        set: { pathManager.simulatorPath = $0 }
                    ),
                    field: .simulator
                )
                
                pathRow(
                    title: "CoreData Path",
                    placeholder: Constants.LIBRARY_APPLICATIONSUPPORT_PATH,
                    text: Binding(
                        get: { pathManager.coreDataPath },
                        set: { pathManager.coreDataPath = $0 }
                    ),
                    field: .coreData
                )
                
                pathRow(
                    title: "SwiftData Path",
                    placeholder: Constants.LIBRARY_APPLICATIONSUPPORT_PATH,
                    text: Binding(
                        get: { pathManager.swiftDataPath },
                        set: { pathManager.swiftDataPath = $0 }
                    ),
                    field: .swiftData
                )
                
                pathRow(
                    title: "UserDefaults Path",
                    placeholder: Constants.LIBRARY_PREFENCES_PATH,
                    text: Binding(
                        get: { pathManager.userDefaultsPath },
                        set: { pathManager.userDefaultsPath = $0 }
                    ),
                    field: .userDefaults
                )
            }
            
            HStack {
                Button("Reset to Defaults") {
                    focusedField = nil
                    pathManager.reset()
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
        .padding()
        .frame(width: 500)
    }
    @ViewBuilder
    private func pathRow(title: String, placeholder: String, text: Binding<String>, field: Field) -> some View {
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
}
