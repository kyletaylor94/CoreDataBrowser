//
//  SimulatorDevice.swift
//  CoreDataBrowser
//
//  Created by Turdesan Csaba on 2025. 10. 29..
//

import Foundation

struct SimulatorDevice: Identifiable, Hashable {
    var id: UUID
    let name: String
    let state: String
    let runTime: String
    let path: URL
}
