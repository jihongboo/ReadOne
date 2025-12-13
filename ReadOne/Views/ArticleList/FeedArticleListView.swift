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
    @Bindable var feed: Feed
    @Binding var selectedArticle: Article?

    @State private var articleFilter: ArticleFilter = .all

    var sortedArticles: [Article] {
        var result = feed.articles.sorted { $0.publishedDate > $1.publishedDate }

        switch articleFilter {
        case .all:
            break
        case .unread:
            result = result.filter { !$0.isRead }
        case .starred:
            result = result.filter { $0.isStarred }
        }

        return result
    }

    var body: some View {
        List(selection: $selectedArticle) {
            ForEach(sortedArticles) { article in
                ArticleRowView(article: article, selectedArticle: $selectedArticle)
            }
        }
        .focusedSceneValue(\.selectedArticle, selectedArticle)
        .navigationTitle(feed.title)
        .toolbar {
            toolbarContent
        }
        .refreshable {
            await refreshFeed()
        }
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .primaryAction) {
            Menu {
                ForEach(ArticleFilter.allCases, id: \.self) { filter in
                    Button {
                        articleFilter = filter
                    } label: {
                        Label(filter.rawValue, systemImage: filter.systemImage)
                    }
                }
            } label: {
                Label(
                    articleFilter.rawValue,
                    systemImage: articleFilter == .all
                        ? "line.3.horizontal.decrease.circle"
                        : "line.3.horizontal.decrease.circle.fill")
            }
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

    private func markAllAsRead() {
        for article in feed.articles {
            article.isRead = true
        }
    }

    private func refreshFeed() async {
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
