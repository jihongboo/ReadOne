//
//  ArticleDetailView.swift
//  ReadOne
//
//  Created by 纪洪波 on 11/30/25.
//

import SwiftData
import SwiftUI
import Translation

struct ArticleDetailView: View {
    @Bindable var article: Article
    @Environment(\.openURL) private var openURL

    @State private var translationConfiguration: TranslationSession.Configuration?
    @State private var translatedTitle: String?
    @State private var translatedContent: String?
    @State private var isTranslated = false

    private var displayTitle: String {
        isTranslated ? (translatedTitle ?? article.title) : article.title
    }

    private var displayContent: String {
        let originalContent = article.content.isEmpty ? article.articleDescription : article.content
        return isTranslated ? (translatedContent ?? originalContent) : originalContent
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
                AISummaryButton(article: article)

                Button {
                    if isTranslated {
                        isTranslated = false
                    } else {
                        triggerTranslation()
                    }
                } label: {
                    Image(systemName: "translate")
                        .foregroundStyle(isTranslated ? Color.accentColor : .primary)
                }

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
        .translationTask(translationConfiguration) { @MainActor session in
            let originalContent =
                article.content.isEmpty ? article.articleDescription : article.content

            let requests = [
                TranslationSession.Request(sourceText: article.title),
                TranslationSession.Request(sourceText: originalContent.strippingHTML()),
            ]

            do {
                let responses = try await session.translations(from: requests)
                if responses.count >= 2 {
                    translatedTitle = responses[0].targetText
                    translatedContent = responses[1].targetText
                    isTranslated = true
                }
            } catch {
                print("Translation failed: \(error)")
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

    private func triggerTranslation() {
        if translatedContent != nil {
            // 已有翻译结果，直接显示
            isTranslated = true
        } else {
            // 触发翻译
            translationConfiguration = .init()
        }
    }
}

// MARK: - String Extension for HTML Stripping

extension String {
    func strippingHTML() -> String {
        guard let data = self.data(using: .utf8) else { return self }

        let options: [NSAttributedString.DocumentReadingOptionKey: Any] = [
            .documentType: NSAttributedString.DocumentType.html,
            .characterEncoding: String.Encoding.utf8.rawValue,
        ]

        if let attributedString = try? NSAttributedString(
            data: data, options: options, documentAttributes: nil)
        {
            return attributedString.string
        }

        return self.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
    }
}

#Preview {
    NavigationStack {
        ArticleDetailView(article: MockData.sampleArticle)
    }
    .modelContainer(PreviewContainer.shared)
    .frame(height: 600)
}
