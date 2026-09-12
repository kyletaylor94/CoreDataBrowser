//
//  CopyPathManager.swift
//  CoreDataBrowser
//
//  Created by Turdesan Csaba on 2026. 09. 12..
//

import Foundation
import AppKit
import Observation

@MainActor
@Observable
final class CopyPathManager {
    private(set) var copiedType: DetailType?
    private var feedbackTask: Task<Void, Never>?

    func copyPath(for table: DBDataTable?, type: DetailType) {
        guard let fileURL = table?.fileURL else { return }

        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(fileURL.path, forType: .string)

        copiedType = type
        feedbackTask?.cancel()

        feedbackTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(2))
            guard !Task.isCancelled else { return }

            if self?.copiedType == type {
                self?.copiedType = nil
            }
        }
        print("Extracted path: \(fileURL.path)")
    }
}
