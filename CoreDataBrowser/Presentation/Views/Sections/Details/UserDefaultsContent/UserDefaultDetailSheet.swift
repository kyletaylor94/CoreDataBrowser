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
        NavigationStack {
            ScrollView {
                Text(value)
                    .textSelection(.enabled)
                    .padding()
            }
            .navigationTitle("Value")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}
