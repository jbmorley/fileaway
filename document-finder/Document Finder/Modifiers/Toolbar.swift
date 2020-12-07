//
//  Toolbar.swift
//  Document Finder
//
//  Created by Jason Barrie Morley on 03/12/2020.
//

import Quartz
import SwiftUI

struct Toolbar: ViewModifier {

    @ObservedObject var manager: SelectionManager
    @Binding var filter: String

    let qlCoordinator: QLCoordinator

    func body(content: Content) -> some View {
        content
            .toolbar {
                ToolbarItem {
                    Button {
                        guard let file = manager.tracker.selection.first else {
                            return
                        }
                        let panel = QLPreviewPanel.shared()
                        qlCoordinator.set(path: file.url)
                        panel?.center()
                        panel?.dataSource = self.qlCoordinator
                        panel?.makeKeyAndOrderFront(nil)
                    } label: {
                        Image(systemName: "eye")
                    }
                    .disabled(!manager.canPreview)
                }
                ToolbarItem {
                    Button {
                        manager.archive()
                    } label: {
                        Image(systemName: "archivebox")
                    }
                    .disabled(!manager.canArchive)
                }
                ToolbarItem {
                    Button {
                        try? manager.trash()
                    } label: {
                        Image(systemName: "trash")
                    }
                    .disabled(!manager.canTrash)
                }
                ToolbarItem {
                    SearchField(search: $filter)
                        .frame(minWidth: 100, idealWidth: 200, maxWidth: .infinity)
                }
            }
    }
}
