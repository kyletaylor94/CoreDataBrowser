//
//  ModifiedProgressView.swift
//  CoreDataBrowser
//
//  Created by Turdesan Csaba on 2026. 09. 06..
//

import Foundation
import SwiftUI

struct ModifiedProgressView: View {
    var body: some View {
        ZStack {
            Color.black.opacity(0.3)
            ProgressView()
                .progressViewStyle(.circular)
                .scaleEffect(1.5)
                .padding()
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 10))
        }
        .ignoresSafeArea()
    }
}
