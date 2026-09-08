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
                    PathRow(pathManager: pathManager, text: pathType.binding(from: pathManager), title: pathType.attributes.title, placeholder: pathType.attributes.placeholder, field: pathType)
                }
            }
           //MARK: - Button sections
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
        .padding()
        .frame(width: 500)
    }
}
