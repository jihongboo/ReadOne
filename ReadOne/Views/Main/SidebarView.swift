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
    @State private var showingDeleteConfirmation = false
    @State private var feedToDelete: Feed?
    @State private var isRefreshing = false

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
                        Text("\(totalUnreadCount)")
                            .font(.callout)
                            .fontWeight(.medium)
                            .foregroundStyle(.secondary)
                    }
                } icon: {
                    Image(systemName: "doc.text")
                }
            }

            // 收藏文章入口
            NavigationLink(value: SidebarSection.starred) {
                Label("Starred", systemImage: "star")
                    .foregroundStyle(.orange)
            }

            // 订阅源列表
            Section("Feeds") {
                ForEach(feeds) { feed in
                    NavigationLink(value: SidebarSection.feed(feed)) {
                        FeedRowView(feed: feed) {
                            feedToDelete = feed
                            showingDeleteConfirmation = true
                        }
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button(role: .destructive) {
                            feedToDelete = feed
                            showingDeleteConfirmation = true
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
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

            ToolbarItem(placement: .automatic) {
                Button {
                    Task {
                        await refreshAllFeeds()
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
        }
        .onDeleteCommand {
            if case .feed(let feed) = selectedSection {
                feedToDelete = feed
                showingDeleteConfirmation = true
            }
        }
        .confirmationDialog(
            "Delete \"\(feedToDelete?.title ?? "Feed")\"?",
            isPresented: $showingDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                if let feed = feedToDelete {
                    if case .feed(let selectedFeed) = selectedSection,
                        selectedFeed.id == feed.id
                    {
                        selectedSection = .allArticles
                    }
                    modelContext.delete(feed)
                    feedToDelete = nil
                }
            }
            Button("Cancel", role: .cancel) {
                feedToDelete = nil
            }
        } message: {
            Text(
                "This will delete the feed and all its articles. This action cannot be undone.")
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
        isRefreshing = true
        defer { isRefreshing = false }

        for feed in feeds {
            do {
                let parsedFeed = try await RSSService.shared.fetchFeed(from: feed.fetchURL)
                updateFeed(feed, with: parsedFeed)
            } catch {
                print("刷新订阅源失败: \(feed.title) - \(error.localizedDescription)")
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
