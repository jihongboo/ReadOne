//
//  AISummaryPopoverView.swift
//  ReadOne
//
//  Created by 纪洪波 on 11/30/25.
//

import SwiftUI

struct AISummaryPopoverView: View {
    let article: Article

    @State private var summary = ""
    @State private var error: Error? = nil
    @State private var isLoading = true

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Label("AI Summary", systemImage: "sparkles")
                        .font(.headline)

                    Spacer()

                    if isLoading {
                        ProgressView()
                            .controlSize(.small)
                    }
                }

                Divider()

                if let error {
                    HStack(alignment: .top) {
                        Image(systemName: "exclamationmark.triangle")
                            .foregroundStyle(.orange)
                        Text(verbatim: error.localizedDescription)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                } else if isLoading {
                    Text("Generating summary...")
                        .foregroundStyle(.secondary)
                } else if !summary.isEmpty {
                    Text(verbatim: summary)
                        .fixedSize(horizontal: false, vertical: true)
                } else {
                    Text("No summary yet")
                        .foregroundStyle(.secondary)
                }
            }
            .padding()
        }
        .task {
            do {
                summary = try await SummarizationService.summarize(article: article)
                isLoading = false
            } catch {
                self.error = error
                isLoading = false
            }
        }
    }
}

#Preview("Loading") {
    AISummaryPopoverView(article: MockData.sampleArticle)
        .frame(width: 300, height: 200)
}

#Preview("With Summary") {
    AISummaryPopoverView(article: MockData.sampleArticle)
        .frame(width: 300, height: 200)
}
