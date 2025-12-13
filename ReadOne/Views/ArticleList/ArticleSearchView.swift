//
//  ArticleSearchView.swift
//  ReadOne
//
//  Created by 纪洪波 on 12/14/25.
//

import SwiftData
import SwiftUI

struct ArticleSearchView: View {
    @Query(sort: \Article.publishedDate, order: .reverse) private var articles: [Article]
    @Binding var selectedArticle: Article?
    @State private var searchText = ""

    private var searchResults: [Article] {
        guard !searchText.isEmpty else { return [] }
        return articles.filter {
            $0.title.localizedCaseInsensitiveContains(searchText)
                || $0.articleDescription.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        Group {
            if searchText.isEmpty {
                ContentUnavailableView {
                    Label("Search Articles", systemImage: "magnifyingglass")
                } description: {
                    Text("Search articles by title or content")
                }
            } else if searchResults.isEmpty {
                ContentUnavailableView {
                    Label("No Results", systemImage: "magnifyingglass")
                } description: {
                    Text("No articles found for \"\(searchText)\"")
                }
            } else {
                List(selection: $selectedArticle) {
                    ForEach(searchResults) { article in
                        ArticleRowView(
                            article: article,
                            showFeedName: true,
                            selectedArticle: $selectedArticle
                        )
                    }
                }
            }
        }
        #if os(iOS)
            .navigationDestination(for: Article.self) { article in
                ArticleDetailView(article: article)
                .onAppear {
                    article.isRead = true
                }
            }
        #endif
        .navigationTitle("Search")
        .searchable(text: $searchText, prompt: "Search articles...")
    }
}

#Preview {
    NavigationStack {
        ArticleSearchView(selectedArticle: .constant(nil))
    }
    .modelContainer(PreviewContainer.shared)
}
