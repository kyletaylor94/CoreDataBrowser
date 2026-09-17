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
            Text(AppConstants.AppFolderStrings.title)
                .font(.headline)
            
            VStack(spacing: 16) {
                ForEach(PathType.allCases, id: \.self) { pathType in
                    PathRow(pathManager: pathManager, text: pathType.binding(from: pathManager), title: pathType.attributes.title, placeholder: pathType.attributes.placeholder, field: pathType)
                }
            }
            
            HStack {
                Button(AppConstants.AppFolderStrings.resetDefaults) {
                    focusedField = nil
                    pathManager.resetPaths()
                }
                
                Spacer()
                
                Button(AppConstants.AppFolderStrings.cancel) {
                    pathManager.isSheetPresented = false
                }
                .keyboardShortcut(.cancelAction)
                
                Button(AppConstants.AppFolderStrings.save) {
                    pathManager.isSheetPresented = false
                }
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding()
        .frame(width: 500)
    }
}
