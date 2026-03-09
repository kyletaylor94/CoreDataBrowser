//
//  EnvironmentSetup.swift
//  CoreDataBrowser
//
//  Created by Turdesan Csaba on 2026. 03. 08..
//

import Foundation
import SwiftUI

struct EnvironmentSetup: ViewModifier {
    let simulatorViewModel: SimulatorViewModel?
    let swiftDataVM: DBDataViewModel?
    let userDefaultsViewModel: UserDefaultsViewModel?
    let searchVM: SearchViewModel?
    
    func body(content: Content) -> some View {
        content
            .environment(swiftDataVM)
            .environment(userDefaultsViewModel)
            .environment(searchVM)
            .environment(simulatorViewModel)
    }
}

extension View {
    func appEnvironment(
        simulator: SimulatorViewModel? = nil,
        swiftData: DBDataViewModel? = nil,
        userDefaults: UserDefaultsViewModel? = nil,
        search: SearchViewModel
    ) -> some View {
        modifier(EnvironmentSetup(
            simulatorViewModel: simulator,
            swiftDataVM: swiftData,
            userDefaultsViewModel: userDefaults,
            searchVM: search
        ))
    }
}

