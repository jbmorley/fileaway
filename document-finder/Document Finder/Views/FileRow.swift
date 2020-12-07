//
//  FileRow.swift
//  Document Finder
//
//  Created by Jason Barrie Morley on 04/12/2020.
//

import SwiftUI

struct FileRow: View {

    var file: FileInfo
    var isSelected: Bool

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 0) {
                HStack {
                    Text(file.name)
                        .lineLimit(1)
                        .font(.headline)
                        .foregroundColor(isSelected ? .white : .primary)
                    Spacer()
                    if let date = file.date {
                        DateView(date: date)
                            .foregroundColor(isSelected ? .white : .secondary)
                    }
                }
                HStack {
                    Text(file.directoryUrl.path)
                        .lineLimit(1)
                        .foregroundColor(isSelected ? .white : .secondary)
                        .font(.subheadline)
                    Spacer()
                }
            }
            .padding(.top, 6)
            .padding(.bottom, 6)
            Divider()
        }
        .padding(.leading)
        .padding(.trailing)
    }

}
