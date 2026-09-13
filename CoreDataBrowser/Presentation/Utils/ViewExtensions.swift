//
//  Extensions.swift
//  CoreDataBrowser
//
//  Created by Turdesan Csaba on 2026. 03. 09..
//

import Foundation
import SwiftUI

extension View {
    func createAlert(isPresented: Binding<Bool>, errorMessage: String?, onDismiss: @escaping () -> Void) -> some View {
        self.alert(isPresented: isPresented) {
            Alert(
                title: Text(AppConstants.error),
                message: Text(errorMessage ?? AppConstants.unknownError),
                dismissButton: .default(Text(AppConstants.ok), action: onDismiss)
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


/// Helper for classifying a field's type name so the Schema Graph can color system/Apple-declared
/// types (`nodeSwiftTypeColor`) differently from custom/user entity types (`nodeCustomObjectColor`).
extension Color {
    /// Whether the given type name (ignoring an optional trailing `?`) is one Apple declares, as
    /// opposed to a custom/user entity type.
    static func isSystemDeclaredType(_ type: String) -> Bool {
        let trimmed = type.hasSuffix(AppConstants.questionMark) ? String(type.dropLast()) : type
        return AppConstants.systemDeclaredTypeNames.contains(trimmed.uppercased())
    }
}
