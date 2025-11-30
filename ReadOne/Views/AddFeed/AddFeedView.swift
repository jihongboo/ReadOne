//
//  AddFeedView.swift
//  ReadOne
//
//  Created by 纪洪波 on 11/30/25.
//

import RSParser
import SwiftData
import SwiftUI

struct AddFeedView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var urlString = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var parsedFeed: ParsedFeedResult?
    @State private var useFullText = true

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Enter RSS Feed URL", text: $urlString)
                        .textContentType(.URL)
                        .autocorrectionDisabled()
                        #if os(iOS)
                            .textInputAutocapitalization(.never)
                            .keyboardType(.URL)
                        #endif

                    if isLoading {
                        HStack {
                            Spacer()
                            ProgressView()
                            Spacer()
                        }
                    }
                }

                if let error = errorMessage {
                    Section {
                        Label(error, systemImage: "exclamationmark.triangle")
                            .foregroundStyle(.red)
                    }
                }

                if let feed = parsedFeed {
                    Section("Preview") {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(feed.title)
                                .font(.headline)

                            if !feed.description.isEmpty {
                                Text(feed.description)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }

                            Text("\(feed.articles.count) articles")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }

                    Section {
                        Toggle("获取全文内容", isOn: $useFullText)
                    } footer: {
                        Text("使用 FeedEx 服务获取完整文章内容，而非 RSS 摘要")
                    }
                }

                List {
                    Section("Recommended Feeds") {
                        ForEach(recommendedFeeds, id: \.url) { feed in
                            Button {
                                urlString = feed.url
                                Task {
                                    await fetchFeed()
                                }
                            } label: {
                                VStack(alignment: .leading) {
                                    Text(feed.name)
                                        .foregroundStyle(.primary)
                                    Text(feed.url)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                }
            }
            .scenePadding()
            .navigationTitle("Add Feed")
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
                    Button("Add") {
                        addFeed()
                    }
                    .disabled(parsedFeed == nil || isLoading)
                }
            }
            .onChange(of: urlString) { _, _ in
                parsedFeed = nil
                errorMessage = nil
            }
            .onSubmit {
                Task {
                    await fetchFeed()
                }
            }
        }
    }

    private var recommendedFeeds: [(name: String, url: String)] {
        [
            ("少数派", "https://sspai.com/feed"),
            ("阮一峰的网络日志", "https://www.ruanyifeng.com/blog/atom.xml"),
            ("V2EX", "https://www.v2ex.com/index.xml"),
            ("Hacker News", "https://hnrss.org/frontpage"),
            ("36氪", "https://36kr.com/feed"),
        ]
    }

    private func fetchFeed() async {
        let trimmedURL = urlString.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedURL.isEmpty else { return }

        var finalURL = trimmedURL
        if !finalURL.hasPrefix("http://") && !finalURL.hasPrefix("https://") {
            finalURL = "https://" + finalURL
        }

        isLoading = true
        errorMessage = nil
        parsedFeed = nil

        // 根据是否启用全文模式决定使用的 URL
        let fetchURL = useFullText ? "https://feedex.net/feed/\(finalURL)" : finalURL

        do {
            parsedFeed = try await RSSService.shared.fetchFeed(from: fetchURL)
            urlString = finalURL
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    private func addFeed() {
        guard let parsed = parsedFeed else { return }

        let feed = Feed(
            title: parsed.title,
            url: urlString,
            feedDescription: parsed.description,
            imageURL: parsed.imageURL,
            useFullText: useFullText
        )

        modelContext.insert(feed)

        for parsedArticle in parsed.articles {
            let article = Article(
                title: parsedArticle.title,
                link: parsedArticle.link,
                articleDescription: parsedArticle.description,
                content: parsedArticle.content,
                author: parsedArticle.author,
                publishedDate: parsedArticle.publishedDate,
                guid: parsedArticle.guid,
                imageURL: parsedArticle.imageURL
            )
            article.feed = feed
            modelContext.insert(article)
        }

        dismiss()
    }
}

#Preview {
    AddFeedView()
        .modelContainer(PreviewContainer.shared)
}
