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
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 16) {
                // 标题
                Text(article.title)
                    .font(.title)
                    .fontWeight(.bold)

                // 元信息
                HStack {
                    if let feedTitle = article.feed?.title {
                        Text(feedTitle)
                            .foregroundStyle(Color.accentColor)
                    }

                    if !article.author.isEmpty {
                        Text("·")
                        Text(article.author)
                    }

                    Text("·")
                    Text(article.publishedDate, style: .date)
                }
                .font(.subheadline)
                .foregroundStyle(.secondary)

                // AI 总结区域
                if summarizationService.isAvailable {
                    AISummaryView(
                        service: summarizationService,
                        showSummary: $showSummary,
                        onSummarize: {
                            let content =
                                article.content.isEmpty
                                ? article.articleDescription : article.content
                            Task {
                                await summarizationService.summarize(
                                    title: article.title, content: content)
                            }
                        }
                    )
                }

                Divider()
            }
            .scenePadding()

            // 文章内容
            if !article.content.isEmpty {
                HTMLContentView(html: article.content)
                    .frame(minHeight: 300)
            } else if !article.articleDescription.isEmpty {
                Text(article.articleDescription.stripHTML())
                    .font(.body)
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
                        if summarizationService.summary.isEmpty {
                            let content =
                                article.content.isEmpty
                                ? article.articleDescription : article.content
                            Task {
                                await summarizationService.summarize(
                                    title: article.title, content: content)
                            }
                            showSummary = true
                        } else {
                            showSummary.toggle()
                        }
                    } label: {
                        Image(systemName: "sparkles")
                            .symbolEffect(.pulse, isActive: summarizationService.isLoading)
                    }
                    .help("AI 总结")
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

                if let url = URL(string: article.link) {
                    ShareLink(item: url)

                    Button {
                        openURL(url)
                    } label: {
                        Image(systemName: "safari")
                    }
                }
            }
        }
        .onAppear {
            if !article.isRead {
                article.isRead = true
            }
        }
        .onChange(of: article.id) {
            // 切换文章时清除之前的总结
            summarizationService.clear()
            showSummary = false
        }
    }
}

// MARK: - AI Summary View Component
struct AISummaryView: View {
    var service: SummarizationService
    @Binding var showSummary: Bool
    var onSummarize: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 总结按钮或展开/收起
            Button {
                if service.summary.isEmpty && !service.isLoading {
                    showSummary.toggle()
                }
            } label: {
                VStack {
                    HStack {
                        Label("AI 总结", systemImage: "sparkles")
                            .fontWeight(.medium)

                        Spacer()

                        if service.isLoading {
                            ProgressView()
                                .controlSize(.mini)
                        }
                    }

                    // 总结内容
                    if showSummary {
                        if let error = service.error {
                            Divider()
                            HStack {
                                Image(systemName: "exclamationmark.triangle")
                                    .foregroundStyle(.orange)
                                Text(error)
                                    .font(.callout)
                                    .foregroundStyle(.secondary)
                                Spacer()
                            }
                        } else if !service.summary.isEmpty {
                            Divider()
                            Text(service.summary)
                                .font(.callout)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.purple.opacity(0.1))
                )
            }
            .buttonStyle(.plain)
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
