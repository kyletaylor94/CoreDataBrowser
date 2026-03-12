//
//  Extensions.swift
//  CoreDataBrowser
//
//  Created by Turdesan Csaba on 2026. 03. 09..
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

extension Notification.Name {
    static let tableDidRefresh = Notification.Name(AppConstants.tableDidRefresh)
}

extension View {
    func createAlert(isPresented: Binding<Bool>, errorMessage: String?, onDismiss: @escaping () -> Void) -> some View {
        self.alert(isPresented: isPresented) {
            Alert(
                title: Text("Error!"),
                message: Text(errorMessage ?? "Unknown Error"),
                dismissButton: .default(Text("OK"), action: onDismiss)
            )
        }
    }
    
    func appEnvironment(simulator: SimulatorViewModel? = nil, swiftData: DBDataViewModel? = nil, userDefaults: UserDefaultsViewModel? = nil, search: SearchViewModel) -> some View {
        modifier(EnvironmentSetup(
            simulatorViewModel: simulator,
            swiftDataVM: swiftData,
            userDefaultsViewModel: userDefaults,
            searchVM: search
        ))
    }
    
    func createModifiedProgressView() -> some View {
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
