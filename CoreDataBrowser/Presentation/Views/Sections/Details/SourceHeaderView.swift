//
//  SourceHeaderView.swift
//  CoreDataBrowser
//
//  Created by Turdesan Csaba on 2026. 09. 06..
//

import Foundation
import SwiftUI

struct SourceHeaderView: View {
    let icon: String
    let title: String
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
