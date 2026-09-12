//
//  SourceHeaderView.swift
//  CoreDataBrowser
//
//  Created by Turdesan Csaba on 2026. 09. 06..
//

import Foundation
import SwiftUI

struct SourceHeaderView: View {
    let displayedInfo: (title: String, icon: String)
    let action: () -> Void
    let copyAction: () -> Void
    let isCopied: Bool
    var body: some View {
        HStack {
            Image(systemName: displayedInfo.icon)
                .font(.title2)
                .foregroundStyle(.secondary)
            Text(displayedInfo.title)
                .font(.largeTitle)
                .fontWeight(.bold)
            Button("Remove from the board") {
                action()
            }
            
            Spacer()
            
            Button(action: copyAction) {
                Label( isCopied ? "Copied" : "Copy Path", systemImage: isCopied ? "checkmark" : "doc.on.doc" )
            }
            .animation(.easeInOut(duration: 0.15), value: isCopied)
            
        }
        .padding()
        .background(Color(nsColor: .controlBackgroundColor))
        Divider()
    }
}
