//
//  FeedArticleListView.swift
//  ReadOne
//
//  Created by 纪洪波 on 11/30/25.
//

import SwiftData
import SwiftUI

struct FeedArticleListView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.openWindow) private var openWindow
    @Bindable var feed: Feed
    @Binding var selectedArticle: Article?

    @State private var isRefreshing = false

    var sortedArticles: [Article] {
        feed.articles.sorted { $0.publishedDate > $1.publishedDate }
    }

    var body: some View {
        List(selection: $selectedArticle) {
            ForEach(sortedArticles) { article in
                ArticleRowView(article: article)
                    .tag(article)
                    .contextMenu {
                        Button("Open in New Window") {
                            openWindow(value: article.persistentModelID)
                        }
                        Divider()
                        Button("Delete", role: .destructive) {
                            deleteArticle(article)
                        }
                    }
            }
            .onDelete(perform: deleteArticles)
        }
        .focusedSceneValue(\.selectedArticle, selectedArticle)
        .navigationTitle(feed.title)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    Task {
                        await refreshFeed()
                    }
                } label: {
                    if isRefreshing {
                        ProgressView()
                    } else {
                        Image(systemName: "arrow.clockwise")
                    }
                }
                .disabled(isRefreshing)
            }

            ToolbarItem {
                Menu {
                    Button("Mark All as Read") {
                        markAllAsRead()
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .refreshable {
            await refreshFeed()
        }
    }

    private func markAllAsRead() {
        for article in feed.articles {
            article.isRead = true
        }
    }

    private func deleteArticles(at offsets: IndexSet) {
        for index in offsets {
            let article = sortedArticles[index]
            if selectedArticle == article {
                selectedArticle = nil
            }
            modelContext.delete(article)
        }
    }

    private func deleteArticle(_ article: Article) {
        if selectedArticle == article {
            selectedArticle = nil
        }
        modelContext.delete(article)
    }

    private func refreshFeed() async {
        isRefreshing = true
        defer { isRefreshing = false }

        do {
            let parsedFeed = try await RSSService.shared.fetchFeed(from: feed.fetchURL)
            updateFeed(with: parsedFeed)
        } catch {
            print("Refresh failed: \(error.localizedDescription)")
        }
    }

    private func updateFeed(with parsedFeed: ParsedFeedResult) {
        feed.lastUpdated = Date()

        let existingGuids = Set(feed.articles.map { $0.guid })

        for parsedArticle in parsedFeed.articles {
            guard let articleLink = parsedArticle.link else { continue }
            if !existingGuids.contains(parsedArticle.guid) {
                let article = Article(
                    title: parsedArticle.title,
                    link: articleLink,
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
        }
    }
}

#Preview {
    NavigationStack {
        FeedArticleListView(
            feed: MockData.sampleFeed,
            selectedArticle: .constant(nil)
        )
    }
    .modelContainer(PreviewContainer.shared)
}
