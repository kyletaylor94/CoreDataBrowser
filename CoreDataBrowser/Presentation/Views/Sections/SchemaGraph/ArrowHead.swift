//
//  ArrowHead.swift
//  CoreDataBrowser
//
//  Created by Turdesan Csaba on 2026. 09. 06..
//

import Foundation
import SwiftUI

struct ArrowHead: View {
    let from: CGPoint
    let to: CGPoint
    var color: Color = .secondary
    private let size: CGFloat = 7

    var body: some View {
        let angle = atan2(
            to.y - from.y,
            to.x - from.x
        )

        Path { path in
            path.move(
                to: CGPoint(
                    x: to.x - cos(angle - .pi / 6) * size,
                    y: to.y - sin(angle - .pi / 6) * size
                )
            )

            path.addLine(to: to)
            path.addLine(
                to: CGPoint(
                    x: to.x - cos(angle + .pi / 6) * size,
                    y: to.y - sin(angle + .pi / 6) * size
                )
            )
        }
        .stroke(color, style: StrokeStyle(lineWidth: 1.5, lineCap: .round, lineJoin: .round))
    }
}
