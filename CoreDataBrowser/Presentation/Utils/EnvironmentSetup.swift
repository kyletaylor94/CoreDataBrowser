//
//  EnvironmentSetup.swift
//  CoreDataBrowser
//
//  Created by Turdesan Csaba on 2026. 09. 06..
//

import Foundation
import SwiftUI

struct EnvironmentSetup: ViewModifier {
    let simulatorViewModel: SimulatorViewModel?
    let dbDataViewModel: DBDataViewModel?
    let userDefaultsViewModel: UserDefaultsViewModel?
    let searchVM: SearchViewModel?
    
    func body(content: Content) -> some View {
        content
            .environment(dbDataViewModel)
            .environment(userDefaultsViewModel)
            .environment(searchVM)
            .environment(simulatorViewModel)
    }
}
