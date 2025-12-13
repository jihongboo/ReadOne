//
//  AllArticlesView.swift
//  ReadOne
//
//  Created by 纪洪波 on 11/30/25.
//

import SwiftData
import SwiftUI

enum ArticleFilter: String, CaseIterable {
    case all = "全部"
    case unread = "未阅读"
    case starred = "收藏"

    var systemImage: String {
        switch self {
        case .all: return "tray.full"
        case .unread: return "circle"
        case .starred: return "star"
        }
    }
}

struct AllArticlesView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Article.publishedDate, order: .reverse) private var articles: [Article]
    @Query private var feeds: [Feed]
    @Binding var selectedArticle: Article?
    @State private var searchText = ""
    @State private var articleFilter: ArticleFilter = .all

    private var filteredArticles: [Article] {
        var result = articles

        switch articleFilter {
        case .all:
            break
        case .unread:
            result = result.filter { !$0.isRead }
        case .starred:
            result = result.filter { $0.isStarred }
        }

        if !searchText.isEmpty {
            result = result.filter {
                $0.title.localizedCaseInsensitiveContains(searchText)
                    || $0.articleDescription.localizedCaseInsensitiveContains(searchText)
            }
        }

        return result
    }

    var body: some View {
        List(selection: $selectedArticle) {
            ForEach(filteredArticles) { article in
                ArticleRowView(
                    article: article, showFeedName: true, selectedArticle: $selectedArticle)
            }
        }
        #if os(iOS)
            .navigationDestination(for: Article.self) { article in
                ArticleDetailView(article: article)
                .onAppear {
                    article.isRead = true
                }
            }
        #endif
        .focusedSceneValue(\.selectedArticle, selectedArticle)
        .searchable(text: $searchText, prompt: "Search articles")
        .refreshable {
            await refreshAllFeeds()
        }
        .navigationTitle("All Articles")
        .navigationSubtitle("\(filteredArticles.count) articles")
        .toolbar {
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
        }
    }

    private func refreshAllFeeds() async {
        for feed in feeds {
            do {
                let parsedFeed = try await RSSService.shared.fetchFeed(from: feed.fetchURL)
                updateFeed(feed, with: parsedFeed)
            } catch {
                print("Failed to refresh feed: \(feed.title) - \(error.localizedDescription)")
            }
        }
    }

    private func updateFeed(_ feed: Feed, with parsedFeed: ParsedFeedResult) {
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
        AllArticlesView(selectedArticle: .constant(nil))
    }
    .modelContainer(PreviewContainer.shared)
}
