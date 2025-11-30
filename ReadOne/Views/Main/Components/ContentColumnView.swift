//
//  ContentColumnView.swift
//  ReadOne
//
//  Created by 纪洪波 on 11/30/25.
//

import SwiftData
import SwiftUI

struct ContentColumnView: View {
    let selectedSection: SidebarSection?
    let allArticles: [Article]
    let starredArticles: [Article]
    @Binding var selectedArticle: Article?
    let modelContext: ModelContext
    
    var body: some View {
        if let selectedSection {
            switch selectedSection {
            case .allArticles:
                ArticleListContentView(
                    articles: allArticles,
                    title: String(localized: "All Articles"),
                    selectedArticle: $selectedArticle
                )
            case .starred:
                ArticleListContentView(
                    articles: starredArticles,
                    title: String(localized: "Starred"),
                    selectedArticle: $selectedArticle,
                    showEmpty: true
                )
            case .feed(let feed):
                FeedArticleListView(
                    feed: feed,
                    selectedArticle: $selectedArticle,
                    modelContext: modelContext
                )
            }
        } else {
            ContentUnavailableView(
                "Select a Feed",
                systemImage: "doc.text",
                description: Text("Choose a feed from the sidebar to view articles")
            )
        }
    }
}
