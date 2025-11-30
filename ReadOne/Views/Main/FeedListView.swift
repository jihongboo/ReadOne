//
//  FeedListView.swift
//  ReadOne
//
//  Created by 纪洪波 on 11/30/25.
//

import SwiftData
import SwiftUI

struct FeedListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Feed.createdAt, order: .reverse) private var feeds: [Feed]

    @State private var showingAddFeed = false
    @State private var showingDeleteConfirmation = false
    @State private var feedToDelete: Feed?
    @State private var isRefreshing = false
    @State private var selectedSection: SidebarSection? = .allArticles
    @State private var selectedArticle: Article?

    var body: some View {
        NavigationSplitView(columnVisibility: .constant(.all)) {
            // 侧边栏
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
            .sheet(isPresented: $showingAddFeed) {
                AddFeedView()
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
            .navigationSplitViewColumnWidth(min: 120, ideal: 200)
        } content: {
            ContentColumnView(
                selectedSection: selectedSection,
                allArticles: allArticles,
                starredArticles: starredArticles,
                selectedArticle: $selectedArticle,
                modelContext: modelContext
            )
            .navigationSplitViewColumnWidth(min: 140, ideal: 200)
        } detail: {
            // 文章详情
            if let selectedArticle {
                ArticleDetailView(article: selectedArticle)
            } else {
                ContentUnavailableView(
                    "Select an Article",
                    systemImage: "doc.plaintext",
                    description: Text("Choose an article from the list to read")
                )
            }
        }
    }

    // MARK: - Computed Properties

    private var allArticles: [Article] {
        feeds.flatMap { $0.articles }
            .sorted { $0.publishedDate > $1.publishedDate }
    }

    private var starredArticles: [Article] {
        feeds.flatMap { $0.articles }
            .filter { $0.isStarred }
            .sorted { $0.publishedDate > $1.publishedDate }
    }

    private var totalUnreadCount: Int {
        feeds.reduce(0) { $0 + $1.unreadCount }
    }

    // MARK: - Actions

    private func deleteFeeds(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(feeds[index])
        }
    }

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

#Preview {
    FeedListView()
        .modelContainer(PreviewContainer.shared)
}
