//
//  DetailsPage.swift
//  Document Finder
//
//  Created by Jason Barrie Morley on 14/12/2020.
//

import SwiftUI

struct DetailsPage: View {

    enum AlertType {
        case error(error: Error)
        case duplicate(duplicateUrl: URL)
    }

    @Environment(\.presentationMode) var presentationMode
    @Environment(\.manager) var manager
    @Environment(\.close) var close

    var url: URL
    @StateObject var task: TaskInstance
    @State var alert: AlertType?
    @State var date: Date = Date()
    @State var year = "2020"

    private var columns: [GridItem] = [
        GridItem(.flexible(maximum: 80), alignment: .trailing),
        GridItem(.flexible()),
    ]

    init(url: URL, rootUrl: URL, rule: Rule) {
        self.url = url
        _task = StateObject(wrappedValue: TaskInstance(url: rootUrl, rule: rule))
    }

    var body: some View {
        VStack {
            ScrollView {
                LazyVGrid(columns: columns) {
                    ForEach(task.variables) { variable in
                        Text(variable.name)
                        HStack {
                            if let variable = variable as? DateInstance {
                                VariableDateView(variable: variable)
                            } else if let variable = variable as? StringInstance {
                                VariableStringView(variable: variable)
                            } else {
                                Text("Unsupported")
                            }
                        }
                        .padding(.trailing, 8)
                    }
                }
            }
            .padding()
            Text(task.destinationUrl.path)
            Button {
                print("moving to \(task.destinationUrl)...")
                do {
                    try task.move(url: url)
                    close()
                } catch CocoaError.fileWriteFileExists {
                    alert = .duplicate(duplicateUrl: task.destinationUrl)
                } catch {
                    alert = .error(error: error)
                }

                presentationMode.wrappedValue.dismiss()
            } label: {
                Text("Move")
            }
        }
        .pageTitle(task.name)
        .frame(minWidth: 0, maxWidth: .infinity)
        .alert(item: $alert) { alert in
            switch alert {
            case .error(let error):
                return Alert(title: Text("Unable to Move File"), message: Text(error.localizedDescription))
            case .duplicate(let duplicateUrl):
                return Alert(title: Text("Unable to Move File"),
                             message: Text("File exists at location."),
                             primaryButton: .default(Text("OK")),
                             secondaryButton: .default(Text("Reveal Duplicate"), action: {
                                NSWorkspace.shared.activateFileViewerSelecting([duplicateUrl])
                             }))
            }
        }
    }

}

extension DetailsPage.AlertType: Identifiable {
    public var id: String {
        switch self {
        case .error(let error):
            return "error:\(error)"
        case .duplicate(let duplicateUrl):
            return "duplicate:\(duplicateUrl)"
        }
    }
}
