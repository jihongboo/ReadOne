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
    @State private var summarizationService = SummarizationService()
    @State private var showSummary = false

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
                // AI 总结按钮
                if summarizationService.isAvailable {
                    Button {
                        if summarizationService.summary.isEmpty && !summarizationService.isLoading {
                            let content =
                                article.content.isEmpty
                                ? article.articleDescription : article.content
                            Task {
                                await summarizationService.summarize(
                                    title: article.title, content: content)
                            }
                        }
                        showSummary = true
                    } label: {
                        Image(systemName: "apple.intelligence")
                            .symbolEffect(.pulse, isActive: summarizationService.isLoading)
                            .foregroundStyle(
                                (showSummary && !summarizationService.isLoading)
                                    ? .orange : .primary)
                    }
                    .help("AI 总结")
                    .popover(isPresented: $showSummary) {
                        AISummaryPopoverView(service: summarizationService)
                    }
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
        .task(id: article.id) {
            if !article.isRead {
                article.isRead = true
            }
            // 切换文章时清除之前的总结
            summarizationService.clear()
            showSummary = false
        }
    }
}

// MARK: - AI Summary Popover View
struct AISummaryPopoverView: View {
    var service: SummarizationService

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Label("AI 总结", systemImage: "sparkles")
                        .font(.headline)

                    Spacer()

                    if service.isLoading {
                        ProgressView()
                            .controlSize(.small)
                    }
                }

                Divider()

                if let error = service.error {
                    HStack(alignment: .top) {
                        Image(systemName: "exclamationmark.triangle")
                            .foregroundStyle(.orange)
                        Text(error)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                } else if service.isLoading {
                    Text("正在生成总结...")
                        .foregroundStyle(.secondary)
                } else if !service.summary.isEmpty {
                    Text(service.summary)
                        .fixedSize(horizontal: false, vertical: true)
                } else {
                    Text("暂无总结")
                        .foregroundStyle(.secondary)
                }
            }
            .padding()
        }
        .frame(width: 350, height: 400)
    }
}

#Preview {
    NavigationStack {
        ArticleDetailView(article: MockData.sampleArticle)
    }
    .modelContainer(PreviewContainer.shared)
    .frame(height: 600)
}
