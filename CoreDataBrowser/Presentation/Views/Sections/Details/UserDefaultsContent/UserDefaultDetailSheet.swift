//
//  UserDefaultDetailSheet.swift
//  CoreDataBrowser
//
//  Created by Turdesan Csaba on 2026. 03. 10..
//

import Foundation
import SwiftUI

struct UserDefaultDetailSheet: View {
    let value: String
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 4) {
                Text(AppConstants.UserDefaultDetailSheetStrings.value)
                    .font(.headline)
                Text(value)
                    .textSelection(.enabled)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.secondary.opacity(0.1))
                    .cornerRadius(8)
            }
            .padding()
        }
        .navigationTitle(AppConstants.UserDefaultDetailSheetStrings.navTitle)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button(AppConstants.UserDefaultDetailSheetStrings.done) {
                    dismiss()
                }
            }
        }
    }
}
