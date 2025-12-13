//
//  DiscoverView.swift
//  ReadOne
//
//  Created by Claude on 12/13/25.
//

import SwiftData
import SwiftUI

struct DiscoverView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \RSSHubInstance.createdAt) private var allInstances: [RSSHubInstance]

    private var currentInstance: RSSHubInstance {
        if let defaultInstance = allInstances.first(where: { $0.isDefault }) {
            return defaultInstance
        }
        if let firstInstance = allInstances.first {
            return firstInstance
        }
        let official = RSSHubInstance.createOfficialInstance()
        modelContext.insert(official)
        return official
    }

    private let categoryColumns = [
        GridItem(.adaptive(minimum: 100, maximum: 150), spacing: 12)
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // 分类卡片（使用静态分类列表）
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Categories")
                            .font(.title2)
                            .fontWeight(.bold)
                            .padding(.horizontal)

                        LazyVGrid(columns: categoryColumns, spacing: 12) {
                            ForEach(RSSHubCategory.all) { category in
                                NavigationLink(value: category) {
                                    CategoryCard(category: category)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal)
                    }

                    // 热门路由
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Popular")
                            .font(.title2)
                            .fontWeight(.bold)
                            .padding(.horizontal)

                        LazyVStack(spacing: 8) {
                            ForEach(RSSHubPopularRoute.all) { route in
                                NavigationLink(value: route) {
                                    PopularRouteRow(route: route)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical)
            }
            .background(Color.platformBackground)
            .navigationTitle("Discover")
            .navigationDestination(for: RSSHubPopularRoute.self) { route in
                RSSHubPopularRouteDetailView(popularRoute: route, instance: currentInstance)
            }
            .navigationDestination(for: RSSHubCategory.self) { category in
                CategoryRoutesView(category: category, instance: currentInstance)
            }
        }
    }
}

// MARK: - Category Card

struct CategoryCard: View {
    let category: RSSHubCategory

    private var gradientColors: [Color] {
        let colorSets: [[Color]] = [
            [.blue, .cyan],
            [.purple, .pink],
            [.orange, .red],
            [.green, .mint],
            [.indigo, .purple],
            [.pink, .orange],
            [.teal, .blue],
            [.yellow, .orange],
        ]
        let index = abs(category.id.hashValue) % colorSets.count
        return colorSets[index]
    }

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: category.icon)
                .font(.system(size: 24))
                .foregroundStyle(.white)

            Text(category.name)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(.white)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 80)
        .background(
            LinearGradient(
                colors: gradientColors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: gradientColors[0].opacity(0.3), radius: 4, x: 0, y: 2)
    }
}

// MARK: - Popular Route Row

struct PopularRouteRow: View {
    let route: RSSHubPopularRoute

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "antenna.radiowaves.left.and.right")
                .font(.title3)
                .foregroundStyle(.green)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 2) {
                Text(route.name)
                    .fontWeight(.medium)
                    .foregroundStyle(.primary)
                Text(route.path)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(12)
        .background(Color.platformCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

// MARK: - Unified Add Feed View

struct AddFeedView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \RSSHubInstance.createdAt) private var allInstances: [RSSHubInstance]

    @State private var urlString = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var parsedFeed: ParsedFeedResult?
    @State private var useFullText = false
    @State private var feedAdded = false

    private var currentInstance: RSSHubInstance {
        allInstances.first(where: { $0.isDefault }) ?? allInstances.first
            ?? RSSHubInstance.createOfficialInstance()
    }

    private var isRSSHubPath: Bool {
        let trimmed = urlString.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.hasPrefix("/") && !trimmed.contains("://")
    }

    private var finalURL: String {
        let trimmed = urlString.trimmingCharacters(in: .whitespacesAndNewlines)
        if isRSSHubPath {
            return currentInstance.baseURL + trimmed
        }
        if !trimmed.hasPrefix("http://") && !trimmed.hasPrefix("https://") {
            return "https://" + trimmed
        }
        return trimmed
    }

    var body: some View {
        Form {
            Section {
                TextField("Enter URL or RSSHub path", text: $urlString)
                    .textContentType(.URL)
                    .autocorrectionDisabled()
                    #if os(iOS)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.URL)
                    #endif

                if !urlString.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        if isRSSHubPath {
                            Label("RSSHub Route", systemImage: "antenna.radiowaves.left.and.right")
                                .font(.caption)
                                .foregroundStyle(.green)
                        } else {
                            Label("RSS Feed", systemImage: "dot.radiowaves.up.forward")
                                .font(.caption)
                                .foregroundStyle(.blue)
                        }
                        Text(finalURL)
                            .font(.system(.caption, design: .monospaced))
                            .foregroundStyle(.secondary)
                    }
                }

                Button {
                    Task {
                        await fetchFeed()
                    }
                } label: {
                    HStack {
                        Text("Preview Feed")
                        Spacer()
                        if isLoading {
                            ProgressView()
                        }
                    }
                }
                .disabled(urlString.isEmpty || isLoading)
            } header: {
                Text("Feed URL")
            } footer: {
                Text("Enter a full RSS URL (https://...) or RSSHub path (/bilibili/user/...)")
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
                    Toggle("Full Text Mode", isOn: $useFullText)
                } footer: {
                    Text("Use FeedEx service to fetch full article content")
                }

                Section {
                    Button("Add Feed") {
                        addFeed()
                    }
                    .frame(maxWidth: .infinity)
                    .disabled(feedAdded)
                }

                if feedAdded {
                    Section {
                        Label("Feed added successfully!", systemImage: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                    }
                }
            }

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

            Section("RSSHub Examples") {
                ForEach(rsshubExamples, id: \.path) { example in
                    Button {
                        urlString = example.path
                        parsedFeed = nil
                        errorMessage = nil
                        feedAdded = false
                    } label: {
                        VStack(alignment: .leading) {
                            Text(example.name)
                                .foregroundStyle(.primary)
                            Text(example.path)
                                .font(.system(.caption, design: .monospaced))
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .navigationTitle("Add Feed")
        #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
        #endif
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

    private var rsshubExamples: [(name: String, path: String)] {
        [
            ("知乎热榜", "/zhihu/hot"),
            ("GitHub Trending (Daily)", "/github/trending/daily"),
            ("微博热搜", "/weibo/search/hot"),
            ("B站排行榜", "/bilibili/ranking/0/3"),
        ]
    }

    private func fetchFeed() async {
        guard !urlString.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }

        isLoading = true
        errorMessage = nil
        parsedFeed = nil
        feedAdded = false

        guard let fetchURL = URL(string: finalURL) else {
            errorMessage = String(localized: "Invalid URL")
            isLoading = false
            return
        }

        do {
            parsedFeed = try await RSSService.shared.fetchFeed(from: fetchURL)
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    private func addFeed() {
        guard let parsed = parsedFeed,
            let feedURL = URL(string: finalURL)
        else { return }

        let feed = Feed(
            title: parsed.title,
            url: feedURL,
            feedDescription: parsed.description,
            imageURL: parsed.imageURL,
            useFullText: useFullText
        )

        modelContext.insert(feed)

        for parsedArticle in parsed.articles {
            guard let articleLink = parsedArticle.link else { continue }
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

        feedAdded = true
    }
}

#Preview {
    DiscoverView()
        .modelContainer(PreviewContainer.shared)
}
