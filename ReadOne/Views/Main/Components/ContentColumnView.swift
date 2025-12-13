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
    @Binding var selectedArticle: Article?

    var body: some View {
        if let selectedSection {
            switch selectedSection {
            case .allArticles:
                AllArticlesView(selectedArticle: $selectedArticle)
            case .discover:
                DiscoverView()
            case .search:
                SearchFeedView()
            case .feed(let feed):
                FeedArticleListView(
                    feed: feed,
                    selectedArticle: $selectedArticle
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
