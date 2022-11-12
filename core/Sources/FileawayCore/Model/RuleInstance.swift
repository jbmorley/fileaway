// Copyright (c) 2018-2022 InSeven Limited
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

import Combine
import SwiftUI

public class RuleInstance: ObservableObject {

    private var ruleModel: RuleModel
    private var subscriptions: [Cancellable]?

    public var variables: [VariableModel]
    public var name: String { ruleModel.name }

    public init(rule: RuleModel) {
        self.ruleModel = rule
        let variables = rule.variables.map { $0.instance() }
        self.variables = variables
        self.subscriptions = variables.map { $0 as! Observable }.map { $0.observe { self.objectWillChange.send() } }
    }

    public func variable(for name: String) -> (any VariableProvider)? {
        guard let variable = variables.first(where: { $0.name == name }) else {
            return nil
        }
        return variable as? any VariableProvider
    }

    public func destination(for url: URL) -> URL {
        let destination = ruleModel.destination.reduce("") { (result, component) -> String in
            switch component.type {
            case .text:
                return result.appending(component.value)
            case .variable:
                guard let variable = variable(for: component.value) else {
                    return result
                }
                return result.appending(variable.textRepresentation)
            }
        }
        return self.ruleModel.rootUrl.appendingPathComponent(destination).appendingPathExtension(url.pathExtension)
    }

    public func move(url: URL) throws {
        let destinationUrl = self.destination(for: url)
        let fileManager = FileManager.default
        try fileManager.createDirectory(at: destinationUrl.deletingLastPathComponent(),
                                        withIntermediateDirectories: true,
                                        attributes: [:])
        try fileManager.moveItem(at: url, to: destinationUrl)
    }

}
