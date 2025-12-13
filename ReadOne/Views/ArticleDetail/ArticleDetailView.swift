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
    @AppStorage(ArticleTextSize.storageKey) private var textSizeRaw: Int = ArticleTextSize.default
        .rawValue

    @State private var translatedTitle: String?
    @State private var translatedContent: String?
    @State private var isTranslated = false

    private var textSize: ArticleTextSize {
        ArticleTextSize(rawValue: textSizeRaw) ?? .medium
    }

    private var originalContent: String {
        article.content.isEmpty ? article.articleDescription : article.content
    }

    private var displayTitle: String {
        isTranslated ? (translatedTitle ?? article.title) : article.title
    }

    private var displayContent: String {
        isTranslated ? (translatedContent ?? originalContent) : originalContent
    }

    var body: some View {
        VStack(spacing: 0) {
            // 文章内容（标题、元信息和正文一起滚动）
            if !article.content.isEmpty || !article.articleDescription.isEmpty {
                HTMLContentView(
                    title: displayTitle,
                    author: article.author,
                    feedTitle: article.feed?.title,
                    publishedDate: article.publishedDate,
                    content: displayContent
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
                // 收藏
                Button {
                    article.isStarred.toggle()
                } label: {
                    Image(systemName: article.isStarred ? "star.fill" : "star")
                        .foregroundStyle(article.isStarred ? .orange : .primary)
                }

                // 分享
                ShareLink(item: article.link)

                // AI 摘要
                AISummaryButton(article: article)

                // 更多操作菜单
                Menu {
                    // 翻译
                    TranslateButton(
                        title: article.title,
                        content: originalContent,
                        translatedTitle: $translatedTitle,
                        translatedContent: $translatedContent,
                        isTranslated: $isTranslated
                    )

                    // 在浏览器中打开
                    Button {
                        openURL(article.link)
                    } label: {
                        Label(String(localized: "Open in Browser"), systemImage: "safari")
                    }

                    Divider()

                    // 已读/未读
                    Button {
                        article.isRead.toggle()
                    } label: {
                        Label(
                            article.isRead
                                ? String(localized: "Mark as Unread")
                                : String(localized: "Mark as Read"),
                            systemImage: article.isRead ? "envelope.badge" : "envelope.open"
                        )
                    }

                    Divider()

                    // 文字大小
                    Menu {
                        ForEach(ArticleTextSize.allCases) { size in
                            Button {
                                textSizeRaw = size.rawValue
                            } label: {
                                HStack {
                                    Text(size.displayName)
                                    if textSize == size {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                    } label: {
                        Label(String(localized: "Text Size"), systemImage: "textformat.size")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .task(id: article.id) {
            if !article.isRead {
                article.isRead = true
            }
            // 切换文章时重置翻译状态
            translatedTitle = nil
            translatedContent = nil
            isTranslated = false
        }
    }
}

#Preview {
    NavigationStack {
        ArticleDetailView(article: MockData.sampleArticle)
    }
    .modelContainer(PreviewContainer.shared)
}
