//
//  ArticleDetailView.swift
//  ReadOne
//
//  Created by 纪洪波 on 11/30/25.
//

import SwiftData
import SwiftUI

struct ArticleDetailView: View {
    @Bindable var article: Article
    @Environment(\.openURL) private var openURL
    
    var body: some View {
        VStack(spacing: 0) {
            // 文章内容（标题、元信息和正文一起滚动）
            if !article.content.isEmpty {
                HTMLContentView(
                    title: article.title,
                    author: article.author,
                    feedTitle: article.feed?.title,
                    publishedDate: article.publishedDate,
                    content: article.content
                )
            } else if !article.articleDescription.isEmpty {
                HTMLContentView(
                    title: article.title,
                    author: article.author,
                    feedTitle: article.feed?.title,
                    publishedDate: article.publishedDate,
                    content: article.articleDescription
                )
            } else {
                ContentUnavailableView(
                    "No Content",
                    systemImage: "doc.text",
                    description: Text("Click the button below to view in browser")
                )
            }
        }
        .navigationTitle(article.title)
#if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
#endif
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                AISummaryButton(article: article)
                
                Button {
                    article.isStarred.toggle()
                } label: {
                    Image(systemName: article.isStarred ? "star.fill" : "star")
                        .foregroundStyle(article.isStarred ? .orange : .primary)
                }
                
                Button {
                    article.isRead.toggle()
                } label: {
                    Image(systemName: article.isRead ? "envelope.open" : "envelope")
                }
                
                ShareLink(item: article.link)
                
                Button {
                    openURL(article.link)
                } label: {
                    Image(systemName: "safari")
                }
            }
        }
        .task(id: article.id) {
            if !article.isRead {
                article.isRead = true
            }
        }
    }
}

#Preview {
    NavigationStack {
        ArticleDetailView(article: MockData.sampleArticle)
    }
    .modelContainer(PreviewContainer.shared)
    .frame(height: 600)
}
