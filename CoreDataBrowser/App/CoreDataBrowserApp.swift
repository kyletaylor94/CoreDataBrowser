//
//  CoreDataBrowserApp.swift
//  CoreDataBrowser
//
//  Created by Turdesan Csaba on 2025. 10. 29..
//

import SwiftUI

@main
struct CoreDataBrowserApp: App {
    private let container = DIContainer()
    var body: some Scene {
        WindowGroup {
            container.makeContentView()
        }
    }
}
