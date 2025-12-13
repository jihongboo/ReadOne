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

    @AppStorage(ArticleTextSize.storageKey) private var textSizeRaw: Int = ArticleTextSize.default
        .rawValue
    @State private var page = WebPage(navigationDecider: ExternalLinkNavigationDecider())

    private var textSize: ArticleTextSize {
        ArticleTextSize(rawValue: textSizeRaw) ?? .medium
    }

    var body: some View {
        WebView(page)
            .webViewContentBackground(.hidden)
            .task(id: content + String(textSizeRaw)) {
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
                    --accent-color: #007AFF;
                    --text-color: #000;
                    --secondary-text-color: rgba(128, 128, 128, 0.8);
                    --border-color: rgba(128, 128, 128, 0.3);
                    --code-bg: rgba(128, 128, 128, 0.1);
                }
                @media (prefers-color-scheme: dark) {
                    :root {
                        --text-color: #fff;
                        --accent-color: #5E9EF4;
                    }
                }

                /* Base styles */
                body {
                    font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif;
                    font-size: \(textSize.fontSize)px;
                    line-height: 1.6;
                    padding: 24px;
                    margin: 0;
                    color: var(--text-color);
                    background-color: transparent;
                    max-width: 44em;
                }

                /* Text size classes */
                body.smallText { font-size: 14px; }
                body.mediumText { font-size: 17px; }
                body.largeText { font-size: 20px; }
                body.xlargeText { font-size: 24px; }
                body.xxlargeText { font-size: 28px; }

                /* Header styles */
                .article-header {
                    margin-bottom: 24px;
                    padding-bottom: 16px;
                    border-bottom: 1px solid var(--border-color);
                }
                .article-title {
                    font-size: 1.65em;
                    font-weight: bold;
                    line-height: 1.3;
                    margin: 0 0 12px 0;
                }
                .article-meta {
                    font-size: 0.82em;
                    color: var(--secondary-text-color);
                    display: flex;
                    flex-wrap: wrap;
                    align-items: center;
                    gap: 4px;
                }
                .article-meta .feed-title {
                    color: var(--accent-color);
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
                    color: var(--accent-color);
                    text-decoration: none;
                }
                a:hover {
                    text-decoration: underline;
                }
                pre, code {
                    background-color: var(--code-bg);
                    padding: 2px 6px;
                    border-radius: 4px;
                    font-family: 'SF Mono', Menlo, Monaco, monospace;
                    font-size: 0.9em;
                    overflow-x: auto;
                }
                pre {
                    padding: 12px;
                    white-space: pre-wrap;
                    word-wrap: break-word;
                }
                pre code {
                    padding: 0;
                    background: none;
                }
                blockquote {
                    border-left: 3px solid var(--accent-color);
                    margin-left: 0;
                    padding-left: 16px;
                    color: var(--secondary-text-color);
                }
                h1, h2, h3, h4, h5, h6 {
                    margin-top: 1.5em;
                    margin-bottom: 0.5em;
                    line-height: 1.3;
                }

                /* Table styles */
                table {
                    border-collapse: collapse;
                    width: 100%;
                    margin: 1em 0;
                    overflow-x: auto;
                    display: block;
                }
                th, td {
                    border: 1px solid var(--border-color);
                    padding: 8px 12px;
                    text-align: left;
                }
                th {
                    background-color: var(--code-bg);
                }

                /* Responsive iframe wrapper */
                .iframe-wrapper {
                    position: relative;
                    width: 100%;
                    padding-bottom: 56.25%; /* 16:9 */
                    height: 0;
                    overflow: hidden;
                    margin: 1em 0;
                }
                .iframe-wrapper iframe {
                    position: absolute;
                    top: 0;
                    left: 0;
                    width: 100%;
                    height: 100%;
                    border: 0;
                }

                /* Ad filtering - hide common ad elements */
                iframe[src*="feedads"],
                iframe[src*="doubleclick"],
                iframe[src*="googlesyndication"],
                iframe[src*="googleadservices"],
                a[href*="feedads"],
                a[href*="doubleclick"],
                a[href*="plusone.google"],
                .advertisement,
                .ad-container,
                [class*="sponsor"],
                [id*="sponsor"] {
                    display: none !important;
                }

                /* WordPress emoji sizing */
                img.wp-smiley {
                    max-height: 1em;
                    margin: 0;
                    padding: 0;
                    border: none;
                }

                /* Figure and figcaption */
                figure {
                    margin: 1em 0;
                }
                figcaption {
                    font-size: 0.85em;
                    color: var(--secondary-text-color);
                    text-align: center;
                    margin-top: 0.5em;
                }

                /* HR styling */
                hr {
                    border: none;
                    border-top: 1px solid var(--border-color);
                    margin: 2em 0;
                }

                /* List styling */
                ul, ol {
                    padding-left: 1.5em;
                }
                li {
                    margin: 0.25em 0;
                }
            </style>
        </head>
        <body class="\(textSize.cssClass)">
            <header class="article-header">
                <h1 class="article-title">\(title.escapedForHTML)</h1>
                <div class="article-meta">\(metaInfo)</div>
            </header>
            <article>
                \(content)
            </article>
            <script>
                // 内容处理脚本
                (function() {
                    // 让 iframe 响应式
                    function wrapFrames() {
                        document.querySelectorAll('iframe').forEach(function(iframe) {
                            if (iframe.closest('.iframe-wrapper')) return;
                            if (!iframe.width && !iframe.height) {
                                var wrapper = document.createElement('div');
                                wrapper.className = 'iframe-wrapper';
                                iframe.parentNode.insertBefore(wrapper, iframe);
                                wrapper.appendChild(iframe);
                            }
                        });
                    }

                    // 视频添加 playsinline 防止自动全屏
                    function inlineVideos() {
                        document.querySelectorAll('video').forEach(function(video) {
                            video.setAttribute('playsinline', '');
                            video.setAttribute('webkit-playsinline', '');
                        });
                    }

                    // 移除可能破坏阅读体验的内联样式
                    function stripStyles() {
                        var propsToRemove = ['color', 'background', 'background-color', 'font-family', 'font-size'];
                        document.querySelectorAll('article *').forEach(function(el) {
                            propsToRemove.forEach(function(prop) {
                                el.style.removeProperty(prop);
                            });
                        });
                    }

                    // 宽表格添加滚动
                    function wrapTables() {
                        document.querySelectorAll('table').forEach(function(table) {
                            if (table.closest('.table-wrapper')) return;
                            var wrapper = document.createElement('div');
                            wrapper.style.overflowX = 'auto';
                            wrapper.className = 'table-wrapper';
                            table.parentNode.insertBefore(wrapper, table);
                            wrapper.appendChild(table);
                        });
                    }

                    // 处理相对路径图片
                    function fixRelativeImages() {
                        document.querySelectorAll('img[src^="/"]').forEach(function(img) {
                            // 相对路径图片无法显示，添加提示
                            img.alt = img.alt || '[Image]';
                        });
                    }

                    // 执行所有处理
                    wrapFrames();
                    inlineVideos();
                    stripStyles();
                    wrapTables();
                    fixRelativeImages();
                })();
            </script>
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
