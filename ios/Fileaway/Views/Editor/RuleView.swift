// Copyright (c) 2018-2024 Jason Morley
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
import Foundation
import SwiftUI

import FileawayCore
import TokenUI

struct TokenField: UIViewControllerRepresentable {

    @Binding var components: [ComponentModel]

    class Coordinator: TokenTextViewControllerDelegate, TokenTextViewControllerInputDelegate {

        func tokenTextViewInputTextDidChange(_ sender: TokenUI.TokenTextViewController, inputText: String) {
        }

        func tokenTextViewInputTextWasConfirmed(_ sender: TokenUI.TokenTextViewController) {
            guard let text = sender.text else {
                return
            }
            print(text)
        }

        func tokenTextViewInputTextWasCanceled(_ sender: TokenUI.TokenTextViewController, reason: TokenUI.TokenTextInputCancellationReason) {

        }

        func tokenTextViewDidChange(_ sender: TokenUI.TokenTextViewController) {
            guard let text = sender.text else {
                return
            }

            // Convert the tokens back into destinations.
            var offset = 0
            for token in sender.tokenList {
                if token.range.location > offset {
                    let startIndex = text.index(text.startIndex, offsetBy: offset)
                    let endIndex = text.index(text.startIndex, offsetBy: token.range.location)
                    print(String(text[startIndex..<endIndex]))
                }
                let startIndex = text.index(text.startIndex, offsetBy: token.range.location)
                let endIndex = text.index(text.startIndex, offsetBy: token.range.location + token.range.length)
                print(String(text[startIndex..<endIndex]))
                offset = token.range.location + token.range.length
            }
            if offset < text.count {
                let startIndex = text.index(text.startIndex, offsetBy: offset)
                print(String(text[startIndex...]))
            }

        }

        func tokenTextViewShouldChangeTextInRange(_ sender: TokenUI.TokenTextViewController,
                                                  range: NSRange,
                                                  replacementText text: String) -> Bool {
            return true
        }

        func tokenTextViewDidSelectToken(_ sender: TokenUI.TokenTextViewController,
                                         tokenRef: TokenUI.TokenReference,
                                         fromRect rect: CGRect) {

        }

        func tokenTextViewDidDeleteToken(_ sender: TokenUI.TokenTextViewController, tokenRef: TokenUI.TokenReference) {

        }

        func tokenTextViewTextStorageIsUpdatingFormatting(_ sender: TokenUI.TokenTextViewController,
                                                          text: String, searchRange: NSRange) -> [(attributes: [NSAttributedString.Key : Any], forRange: NSRange)] {
            return []
        }

        func tokenTextViewBackgroundColourForTokenRef(_ sender: TokenUI.TokenTextViewController, tokenRef: TokenUI.TokenReference) -> UIColor? {
            return .systemCyan
        }

        func tokenTextViewShouldCancelEditingAtInsert(_ sender: TokenUI.TokenTextViewController,
                                                      newText: String,
                                                      inputText: String) -> Bool {
            return true
        }

    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIViewController(context: Context) -> TokenTextViewController {
        let tokenTextViewController = TokenTextViewController()
        tokenTextViewController.delegate = context.coordinator
        tokenTextViewController.inputDelegate = context.coordinator

        for component in components {
            if component.type == .variable {
                tokenTextViewController.addToken(tokenTextViewController.text.count, text: component.value)
            } else {
                tokenTextViewController.appendText(component.value)
            }
        }

        return tokenTextViewController
    }

    func updateUIViewController(_ tokenTextViewController: TokenTextViewController, context: Context) {
        tokenTextViewController.delegate = context.coordinator
    }
}

struct RuleView: View {

    @State private var editMode = EditMode.inactive
    @ObservedObject var rulesModel: RulesModel
    @ObservedObject var editingRuleModel: RuleModel
    var originalRuleModel: RuleModel

    func edit() {
        self.editingRuleModel.establishBackChannel()
        self.editMode = .active
    }

    func save() {
        // SwiftUI gets crashy if there's a first responder attached to a TextView when it's hidden.
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        rulesModel.replace(ruleModel: editingRuleModel)
        self.editMode = .inactive
    }

    func cancel() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        editingRuleModel.reset(to: originalRuleModel)
        self.editMode = .inactive
    }

    var body: some View {
        return VStack {
            Form {

                Section {
                    EditText("Rule", text: $editingRuleModel.name)
                }

                Section("Filename") {
                    TokenField(components: $editingRuleModel.destination)
                        .frame(height: 100)
                }

                Section {
                    ForEach(editingRuleModel.variables) { variable in
                        VariableRow(ruleModel: self.editingRuleModel, variable: variable)
                    }
                    .onDelete { self.editingRuleModel.remove(variableOffsets: $0) }
                    if self.editMode == .active {
                        Button {
                            withAnimation {
                                _ = self.editingRuleModel.createVariable()
                            }
                        } label: {
                            Text("New Variable...")
                        }
                    }
                } header: {
                    Text("Variables")
                } footer: {
                    ErrorText(text: editingRuleModel.validate() ? nil : "Variable names must be unique.")
                }

                Section("Folder") {
                    ComponentItem(ruleModel: self.editingRuleModel, component: self.editingRuleModel.folder)
                }

                Section {
                    ForEach(editingRuleModel.filename) { component in
                        ComponentItem(ruleModel: self.editingRuleModel, component: component)
                    }
                    .onMove { (fromOffsets, toOffset) in
                        self.editingRuleModel.filename.move(fromOffsets: fromOffsets, toOffset: toOffset)
                    }
                    .onDelete { self.editingRuleModel.filename.remove(atOffsets: $0) }
                } header: {
                    Text("Filename")
                } footer: {
                    if editMode == .active {
                        VariablePicker(ruleModel: editingRuleModel)
                    }
                }

            }
            .environment(\.editMode, $editMode)
        }
        .navigationBarTitle(editingRuleModel.name)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(editMode == .active)
        .interactiveDismissDisabled(editMode == .active)
        .toolbar {

            if editMode == .active {

                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        withAnimation {
                            self.cancel()
                        }
                    } label: {
                        Text("Cancel")
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        withAnimation {
                            self.save()
                        }
                    } label: {
                        Text("Save")
                            .bold()
                            .disabled(!editingRuleModel.validate())
                    }
                }

            } else {

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        withAnimation {
                            self.edit()
                        }
                    } label: {
                        Text("Edit")
                    }
                }

            }

        }

    }

}
