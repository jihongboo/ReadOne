//
//  StarredArticlesView.swift
//  ReadOne
//
//  Created by 纪洪波 on 11/30/25.
//

import SwiftData
import SwiftUI

struct StarredArticlesView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.openWindow) private var openWindow
    @Query(
        filter: #Predicate<Article> { $0.isStarred },
        sort: \Article.publishedDate,
        order: .reverse
    ) private var articles: [Article]
    @Binding var selectedArticle: Article?

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
        .navigationTitle("Starred")
        .overlay {
            if articles.isEmpty {
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

#Preview {
    NavigationStack {
        StarredArticlesView(selectedArticle: .constant(nil))
    }
    .modelContainer(PreviewContainer.shared)
}
