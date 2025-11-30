//
//  Article.swift
//  ReadOne
//
//  Created by 纪洪波 on 11/30/25.
//

import Foundation
import SwiftData

@Model
final class Article {
    var title: String
    var link: String
    var articleDescription: String
    var content: String
    var author: String
    var publishedDate: Date
    var isRead: Bool
    var isStarred: Bool
    var guid: String
    var imageURL: String?

    var feed: Feed?

    init(
        title: String,
        link: String,
        articleDescription: String = "",
        content: String = "",
        author: String = "",
        publishedDate: Date = Date(),
        guid: String,
        imageURL: String? = nil
    ) {
        self.title = title
        self.link = link
        self.articleDescription = articleDescription
        self.content = content
        self.author = author
        self.publishedDate = publishedDate
        self.isRead = false
        self.isStarred = false
        self.guid = guid
        self.imageURL = imageURL
    }
}
