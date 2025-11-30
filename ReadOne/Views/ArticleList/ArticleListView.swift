//
//  ArticleListView.swift
//  ReadOne
//
//  Created by 纪洪波 on 11/30/25.
//

import SwiftData
import SwiftUI

struct ArticleListView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.openWindow) private var openWindow
    let feed: Feed

    @State private var isRefreshing = false
    @State private var selectedArticle: Article?

    var body: some View {
        List(selection: $selectedArticle) {
            ForEach(feed.articles) { article in
                ArticleRowView(article: article)
                    .tag(article)
                    .contextMenu {
                        Button("Open in New Window") {
                            openWindow(value: article.persistentModelID)
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

    private func deleteArticles(at offsets: IndexSet) {
        let articlesToDelete = offsets.map { feed.articles[$0] }
        for article in articlesToDelete {
            modelContext.delete(article)
        }
    }

    private func markAllAsRead() {
        for article in feed.articles {
            article.isRead = true
        }
    }

    private func refreshFeed() async {
        isRefreshing = true
        defer { isRefreshing = false }

        do {
            let parsedFeed = try await RSSService.shared.fetchFeed(from: feed.fetchURL)
            updateFeed(with: parsedFeed)
        } catch {
            print("刷新失败: \(error.localizedDescription)")
        }
    }

    private func updateFeed(with parsedFeed: ParsedFeedResult) {
        feed.lastUpdated = Date()

        let existingGuids = Set(feed.articles.map { $0.guid })

        for parsedArticle in parsedFeed.articles {
            if !existingGuids.contains(parsedArticle.guid) {
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
        }
    }
}

// MARK: - 全部文章视图

struct AllArticlesView: View {
    @Environment(\.openWindow) private var openWindow
    @Query(sort: \Article.publishedDate, order: .reverse) private var articles: [Article]
    @State private var selectedArticle: Article?

    var body: some View {
        List(selection: $selectedArticle) {
            ForEach(articles) { article in
                NavigationLink {
                    ArticleDetailView(article: article)
                } label: {
                    ArticleRowView(article: article, showFeedName: true)
                }
                .tag(article)
                .contextMenu {
                    Button("Open in New Window") {
                        openWindow(value: article.persistentModelID)
                    }
                }
            }
        }
        .focusedSceneValue(\.selectedArticle, selectedArticle)
        .navigationTitle("All Articles")
    }
}

// MARK: - 收藏文章视图

struct StarredArticlesView: View {
    @Environment(\.openWindow) private var openWindow
    @Query(
        filter: #Predicate<Article> { $0.isStarred },
        sort: \Article.publishedDate,
        order: .reverse
    )
    private var starredArticles: [Article]
    @State private var selectedArticle: Article?

    var body: some View {
        List(selection: $selectedArticle) {
            if starredArticles.isEmpty {
                ContentUnavailableView(
                    "No Starred Articles",
                    systemImage: "star",
                    description: Text("Starred articles will appear here")
                )
            } else {
                ForEach(starredArticles) { article in
                    NavigationLink {
                        ArticleDetailView(article: article)
                    } label: {
                        ArticleRowView(article: article, showFeedName: true)
                    }
                    .tag(article)
                    .contextMenu {
                        Button("Open in New Window") {
                            openWindow(value: article.persistentModelID)
                        }
                    }
                }
            }
        }
        .focusedSceneValue(\.selectedArticle, selectedArticle)
        .navigationTitle("Starred")
    }
}

#Preview("All Articles") {
    NavigationStack {
        AllArticlesView()
    }
    .modelContainer(PreviewContainer.shared)
}

#Preview("Starred Articles") {
    NavigationStack {
        StarredArticlesView()
    }
    .modelContainer(PreviewContainer.shared)
}
