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

            Button {
                //TODO: - Needs to be implemented
            } label: {
                HStack{
                    Text("Copy Path")
                    
                    Image(systemName: "doc.on.doc")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
        .background(Color(nsColor: .controlBackgroundColor))
        Divider()
    }
}
