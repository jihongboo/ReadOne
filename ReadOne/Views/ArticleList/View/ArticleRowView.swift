//
//  ArticleRowView.swift
//  ReadOne
//
//  Created by 纪洪波 on 11/30/25.
//

import SwiftData
import SwiftUI

struct ArticleRowView: View {
    @Environment(\.modelContext) private var modelContext
    #if os(macOS)
        @Environment(\.openWindow) private var openWindow
    #endif
    #if os(iOS)
        @Environment(\.navigationPath) private var path
        @Environment(\.horizontalSizeClass) private var horizontalSizeClass

        private var isCompact: Bool {
            horizontalSizeClass == .compact
        }
    #endif

    let article: Article
    var showFeedName: Bool = false
    @Binding var selectedArticle: Article?

    var body: some View {
        Button {
            #if os(iOS)
                if isCompact {
                    path.wrappedValue.append(article)
                } else {
                    selectedArticle = article
                }
            #else
                selectedArticle = article
            #endif
        } label: {
            rowContent
        }
        .buttonStyle(.plain)
        .tag(article)
        .contentShape(Rectangle())
        #if os(iOS)
            .onTapGesture {
                if isCompact {
                    path.wrappedValue.append(article)
                } else {
                    selectedArticle = article
                }
            }
        #endif
        .contextMenu {
            #if os(macOS)
                Button("Open in New Window") {
                    openWindow(value: article.persistentModelID)
                }
                Divider()
            #endif
            starButton
            readButton
            Divider()
            deleteButton
        } preview: {
            ArticleDetailView(article: article)
                .frame(width: 350, height: 500)
        }
        #if os(iOS)
            .swipeActions(edge: .trailing) {
                deleteButton
            }
            .swipeActions(edge: .leading) {
                starButton
                .tint(.orange)
                readButton
                .tint(.blue)
            }
        #endif
    }

    private var rowContent: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading) {
                if showFeedName, let feedTitle = article.feed?.title {
                    Text(feedTitle)
                        .font(.caption)
                        .lineLimit(1)
                        .foregroundStyle(.secondary)
                }

                HStack {
                    if article.isStarred {
                        let star = Text(Image(systemName: "star.fill"))
                            .foregroundStyle(.orange)
                            .font(.caption)
                        Text(verbatim: "\(star) \(article.title)")
                            .lineLimit(1)
                    } else {
                        Text(article.title)
                            .lineLimit(1)
                    }
                }
                .font(.headline)
                .lineLimit(2)
                .foregroundStyle(article.isRead ? .secondary : .primary)

                Text(article.articleDescription.stripHTML())
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2, reservesSpace: true)
                    .frame(maxWidth: .infinity, alignment: .leading)

                ViewThatFits(in: .horizontal) {
                    InformationView(article: article, isCompact: false)
                    InformationView(article: article, isCompact: true)
                }
            }

            Spacer()

            if let imageURL = article.imageURL {
                AsyncImage(url: imageURL) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 80, height: 80)
                } placeholder: {
                    Color.secondary
                        .frame(width: 80, height: 80)
                }
                .clipShape(.rect(corners: .concentric, isUniform: true))
            }
        }
    }

    // MARK: - Action Buttons

    private var starButton: some View {
        Button {
            article.isStarred.toggle()
        } label: {
            Label(
                article.isStarred ? "Unstar" : "Star",
                systemImage: article.isStarred ? "star.slash" : "star.fill")
        }
    }

    private var readButton: some View {
        Button {
            article.isRead.toggle()
        } label: {
            Label(
                article.isRead ? "Mark as Unread" : "Mark as Read",
                systemImage: article.isRead ? "envelope.badge" : "envelope.open")
        }
    }

    private var deleteButton: some View {
        Button(role: .destructive) {
            if selectedArticle == article {
                selectedArticle = nil
            }
            modelContext.delete(article)
        } label: {
            Label("Delete", systemImage: "trash")
        }
    }

    struct InformationView: View {
        let article: Article
        let isCompact: Bool

        var body: some View {
            HStack(spacing: 4) {
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

// MARK: - Previews

#Preview("Default") {
    List {
        ArticleRowView(
            article: MockData.sampleArticle, showFeedName: true, selectedArticle: .constant(nil))
        ArticleRowView(
            article: MockData.sampleArticle, showFeedName: true, selectedArticle: .constant(nil))
    }
    .modelContainer(PreviewContainer.shared)
}

#Preview("Read Article") {
    ArticleRowView(article: MockData.sampleReadArticle, selectedArticle: .constant(nil))
        .modelContainer(PreviewContainer.shared)
}

#Preview("Starred Article") {
    ArticleRowView(
        article: MockData.sampleStarredArticle, showFeedName: true, selectedArticle: .constant(nil)
    )
    .modelContainer(PreviewContainer.shared)
}
