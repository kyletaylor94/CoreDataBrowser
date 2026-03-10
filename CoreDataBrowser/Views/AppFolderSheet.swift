//
//  AppFolderSheet.swift
//  CoreDataBrowser
//
//  Created by Turdesan Csaba on 2026. 03. 09..
//

import Foundation
import SwiftUI

enum PathType: CaseIterable, Hashable {
    case simulator, coreData, swiftData, userDefaults
    
    var attributes: (title: String, placeholder: String) {
        switch self {
        case .simulator:
            return (title: "Simulators Path", placeholder: Constants.SIMULATOR_PATH)
        case .coreData:
            return (title: "CoreData Path", placeholder: Constants.LIBRARY_APPLICATIONSUPPORT_PATH)
        case .swiftData:
            return (title: "SwiftData Path", placeholder: Constants.LIBRARY_APPLICATIONSUPPORT_PATH)
        case .userDefaults:
            return (title: "UserDefaults Path", placeholder: Constants.LIBRARY_PREFENCES_PATH)
        }
    }
    
    func binding(from pathManager: PathManager) -> Binding<String> {
        switch self {
        case .simulator:
            return Binding(
                get: { pathManager.simulatorPath },
                set: { pathManager.simulatorPath = $0 }
            )
        case .coreData:
            return Binding(
                get: { pathManager.coreDataPath },
                set: { pathManager.coreDataPath = $0 }
            )
        case .swiftData:
            return Binding(
                get: { pathManager.swiftDataPath },
                set: { pathManager.swiftDataPath = $0 }
            )
        case .userDefaults:
            return Binding(
                get: { pathManager.userDefaultsPath },
                set: { pathManager.userDefaultsPath = $0 }
            )
        }
    }
}

struct AppFolderSheet: View {
    @Bindable var pathManager: PathManager
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
}
