//
//  SchemaBottomButtonStack.swift
//  CoreDataBrowser
//
//  Created by Turdesan Csaba on 2026. 09. 09..
//

import Foundation
import SwiftUI

struct SchemaBottomButtonStack: View {
    @Binding var gestureStartZoom: CGFloat
    @Environment(SchemaGraphViewModel.self) var viewModel
    var body: some View {
        HStack(spacing: 4) {
            Button {
                viewModel.resetZoom()
                gestureStartZoom = 1.0
            } label: {
                Image(systemName: "arrow.trianglehead.counterclockwise")
            }
            .help("Reset Zoom")

            Divider()
                .frame(height: 18)
                .padding(.horizontal, 4)

            Button {
                viewModel.zoomOut()
            } label: {
                Image(systemName: "minus.magnifyingglass")
            }
            .help("Zoom Out")

            Text("\(Int(viewModel.zoomScale * 100))%")
                .font(.system(size: 13, weight: .medium))
                .monospacedDigit()
                .foregroundStyle(.secondary)
                .frame(width: 48)

            Button {
                viewModel.zoomIn()
            } label: {
                Image(systemName: "plus.magnifyingglass")
            }
            .help("Zoom In")
        }
        .buttonStyle(.borderless)
        .padding(.horizontal, 10)
        .frame(height: 38)
        .background {
            RoundedRectangle(cornerRadius: 19)
                .fill(Color(nsColor: .controlBackgroundColor))
                .overlay {
                    RoundedRectangle(cornerRadius: 19)
                        .strokeBorder(.quaternary, lineWidth: 1)
                }
        }
        .shadow(color: .black.opacity(0.15), radius: 8, y: 3)
        .padding(.bottom, 30)
    }
}
