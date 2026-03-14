//
//  DetailContentView.swift
//  CoreDataBrowser
//
//  Created by Turdesan Csaba on 2026. 03. 09..
//

import Foundation
import SwiftUI

struct DetailContentView: View {
    let table: DBDataTable
    let isLoading: Bool
    let title: String
    let icon: String
    @Binding var hasError: Bool
    let errorMessage: String?
    let onDismiss: () -> Void
    let onErrorDismiss: () -> Void
    var isUserDefaultsDetail: Bool = false
    var isSwiftDataContent: Bool = false
    var body: some View {
        if isLoading {
            ProgressView()
        } else {
            chooseDetailView()
                .createAlert(isPresented: $hasError, errorMessage: errorMessage, onDismiss: onErrorDismiss)
        }
    }
    @ViewBuilder
    private func chooseDetailView() -> some View {
        if isUserDefaultsDetail {
            sourceHeaderView(icon: "gearshape.2", title: "UserDefaults", action: onDismiss)
            UserDefaultsTableView(table: table)
        } else {
            sourceHeaderView(icon: icon, title: title, action: onDismiss)
            DBDetailsView(table: table, isSwiftDataContent: isSwiftDataContent)
        }
    }
    @ViewBuilder
    private func sourceHeaderView(icon: String, title: String, action: @escaping () -> Void) -> some View {
        HStack {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(.secondary)
            Text(title)
                .font(.largeTitle)
                .fontWeight(.bold)
            Button("Remove from the board") {
                action()
            }
            Spacer()
        }
        .padding()
        .background(Color(nsColor: .controlBackgroundColor))
        Divider()
    }
}

