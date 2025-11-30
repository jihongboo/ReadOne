//
//  HTMLContentView.swift
//  ReadOne
//
//  Created by 纪洪波 on 11/30/25.
//

import SwiftUI
import WebKit

struct HTMLContentView: View {
    let html: String

    @State private var page = WebPage(navigationDecider: ExternalLinkNavigationDecider())

    var body: some View {
        WebView(page)
            .webViewContentBackground(.hidden)
            .onAppear {
                page.load(html: styledHTML, baseURL: URL(string: "about:blank")!)
            }
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
            \(html)
        </body>
        </html>
        """
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
    HTMLContentView(html: MockData.sampleHTMLContent)
}
