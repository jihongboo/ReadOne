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

                HStack {
                    if article.isStarred {
                        let star = Text(Image(systemName: "star.fill"))
                            .foregroundStyle(.orange)
                            .font(.caption)
                        Text(verbatim: "\(star) \(article.title)")
                    } else {
                        Text(article.title)
                    }
                }
                .font(.headline)
                .lineLimit(2)
                .foregroundStyle(article.isRead ? .secondary : .primary)

                Text(article.articleDescription.stripHTML())
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(3)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Spacer()

                ViewThatFits(in: .horizontal) {
                    InformationView(article: article, isCompact: false)
                    InformationView(article: article, isCompact: true)
                }
            }

            if let imageURL = article.imageURL {
                GeometryReader { geometry in
                    AsyncImage(url: imageURL) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: geometry.size.height, height: geometry.size.height)
                    } placeholder: {
                        Color.secondary
                            .frame(width: geometry.size.height, height: geometry.size.height)
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
        }
        .frame(height: 80)
    }

    struct InformationView: View {
        let article: Article
        let isCompact: Bool

        var body: some View {
            HStack {
                Text(article.publishedDate, style: .relative)

                if !isCompact, !article.author.isEmpty {
                    Text(verbatim: "·")
                    Text(article.author)
                        .lineLimit(1)
                }
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
    }
}

#Preview("Default") {
    ArticleRowView(article: MockData.sampleArticle, showFeedName: true)
        .modelContainer(PreviewContainer.shared)
        .frame(width: 280)
}

#Preview("Read Article") {
    ArticleRowView(article: MockData.sampleReadArticle)
        .modelContainer(PreviewContainer.shared)
        .frame(width: 280)
}

#Preview("Starred Article") {
    ArticleRowView(article: MockData.sampleStarredArticle, showFeedName: true)
        .modelContainer(PreviewContainer.shared)
        .frame(width: 280)
}
