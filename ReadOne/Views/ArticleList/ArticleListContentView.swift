//
//  ArticleListContentView.swift
//  ReadOne
//
//  Created by 纪洪波 on 11/30/25.
//

import SwiftData
import SwiftUI

// MARK: - 文章列表视图（用于全部文章和收藏）
struct ArticleListContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.openWindow) private var openWindow
    let articles: [Article]
    let title: String
    @Binding var selectedArticle: Article?
    var showEmpty: Bool = false

    var body: some View {
        List(selection: $selectedArticle) {
            ForEach(articles) { article in
                ArticleRowView(article: article, showFeedName: true)
                    .tag(article)
                    .contextMenu {
                        Button("Open in New Window") {
                            openWindow(value: article.persistentModelID)
                        }
                        Divider()
                        Button("Delete", role: .destructive) {
                            deleteArticle(article)
                        }
                    }
                    .onDoubleClick {
                        openWindow(value: article.persistentModelID)
                    }
            }
            .onDelete(perform: deleteArticles)
        }
        .focusedSceneValue(\.selectedArticle, selectedArticle)
        .navigationTitle(title)
        .overlay {
            if showEmpty && articles.isEmpty {
                ContentUnavailableView(
                    "No Starred Articles",
                    systemImage: "star",
                    description: Text("Starred articles will appear here")
                )
            }
        }
    }

    private func deleteArticles(at offsets: IndexSet) {
        for index in offsets {
            let article = articles[index]
            if selectedArticle == article {
                selectedArticle = nil
            }
            modelContext.delete(article)
        }
    }

    private func deleteArticle(_ article: Article) {
        if selectedArticle == article {
            selectedArticle = nil
        }
        modelContext.delete(article)
    }
}

#Preview("With Articles") {
    NavigationStack {
        ArticleListContentView(
            articles: MockData.sampleFeed.articles,
            title: "全部文章",
            selectedArticle: .constant(nil)
        )
    }
    .modelContainer(PreviewContainer.shared)
}

#Preview("Empty") {
    NavigationStack {
        ArticleListContentView(
            articles: [],
            title: "收藏",
            selectedArticle: .constant(nil),
            showEmpty: true
        )
    }
    .modelContainer(PreviewContainer.shared)
}
