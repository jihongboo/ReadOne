//
//  EditFeedView.swift
//  ReadOne
//
//  Created by 纪洪波 on 11/30/25.
//

import SwiftData
import SwiftUI

struct EditFeedView: View {
    @Environment(\.dismiss) private var dismiss

    @Bindable var feed: Feed

    @State private var title: String
    @State private var urlString: String
    @State private var feedDescription: String
    @State private var useFullText: Bool

    init(feed: Feed) {
        self.feed = feed
        _title = State(initialValue: feed.title)
        _urlString = State(initialValue: feed.url)
        _feedDescription = State(initialValue: feed.feedDescription)
        _useFullText = State(initialValue: feed.useFullText)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Basic Info") {
                    TextField("Feed Name", text: $title)

                    TextField("Feed URL", text: $urlString)
                        .textContentType(.URL)
                        .autocorrectionDisabled()
                        #if os(iOS)
                            .textInputAutocapitalization(.never)
                            .keyboardType(.URL)
                        #endif
                }

                Section("Description") {
                    TextField("Description", text: $feedDescription, axis: .vertical)
                        .lineLimit(3...6)
                }

                Section {
                    Toggle("Full Text Mode", isOn: $useFullText)
                } footer: {
                    Text("Use FeedEx service to fetch full article content instead of RSS summary")
                }

                Section("Statistics") {
                    LabeledContent("Total Articles", value: "\(feed.articles.count)")
                    LabeledContent("Unread Articles", value: "\(feed.unreadCount)")
                    LabeledContent(
                        "Created At",
                        value: feed.createdAt.formatted(date: .abbreviated, time: .shortened))
                    LabeledContent(
                        "Last Updated",
                        value: feed.lastUpdated.formatted(date: .abbreviated, time: .shortened))
                }
            }
            .scenePadding()
            .navigationTitle("Edit Feed")
            #if os(iOS)
                .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveFeed()
                    }
                    .disabled(!isValid)
                }
            }
        }
    }

    private var isValid: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !urlString.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func saveFeed() {
        feed.title = title.trimmingCharacters(in: .whitespacesAndNewlines)
        feed.url = urlString.trimmingCharacters(in: .whitespacesAndNewlines)
        feed.feedDescription = feedDescription.trimmingCharacters(in: .whitespacesAndNewlines)
        feed.useFullText = useFullText
        dismiss()
    }
}

#Preview {
    EditFeedView(feed: MockData.sampleFeed)
        .modelContainer(PreviewContainer.shared)
}
