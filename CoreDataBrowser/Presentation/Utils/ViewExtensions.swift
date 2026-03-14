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
    
    /// Applies the necessary environment objects to the view.
    /// - Parameters:
    ///   - simulatorViewModel: The vm for managing simulator data.
    ///   - dbDataViewModel: The vm for managing database data.
    ///   - userDefaultsViewModel: The vm for managing UserDefaults data.
    ///   - searchViewModel: The vm for managing search functionality.
    ///   - Returns: A view with the specified environment objects applied.
    func appEnvironment(simulatorViewModel: SimulatorViewModel? = nil, dbDataViewModel: DBDataViewModel? = nil, userDefaultsViewModel: UserDefaultsViewModel? = nil, searchViewModel: SearchViewModel) -> some View {
        modifier(EnvironmentSetup(
            simulatorViewModel: simulatorViewModel,
            dbDataViewModel: dbDataViewModel,
            userDefaultsViewModel: userDefaultsViewModel,
            searchVM: searchViewModel
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

extension Binding {
    /// Creates a binding to a property of an object.
    /// - Parameters:
    ///  - root: The object containing the property.
    ///  - keyPath: The key path to the property.
    ///  - Returns: A binding to the specified property.
    static func from<Root>(_ root: Root, keyPath: ReferenceWritableKeyPath<Root, Value>) -> Binding<Value> where Root: AnyObject {
        Binding(get: { root[keyPath: keyPath] }, set: { root[keyPath: keyPath] = $0 })
    }
}
