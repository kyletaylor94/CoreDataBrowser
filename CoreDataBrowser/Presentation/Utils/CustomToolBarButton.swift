//
//  CustomToolBarButton.swift
//  CoreDataBrowser
//
//  Created by Turdesan Csaba on 2026. 09. 08..
//

import Foundation
import SwiftUI

struct CustomToolBarButton: ToolbarContent {
    let placement: ToolbarItemPlacement
    var icon: String? = ""
    var text: String? = ""
    let action: () -> Void
    
    var body: some ToolbarContent {
        ToolbarItem(placement: placement) {
            Button {
                action()
            } label: {
                if text != nil && !text!.isEmpty {
                    Text(text!)
                } else if icon != nil && !icon!.isEmpty {
                    Image(systemName: icon!)
                }
            }
        }
    }
}
