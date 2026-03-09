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
    var body: some View {
        if isLoading {
            ProgressView()
        } else {
            if isUserDefaultsDetail {
                SectionHeaderView(title: "User Defaults", icon: "gearshape.2", action: onDismiss)
                UserDefaultsTableView(table: table)
                    .alert(isPresented: $hasError) {
                        Alert(
                            title: Text("Error!"),
                            message: Text(errorMessage ?? "Unknown Error"),
                            dismissButton: .default(Text("OK"), action: onErrorDismiss)
                        )
                    }
            } else {
                SectionHeaderView(title: title, icon: icon, action: onDismiss)
                DBDetailsView(table: table)
                    .alert(isPresented: $hasError) {
                        Alert(
                            title: Text("Error!"),
                            message: Text(errorMessage ?? "Unknown Error"),
                            dismissButton: .default(Text("OK"), action: onErrorDismiss)
                        )
                    }
            }
        }
    }
}
