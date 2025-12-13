//
//  SidebarView.swift
//  ReadOne
//
//  Created by 纪洪波 on 11/30/25.
//

import SwiftData
import SwiftUI

struct SidebarView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Feed.createdAt, order: .reverse) private var feeds: [Feed]
    @Query private var allArticles: [Article]

    @Binding var selectedSection: SidebarSection?

    @State private var showingAddFeed = false

    private var totalUnreadCount: Int {
        allArticles.filter { !$0.isRead }.count
    }

    var body: some View {
        List(selection: $selectedSection) {
            // 全部文章入口
            NavigationLink(value: SidebarSection.allArticles) {
                Label {
                    HStack {
                        Text("All Articles")
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Text(totalUnreadCount, format: .number)
                            .font(.callout)
                            .fontWeight(.medium)
                            .foregroundStyle(.secondary)
                    }
                } icon: {
                    Image(systemName: "doc.text")
                }
            }

            // 发现入口
            NavigationLink(value: SidebarSection.discover) {
                Label("Discover", systemImage: "sparkles")
                    .foregroundStyle(.purple)
            }

            // 搜索入口
            NavigationLink(value: SidebarSection.search) {
                Label("Search", systemImage: "magnifyingglass")
                    .foregroundStyle(.blue)
            }

            // 订阅源列表
            Section("Feeds") {
                ForEach(feeds) { feed in
                    FeedRowView(feed: feed, selectedSection: $selectedSection)
                }
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
            AddFeedView()
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

#Preview {
    NavigationSplitView {
        SidebarView(selectedSection: .constant(.allArticles))
    } detail: {
        Text("Detail")
    }
    .modelContainer(PreviewContainer.shared)
}
