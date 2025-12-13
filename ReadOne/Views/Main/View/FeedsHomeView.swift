//
//  FeedsHomeView.swift
//  ReadOne
//
//  Created by Claude on 12/14/25.
//

import SwiftData
import SwiftUI

struct FeedsHomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.navigationPath) private var path
    @Query(sort: \Feed.createdAt, order: .reverse) private var feeds: [Feed]
    @Query private var allArticles: [Article]

    @Binding var selectedArticle: Article?

    @State private var showingAddFeed = false

    private var totalUnreadCount: Int {
        allArticles.filter { !$0.isRead }.count
    }

    var body: some View {
        List {
            // 全部文章入口
            Section {
                NavigationLink(value: AllArticlesDestination()) {
                    HStack {
                        Image(systemName: "doc.text")
                            .font(.title2)
                            .foregroundStyle(.blue)
                            .frame(width: 32, height: 32)

                        Text("All Articles")
                            .foregroundStyle(.primary)

                        Spacer()

                        if totalUnreadCount > 0 {
                            Text("\(totalUnreadCount)")
                                .font(.callout)
                                .fontWeight(.medium)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .buttonStyle(.plain)
            }

            // 订阅源列表
            Section("Feeds") {
                ForEach(feeds) { feed in
                    FeedRowView(feed: feed)
                }
            }
        }
        .navigationDestination(for: AllArticlesDestination.self) { _ in
            AllArticlesView(selectedArticle: $selectedArticle)
        }
        .navigationDestination(for: Feed.self) { feed in
            FeedArticleListView(feed: feed, selectedArticle: $selectedArticle)
        }
        .navigationDestination(for: Article.self) { article in
            ArticleDetailView(article: article)
                .onAppear {
                    article.isRead = true
                }
        }
        .navigationTitle("ReadOne")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingAddFeed = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .refreshable {
            await refreshAllFeeds()
        }
        .sheet(isPresented: $showingAddFeed) {
            NavigationStack {
                AddFeedView()
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Cancel") {
                                showingAddFeed = false
                            }
                        }
                    }
            }
        }
        .overlay {
            if feeds.isEmpty {
                ContentUnavailableView {
                    Label("No Feeds", systemImage: "list.bullet")
                } description: {
                    Text("Add your first feed to get started")
                } actions: {
                    Button("Add Feed") {
                        showingAddFeed = true
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
        }
    }

    // MARK: - Actions

    private func refreshAllFeeds() async {
        let feedsToRefresh = feeds.map { ($0.persistentModelID, $0.fetchURL, $0.title) }

        await withTaskGroup(of: (PersistentIdentifier, ParsedFeedResult?).self) { group in
            for (feedID, fetchURL, title) in feedsToRefresh {
                group.addTask {
                    do {
                        let parsedFeed = try await RSSService.shared.fetchFeed(from: fetchURL)
                        return (feedID, parsedFeed)
                    } catch {
                        print("Failed to refresh feed: \(title) - \(error.localizedDescription)")
                        return (feedID, nil)
                    }
                }
            }

            for await (feedID, parsedFeed) in group {
                if let parsedFeed, let feed = modelContext.model(for: feedID) as? Feed {
                    updateFeed(feed, with: parsedFeed)
                }
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

// MARK: - Navigation Destination

struct AllArticlesDestination: Hashable {}

#Preview {
    NavigationStack {
        FeedsHomeView(selectedArticle: .constant(nil))
    }
    .modelContainer(PreviewContainer.shared)
}
