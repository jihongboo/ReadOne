//
//  FeedListView.swift
//  ReadOne
//
//  Created by 纪洪波 on 11/30/25.
//

import SwiftData
import SwiftUI

struct FeedListView: View {
    @State private var selectedSection: SidebarSection? = .allArticles
    @State private var selectedArticle: Article?

    var body: some View {
        NavigationSplitView(columnVisibility: .constant(.all)) {
            SidebarView(selectedSection: $selectedSection)
            .navigationSplitViewColumnWidth(min: 180, ideal: 200)
        } content: {
            ContentColumnView(
                selectedSection: selectedSection,
                selectedArticle: $selectedArticle
            )
            .navigationSplitViewColumnWidth(min: 240, ideal: 300)
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
}

#Preview {
    FeedListView()
        .modelContainer(PreviewContainer.shared)
}
