//
//  DIContainer.swift
//  CoreDataBrowser
//
//  Created by Turdesan Csaba on 2026. 03. 13..
//

import Foundation

@MainActor
final class DIContainer {
    static let shared = DIContainer()
    
    private lazy var fileManager = FileManager.default
    private lazy var pathManagerImpl = PathManagerImpl(fileManager: fileManager)
    private let blobDecoder = BlobDecoder()
    private lazy var sqliteExecutorImpl = SQLiteExecutor(blobDecoder: blobDecoder)
    
    var pathManager: PathManager {
        pathManagerImpl
    }
    
    func makeContentView() -> ContentView {
        ContentView(
            simulatorViewModel: makeSimulatorViewModel(),
            dbDataViewModel: makeDBDataViewModel(),
            userDefaultsViewModel: makeUserDefaultsViewModel(),
            searchViewModel: makeSearchViewModel(),
            pathManager: pathManagerImpl
        )
    }
    
    private func makeSimulatorViewModel() -> SimulatorViewModel {
        let repo = SimulatorRepositoryImpl(fileManager: fileManager, pathManager: pathManager)
        let useCase = SimulatorUseCaseImpl(repository: repo)
        return SimulatorViewModel(useCase: useCase)
    }
    
    private func makeDBDataViewModel() -> DBDataViewModel {
        let repo = DBRepositoryImpl(fileManager: fileManager, pathManager: pathManager, sqliteExecutor: sqliteExecutorImpl)
        let useCase = DBUseCaseImpl(repository: repo)
        return DBDataViewModel(useCase: useCase)
    }
    
    private func makeUserDefaultsViewModel() -> UserDefaultsViewModel {
        let repo = UserDefaultsRepositoryImpl(fileManager: fileManager)
        let useCase = UserDefaultsUseCaseImpl(repository: repo)
        return UserDefaultsViewModel(useCase: useCase)
    }
    
    private func makeSearchViewModel() -> SearchViewModel {
        let repo = SearchRepositoryImpl()
        let useCase = SearchUseCaseImpl(repository: repo)
        return SearchViewModel(useCase: useCase)
    }
}
