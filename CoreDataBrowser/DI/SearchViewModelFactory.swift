//
//  SearchViewModelFactory.swift
//  CoreDataBrowser
//
//  Created by Turdesan Csaba on 2026. 03. 12..
//

import Foundation

struct SearchViewModelFactory {
    static func make() -> SearchViewModel {
        let repository = SearchRepositoryImpl()
        let useCase = SearchUseCaseImpl(repository: repository)
        return SearchViewModel(useCase: useCase)
    }
}
