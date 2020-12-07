//
//  SelectionManager.swift
//  Document Finder
//
//  Created by Jason Barrie Morley on 06/12/2020.
//

import Combine
import SwiftUI

class SelectionManager: ObservableObject {

    var tracker: SelectionTracker<FileInfo>
    var cancellable: AnyCancellable? = nil

    init(tracker: SelectionTracker<FileInfo>) {
        self.tracker = tracker
        cancellable = tracker.objectWillChange.sink { [weak self] _ in
            self?.objectWillChange.send()
        }
    }

    var urls: [URL] {
        tracker.selection.map { $0.url }
    }

    var canPreview: Bool { !tracker.selection.isEmpty }

    var canArchive: Bool { !tracker.selection.isEmpty }

    func archive() {
        FileActions.open(urls: urls)
    }

    var canCut: Bool { !tracker.selection.isEmpty }

    func cut() -> [NSItemProvider] {
        urls.map { NSItemProvider(object: $0 as NSURL) }
    }

    var canTrash: Bool { !tracker.selection.isEmpty }

    func trash() throws {
        try urls.forEach { try FileManager.default.trashItem(at: $0, resultingItemURL: nil) }
    }

}