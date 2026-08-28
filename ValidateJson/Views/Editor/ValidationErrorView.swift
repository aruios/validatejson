//
//  ValidationErrorView.swift
//  ValidateJson
//
//  Created by Arun Madasamy on 8/27/26.
//

import SwiftUI

struct ValidationErrorView: View {
    let errors: [JSONParseError]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 8) {
                ForEach(errors) { error in
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: error.type.icon)
                            .foregroundStyle(.red)
                            .frame(width: 16)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(error.message)
                                .font(.caption)
                                .foregroundStyle(.primary)

                            if let line = error.line {
                                Text("Line \(line)\(error.column.map { ", Column \($0)" } ?? "")")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }

                        Spacer()
                    }
                    .padding(8)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.red.opacity(0.1))
                    )
                }
            }
            .padding(8)
        }
        .background(Color(nsColor: .controlBackgroundColor))
    }
}
