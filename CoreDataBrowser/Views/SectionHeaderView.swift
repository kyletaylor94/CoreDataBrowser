//
//  SectionHeaderView.swift
//  CoreDataBrowser
//
//  Created by Turdesan Csaba on 2026. 03. 08..
//

import Foundation
import SwiftUI

struct SectionHeaderView: View {
    let title: String
    let icon: String
    let action: () -> Void
    
    var body: some View {
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
