//
//  DIContainer.swift
//  CoreDataBrowser
//
//  Created by Turdesan Csaba on 2026. 03. 13..
//

import Foundation

final class DIContainer {
    private lazy var fileManager = FileManager.default
    private lazy var pathManagerImpl = PathManagerImpl(fileManager: fileManager)
    private let blobDecoder = BlobDecoder()
    private lazy var sqliteExecutorImpl = SQLiteExecutor(blobDecoder: blobDecoder)
    private let copyPathManager = CopyPathManager()
    
    var pathManager: PathManager {
        pathManagerImpl
    }
    
    func makeContentView() -> ContentView {
        let simulatorViewModel = makeSimulatorViewModel()
        let dbDataViewModel = makeDBDataViewModel()
        let userDefaultsViewModel = makeUserDefaultsViewModel()
        
        let contentViewModel = ContentViewModel(
            simulatorViewModel: simulatorViewModel,
            dbDataViewModel: dbDataViewModel,
            userDefaultsViewModel: userDefaultsViewModel
        )
        
        return ContentView(
            simulatorViewModel: simulatorViewModel,
            dbDataViewModel: dbDataViewModel,
            userDefaultsViewModel: userDefaultsViewModel,
            searchViewModel: makeSearchViewModel(),
            pathManager: pathManagerImpl,
            schemaGraphViewModel: makeSchemaGraphViewModel(),
            contentViewModel: contentViewModel
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
        return DBDataViewModel(useCase: useCase, copyPathManager: copyPathManager)
    }
    
    private func makeUserDefaultsViewModel() -> UserDefaultsViewModel {
        let repo = UserDefaultsRepositoryImpl(fileManager: fileManager)
        let useCase = UserDefaultsUseCaseImpl(repository: repo)
        return UserDefaultsViewModel(useCase: useCase, copyPathManager: copyPathManager)
    }
    
    private func makeSearchViewModel() -> SearchViewModel {
        let repo = SearchRepositoryImpl()
        let useCase = SearchUseCaseImpl(repository: repo)
        return SearchViewModel(useCase: useCase)
    }
    
    private func makeSchemaGraphViewModel() -> SchemaGraphViewModel {
        let repo = SchemaGraphRepositoryImpl()
        let useCase = SchemaGraphUseCaseImpl(repository: repo)
        return SchemaGraphViewModel(tables: [], usecase: useCase)
    }
}
