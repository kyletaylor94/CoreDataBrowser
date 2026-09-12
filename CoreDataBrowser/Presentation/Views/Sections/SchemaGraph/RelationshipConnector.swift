//
//  RelationshipConnector.swift
//  CoreDataBrowser
//
//  Created by Turdesan Csaba on 2026. 09. 06..
//

import Foundation
import SwiftUI

struct RelationshipConnector: View {
    let points: [CGPoint]
    var color: Color = .secondary

    var body: some View {
        Path { path in
            guard let first = points.first else { return }
            path.move(to: first)
            for point in points.dropFirst() {
                path.addLine(to: point)
            }
        }
        .stroke(color, style: StrokeStyle(lineWidth: 1.5, lineCap: .round, lineJoin: .round))
        .overlay {
            if points.count >= 2 {
                ArrowHead(
                    from: points[points.count - 2],
                    to: points[points.count - 1],
                    color: color
                )
            }
        }
    }
}
