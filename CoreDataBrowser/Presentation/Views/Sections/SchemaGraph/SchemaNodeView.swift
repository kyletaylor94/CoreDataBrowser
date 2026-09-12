//
//  SchemaNodeView.swift
//  CoreDataBrowser
//
//  Created by Turdesan Csaba on 2026. 09. 06..
//

import Foundation
import SwiftUI

struct SchemaNodeView: View {
    let node: SchemaNode
    let nodeWidth: CGFloat
    var isFocused: Bool = false
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(node.name)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color("nodeEntityColor"))
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(
                Color("nodeEntityBackgroundColor"),
                in: UnevenRoundedRectangle(
                    topLeadingRadius: 5,
                    bottomLeadingRadius: 0,
                    bottomTrailingRadius: 0,
                    topTrailingRadius: 5
                )
            )
            
            VStack{
                ForEach(node.fields) { field in
                    HStack(spacing: 6) {
                        if field.isRelationship {
                            Image(systemName: "arrowshape.turn.up.right.fill")
                                .font(.system(size: 8))
                                .foregroundStyle(Color.accentColor)
                        }
                        
                        Text(field.name)
                            .font(.system(size: 11, weight: .heavy, design: .monospaced))
                            .foregroundStyle(Color("nodeAttributeColor"))
                            .lineLimit(1)
                            .truncationMode(.tail)
                        
                        Text(field.type + (field.isOptional ? "?" : ""))
                            .font(.system(size: 10, weight: .heavy, design: .monospaced))
                            .foregroundStyle(Color.isSystemDeclaredType(field.type) ? Color("nodeSwiftTypeColor") : Color("nodeCustomObjectColor"))
                            .lineLimit(1)
                            .truncationMode(.tail)
                            .layoutPriority(1)
                            .frame(maxWidth: .infinity, alignment: .trailing)
                    }
                    .padding(.bottom, field.id == node.fields.last?.id ? 6 : 0)
                    if field.id != node.fields.last?.id {
                        Divider()
                    }
                }
            }
            .padding(.horizontal, 10)
        }
        .frame(width: nodeWidth, alignment: .leading)
        .fixedSize(horizontal: false, vertical: true)
        .background(Color("nodeAttributeBackgroundColor"), in: RoundedRectangle(cornerRadius: 0))
        .overlay {
            RoundedRectangle(cornerRadius: 5)
                .stroke(isFocused ? Color.accentColor : .secondary.opacity(0.4), lineWidth: isFocused ? 2.5 : 1)
        }
        .shadow(color: .black.opacity(0.08), radius: 2, y: 1)
    }
}
