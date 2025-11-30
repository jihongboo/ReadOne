//
//  HTMLContentView.swift
//  ReadOne
//
//  Created by 纪洪波 on 11/30/25.
//

import SwiftUI
import WebKit

struct HTMLContentView: View {
    let title: String
    let author: String
    let feedTitle: String?
    let publishedDate: Date
    let content: String

    @State private var page = WebPage(navigationDecider: ExternalLinkNavigationDecider())

    var body: some View {
        WebView(page)
            .webViewContentBackground(.hidden)
            .task(id: content) {
                page.load(html: styledHTML, baseURL: URL(string: "about:blank")!)
            }
    }

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: publishedDate)
    }

    private var metaInfo: String {
        var parts: [String] = []
        if let feedTitle, !feedTitle.isEmpty {
            parts.append("<span class=\"feed-title\">\(feedTitle.escapedForHTML)</span>")
        }
        if !author.isEmpty {
            parts.append("<span class=\"author\">\(author.escapedForHTML)</span>")
        }
        parts.append("<span class=\"date\">\(formattedDate)</span>")
        return parts.joined(separator: "<span class=\"separator\">·</span>")
    }

    private var styledHTML: String {
        """
        <!DOCTYPE html>
        <html>
        <head>
            <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
            <style>
                :root {
                    color-scheme: light dark;
                }
                body {
                    font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif;
                    font-size: 17px;
                    line-height: 1.6;
                    padding: 24px;
                    margin: 0;
                    color: var(--text-color, #000);
                    background-color: transparent;
                }
                @media (prefers-color-scheme: dark) {
                    body {
                        --text-color: #fff;
                    }
                }
                /* Header styles */
                .article-header {
                    margin-bottom: 24px;
                    padding-bottom: 16px;
                    border-bottom: 1px solid rgba(128, 128, 128, 0.3);
                }
                .article-title {
                    font-size: 28px;
                    font-weight: bold;
                    line-height: 1.3;
                    margin: 0 0 12px 0;
                }
                .article-meta {
                    font-size: 14px;
                    color: rgba(128, 128, 128, 0.8);
                    display: flex;
                    flex-wrap: wrap;
                    align-items: center;
                    gap: 4px;
                }
                .article-meta .feed-title {
                    color: #007AFF;
                }
                .article-meta .separator {
                    margin: 0 4px;
                }
                /* Content styles */
                img {
                    max-width: 100%;
                    height: auto;
                    border-radius: 8px;
                }
                a {
                    color: #007AFF;
                    text-decoration: none;
                }
                pre, code {
                    background-color: rgba(128, 128, 128, 0.1);
                    padding: 2px 6px;
                    border-radius: 4px;
                    font-family: 'SF Mono', Menlo, Monaco, monospace;
                    font-size: 14px;
                    overflow-x: auto;
                }
                pre {
                    padding: 12px;
                }
                blockquote {
                    border-left: 3px solid #007AFF;
                    margin-left: 0;
                    padding-left: 16px;
                    color: rgba(128, 128, 128, 0.8);
                }
                h1, h2, h3, h4, h5, h6 {
                    margin-top: 1.5em;
                    margin-bottom: 0.5em;
                }
            </style>
        </head>
        <body>
            <header class="article-header">
                <h1 class="article-title">\(title.escapedForHTML)</h1>
                <div class="article-meta">\(metaInfo)</div>
            </header>
            <article>
                \(content)
            </article>
        </body>
        </html>
        """
    }
}

// MARK: - String Extension for HTML Escaping

extension String {
    fileprivate var escapedForHTML: String {
        self.replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
            .replacingOccurrences(of: "'", with: "&#39;")
    }
}

// MARK: - Navigation Decider

class ExternalLinkNavigationDecider: WebPage.NavigationDeciding {
    func decidePolicy(
        for action: WebPage.NavigationAction,
        preferences: inout WebPage.NavigationPreferences
    ) async -> WKNavigationActionPolicy {
        if action.navigationType == .linkActivated, let url = action.request.url {
            #if os(iOS)
                await UIApplication.shared.open(url)
            #else
                NSWorkspace.shared.open(url)
            #endif
            return .cancel
        }
        return .allow
    }
}

#Preview {
    HTMLContentView(
        title: "Sample Article Title",
        author: "John Doe",
        feedTitle: "Tech Blog",
        publishedDate: Date(),
        content: MockData.sampleHTMLContent
    )
}
