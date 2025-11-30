//
//  ArticleRowView.swift
//  ReadOne
//
//  Created by 纪洪波 on 11/30/25.
//

import SwiftData
import SwiftUI

struct ArticleRowView: View {
    let article: Article
    var showFeedName: Bool = false

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                if showFeedName, let feedTitle = article.feed?.title {
                    Text(feedTitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Text(article.title)
                    .font(.headline)
                    .lineLimit(2)
                    .foregroundStyle(article.isRead ? .secondary : .primary)

                Text(article.articleDescription.stripHTML())
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .frame(maxWidth: .infinity, alignment: .leading)

                HStack {
                    Text(article.publishedDate, style: .relative)

                    if !article.author.isEmpty {
                        Text("·")
                        Text(article.author)
                    }

                    if article.isStarred {
                        Spacer()
                        Image(systemName: "star.fill")
                            .foregroundStyle(.orange)
                            .font(.caption)
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            if let imageURL = article.imageURL, let url = URL(string: imageURL) {
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Color.gray.opacity(0.2)
                }
                .frame(width: 80, height: 80)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview("Default") {
    ArticleRowView(article: MockData.sampleArticle, showFeedName: true)
        .modelContainer(PreviewContainer.shared)
}

#Preview("Read Article") {
    ArticleRowView(article: MockData.sampleReadArticle)
        .modelContainer(PreviewContainer.shared)
}

#Preview("Starred Article") {
    ArticleRowView(article: MockData.sampleStarredArticle, showFeedName: true)
        .modelContainer(PreviewContainer.shared)
}
