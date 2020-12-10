//
//  SelectionTracker.swift
//  Document Finder
//
//  Created by Jason Barrie Morley on 06/12/2020.
//

import Combine
import SwiftUI

enum SelectionTrackerError: Error {
    case outOfRange
}

class SelectionBounds<T> where T: Hashable {

    var tracker: SelectionTracker<T>

    var anchor: T
    var cursor: T

    // Item before the cursor
    var previous: T? {
        return tracker.item(before: cursor)
    }

    init(tracker: SelectionTracker<T>, cursor: T) {
        self.tracker = tracker
        self.anchor = cursor
        self.cursor = cursor
        tracker.select(item: cursor)
    }

    func enumerate(perform: (T) -> Void) {
        let bounds = [tracker.index(of: anchor)!, tracker.index(of: cursor)!].sorted()
        for index in bounds[0]...bounds[1] {
            perform(tracker.items[index])
        }
    }

    func adjustSelectionByMovingCursor(to item: T) {
        enumerate { item in
            tracker.deselect(item: item)
        }
        cursor = item
        enumerate { item in
            tracker.select(item: item)
        }
    }

}

class SelectionTracker<T>: ObservableObject where T: Hashable {

    var publisher: Published<[T]>.Publisher
    var subscription: Cancellable? = nil

    @Published var items: [T] = []
    @Published var selection: Set<T> = []

    var bounds: SelectionBounds<T>?

    init(items: Published<[T]>.Publisher) {
        publisher = items
        subscription = publisher.assign(to: \.items, on: self)
    }

    func clear() {
        selection.removeAll()
        bounds = nil
    }

    fileprivate func select(item: T) {
        selection.insert(item)
    }

    fileprivate func deselect(item: T) {
        selection.remove(item)
    }

    func beginsSelection(item: T) -> Bool {
        guard let index = self.index(of: item) else {
            return false
        }
        if index < 1 {
            return true
        }
        return !selection.contains(items[index - 1])
    }

    func endsSelection(item: T) -> Bool {
        guard let index = self.index(of: item) else {
            return false
        }
        if index >= items.count - 1 {
            return true
        }
        return !selection.contains(items[index + 1])
    }

    func isSelected(item: T) -> Bool {
        return selection.contains(item)
    }

    func index(of item: T) -> Int? {
        items.firstIndex { $0 == item }
    }

    var indexes: [Int] {
        selection.compactMap { item in index(of: item) }
    }

    func selectFirst() throws {
        guard !self.items.isEmpty else {
            throw SelectionTrackerError.outOfRange
        }
        select(item: items[0])
    }

    fileprivate func item(before item: T) -> T? {
        guard var index = self.index(of: item) else {
            return nil
        }
        index -= 1
        if index < 0 || items.count < 1 {
            return nil
        }
        return items[index]
    }

    fileprivate func item(after item: T) -> T? {
        guard var index = self.index(of: item) else {
            return nil
        }
        index += 1
        if index >= items.count {
            return nil
        }
        return items[index]
    }

    func handleDirectionUp() {
        guard let bounds = bounds else {
            if let last = self.items.last {
                clear(selectingItem: last)
            }
            return
        }
        guard let previous = item(before: bounds.cursor) else {
            return
        }
        clear(selectingItem: previous)
    }

    func handleDirectionDown() {
        guard let bounds = bounds else {
            if let first = self.items.first {
                clear(selectingItem: first)
            }
            return
        }
        guard let next = item(after: bounds.cursor) else {
            return
        }
        clear(selectingItem: next)
    }

    func handleShiftDirectionUp() {
        guard let bounds = bounds else {
            if let last = self.items.last {
                clear(selectingItem: last)
            }
            return
        }
        guard let previous = item(before: bounds.cursor) else {
            return
        }
        bounds.adjustSelectionByMovingCursor(to: previous)
    }

    func handleShiftDirectionDown() {
        guard let bounds = bounds else {
            if let first = self.items.first {
                clear(selectingItem: first)
            }
            return
        }
        guard let next = item(after: bounds.cursor) else {
            return
        }
        bounds.adjustSelectionByMovingCursor(to: next)
    }

    fileprivate func clear(selectingItem item: T) {
        clear()
        bounds = SelectionBounds(tracker: self, cursor: item)
        select(item: item)
    }

    func handleClick(item: T) {
        clear(selectingItem: item)
    }

    func handleShiftClick(item: T) {
        guard let bounds = bounds else {
            clear(selectingItem: item)
            return
        }
        bounds.adjustSelectionByMovingCursor(to: item)
    }

    func handleCommandClick(item: T) {
        guard let bounds = bounds else {
            clear(selectingItem: item)
            return
        }
        if selection.contains(item) {
            deselect(item: item)
        } else {
            bounds.anchor = item
            bounds.cursor = item
            select(item: item)
        }
    }

    func corners(for item: T) -> RectCorner {
        var corners = RectCorner()
        if beginsSelection(item: item) {
            corners.insert(.topLeft)
            corners.insert(.topRight)
        }
        if endsSelection(item: item) {
            corners.insert(.bottomLeft)
            corners.insert(.bottomRight)
        }
        return corners
    }

}
