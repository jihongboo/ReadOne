//
//  Feed.swift
//  ReadOne
//
//  Created by 纪洪波 on 11/30/25.
//

import Foundation
import SwiftData

@Model
final class Feed {
    var title: String
    var url: String
    var feedDescription: String
    var imageURL: String?
    var lastUpdated: Date
    var createdAt: Date
    var useFullText: Bool

    @Relationship(deleteRule: .cascade, inverse: \Article.feed)
    var articles: [Article] = []

    var unreadCount: Int {
        articles.filter { !$0.isRead }.count
    }

    /// 返回实际用于获取内容的 URL（如果启用全文模式则使用 FeedEx 代理）
    var fetchURL: String {
        if useFullText {
            return "https://feedex.net/feed/\(url)"
        }
        return url
    }

    init(
        title: String, url: String, feedDescription: String = "", imageURL: String? = nil,
        useFullText: Bool = true
    ) {
        self.title = title
        self.url = url
        self.feedDescription = feedDescription
        self.imageURL = imageURL
        self.lastUpdated = Date()
        self.createdAt = Date()
        self.useFullText = useFullText
    }
}
