//
//  MockData.swift
//  ReadOne
//
//  Created by 纪洪波 on 11/30/25.
//

import Foundation
import SwiftData

// MARK: - Preview Container

@MainActor
enum PreviewContainer {
    static let shared: ModelContainer = {
        let schema = Schema([Feed.self, Article.self])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: schema, configurations: [config])

        // 插入 mock 数据
        for feed in MockData.feeds {
            container.mainContext.insert(feed)
        }

        return container
    }()
}

// MARK: - Mock Data

enum MockData {

    // MARK: - Feeds

    static let feeds: [Feed] = {
        let feed1 = Feed(
            title: "少数派",
            url: "https://sspai.com/feed",
            feedDescription: "高效工作，品质生活",
            imageURL: "https://cdn.sspai.com/sspai/assets/img/favicon/icon.ico"
        )

        let feed2 = Feed(
            title: "Swift by Sundell",
            url: "https://swiftbysundell.com/rss",
            feedDescription: "Articles, podcasts and news about Swift development",
            imageURL: nil
        )

        let feed3 = Feed(
            title: "Hacking with Swift",
            url: "https://hackingwithswift.com/feed",
            feedDescription: "Learn Swift the easy way",
            imageURL: nil
        )

        // 添加文章到 feed1
        let articles1 = [
            Article(
                title: "2024 年度最佳 iOS App 推荐：这些应用让你的 iPhone 更好用",
                link: "https://sspai.com/post/12345",
                articleDescription: "每年年末，我们都会盘点一下这一年中最值得推荐的 iOS 应用。今年的榜单包含了效率工具、创意应用、健康管理等多个类别...",
                content: sampleHTMLContent,
                author: "少数派编辑部",
                publishedDate: Date().addingTimeInterval(-3600),
                guid: "sspai-12345",
                imageURL: "https://picsum.photos/400/300?random=1"
            ),
            Article(
                title: "用 Shortcuts 打造你的自动化工作流",
                link: "https://sspai.com/post/12346",
                articleDescription: "快捷指令是 iOS 上最强大的自动化工具，本文将带你从入门到精通...",
                content: "<p>快捷指令（Shortcuts）是苹果生态中非常强大的自动化工具。</p>",
                author: "Power User",
                publishedDate: Date().addingTimeInterval(-7200),
                guid: "sspai-12346",
                imageURL: nil
            ),
            Article(
                title: "macOS Sequoia 新功能完全指南",
                link: "https://sspai.com/post/12347",
                articleDescription: "苹果最新的 macOS 系统带来了许多令人兴奋的新功能，包括窗口平铺、iPhone 镜像等...",
                content: "<p>macOS Sequoia 是苹果公司发布的最新桌面操作系统。</p>",
                author: "Mac 玩家",
                publishedDate: Date().addingTimeInterval(-86400),
                guid: "sspai-12347",
                imageURL: "https://picsum.photos/400/300?random=2"
            )
        ]

        // 添加文章到 feed2
        let articles2 = [
            Article(
                title: "Understanding Swift's async/await",
                link: "https://swiftbysundell.com/articles/async-await",
                articleDescription: "Swift's concurrency system, powered by async/await, provides a modern way to write asynchronous code that's both safe and easy to understand.",
                content: sampleSwiftArticleContent,
                author: "John Sundell",
                publishedDate: Date().addingTimeInterval(-14400),
                guid: "sundell-001",
                imageURL: nil
            ),
            Article(
                title: "Building custom SwiftUI views",
                link: "https://swiftbysundell.com/articles/swiftui-views",
                articleDescription: "Learn how to create reusable, composable UI components using SwiftUI's powerful view building system.",
                content: "<p>SwiftUI makes it incredibly easy to build custom views.</p>",
                author: "John Sundell",
                publishedDate: Date().addingTimeInterval(-172800),
                guid: "sundell-002",
                imageURL: "https://picsum.photos/400/300?random=3"
            )
        ]

        // 添加文章到 feed3
        let articles3 = [
            Article(
                title: "What's new in Swift 6.0",
                link: "https://hackingwithswift.com/swift6",
                articleDescription: "Swift 6.0 introduces complete concurrency checking, typed throws, and much more. Let's explore all the new features.",
                content: "<p>Swift 6.0 是一个重要的版本更新。</p>",
                author: "Paul Hudson",
                publishedDate: Date().addingTimeInterval(-28800),
                guid: "hws-001",
                imageURL: nil
            )
        ]

        // 设置文章的 feed 关系和状态
        for article in articles1 {
            article.feed = feed1
        }
        articles1[0].isStarred = true

        for article in articles2 {
            article.feed = feed2
        }
        articles2[0].isRead = true
        articles2[1].isStarred = true

        for article in articles3 {
            article.feed = feed3
        }

        feed1.articles = articles1
        feed2.articles = articles2
        feed3.articles = articles3

        return [feed1, feed2, feed3]
    }()

    // MARK: - Single Items for Simple Previews

    static var sampleFeed: Feed {
        let feed = Feed(
            title: "少数派",
            url: "https://sspai.com/feed",
            feedDescription: "高效工作，品质生活",
            imageURL: "https://cdn.sspai.com/sspai/assets/img/favicon/icon.ico"
        )

        let articles = [
            Article(
                title: "示例文章标题",
                link: "https://example.com",
                articleDescription: "这是文章的描述内容，展示了文章的简要信息...",
                content: sampleHTMLContent,
                author: "作者",
                publishedDate: Date(),
                guid: "sample-001"
            ),
            Article(
                title: "另一篇文章",
                link: "https://example.com/2",
                articleDescription: "这是另一篇文章的描述",
                content: "",
                author: "作者2",
                publishedDate: Date().addingTimeInterval(-3600),
                guid: "sample-002"
            )
        ]

        for article in articles {
            article.feed = feed
        }
        feed.articles = articles

        return feed
    }

    static var sampleArticle: Article {
        let article = Article(
            title: "2024 年度最佳 iOS App 推荐",
            link: "https://example.com",
            articleDescription: "每年年末，我们都会盘点一下这一年中最值得推荐的 iOS 应用。今年的榜单包含了效率工具、创意应用、健康管理等多个类别...",
            content: sampleHTMLContent,
            author: "少数派编辑部",
            publishedDate: Date(),
            guid: "sample-article-001",
            imageURL: "https://picsum.photos/400/300"
        )
        return article
    }

    static var sampleReadArticle: Article {
        let article = Article(
            title: "已读文章示例",
            link: "https://example.com",
            articleDescription: "这是一篇已经阅读过的文章",
            content: "<p>文章内容</p>",
            author: "作者",
            publishedDate: Date().addingTimeInterval(-86400),
            guid: "sample-read-001"
        )
        article.isRead = true
        return article
    }

    static var sampleStarredArticle: Article {
        let article = Article(
            title: "收藏的文章示例",
            link: "https://example.com",
            articleDescription: "这是一篇已收藏的重要文章",
            content: sampleHTMLContent,
            author: "作者",
            publishedDate: Date().addingTimeInterval(-7200),
            guid: "sample-starred-001",
            imageURL: "https://picsum.photos/400/300?random=5"
        )
        article.isStarred = true
        return article
    }

    // MARK: - Sample HTML Content

    static let sampleHTMLContent = """
    <div>
        <p>这是一篇示例文章的完整内容。在这里你可以看到富文本的排版效果。</p>

        <h2>主要特性</h2>
        <p>本文将介绍以下几个方面的内容：</p>
        <ul>
            <li>第一个要点：基础概念介绍</li>
            <li>第二个要点：实际应用场景</li>
            <li>第三个要点：最佳实践建议</li>
        </ul>

        <h2>代码示例</h2>
        <p>下面是一段示例代码：</p>
        <pre><code>struct ContentView: View {
        var body: some View {
            Text("Hello, World!")
        }
    }</code></pre>

        <h2>总结</h2>
        <p>通过本文的学习，你应该已经掌握了相关的基础知识。如果有任何问题，欢迎在评论区留言讨论。</p>

        <p><strong>感谢阅读！</strong></p>
    </div>
    """

    static let sampleSwiftArticleContent = """
    <div>
        <p>Swift's concurrency system, powered by async/await, provides a modern way to write asynchronous code that's both safe and easy to understand.</p>

        <h2>Getting Started</h2>
        <p>To use async/await in Swift, you first need to understand the basic concepts:</p>

        <pre><code>func fetchData() async throws -> Data {
        let url = URL(string: "https://api.example.com/data")!
        let (data, _) = try await URLSession.shared.data(from: url)
        return data
    }</code></pre>

        <h2>Error Handling</h2>
        <p>Async functions can throw errors just like regular functions. Use try/catch to handle them appropriately.</p>

        <h2>Conclusion</h2>
        <p>Swift's async/await makes concurrent programming much more approachable. Start using it in your projects today!</p>
    </div>
    """
}
