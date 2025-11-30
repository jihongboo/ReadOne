//
//  RSSService.swift
//  ReadOne
//
//  Created by 纪洪波 on 11/30/25.
//

import Foundation
import RSParser

enum RSSError: LocalizedError {
    case invalidURL
    case networkError(Error)
    case parseError(Error)
    case noData
    case unsupportedFeed

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return String(localized: "Invalid URL")
        case .networkError(let error):
            return String(localized: "Network error: \(error.localizedDescription)")
        case .parseError(let error):
            return String(localized: "Parse error: \(error.localizedDescription)")
        case .noData:
            return String(localized: "No data")
        case .unsupportedFeed:
            return String(localized: "Unsupported feed format")
        }
    }
}

struct ParsedFeedResult {
    let title: String
    let description: String
    let imageURL: URL?
    let articles: [ParsedArticleResult]
}

struct ParsedArticleResult {
    let title: String
    let link: URL?
    let description: String
    let content: String
    let author: String
    let publishedDate: Date
    let guid: String
    let imageURL: URL?
}

class RSSService {
    static let shared = RSSService()

    private init() {}

    func fetchFeed(from url: URL) async throws -> ParsedFeedResult {
        let data: Data
        do {
            let (responseData, _) = try await URLSession.shared.data(from: url)
            data = responseData
        } catch {
            throw RSSError.networkError(error)
        }

        guard !data.isEmpty else {
            throw RSSError.noData
        }

        return try parseFeedData(data, url: url.absoluteString)
    }

    private func parseFeedData(_ data: Data, url: String) throws -> ParsedFeedResult {
        let parserData = ParserData(url: url, data: data)

        let parsedFeed: RSParser.ParsedFeed
        do {
            guard let result = try FeedParser.parse(parserData) else {
                throw RSSError.unsupportedFeed
            }
            parsedFeed = result
        } catch let error as RSSError {
            throw error
        } catch {
            throw RSSError.parseError(error)
        }

        let articles = parsedFeed.items.map { item -> ParsedArticleResult in
            let imageURL = extractImageURL(from: item)

            return ParsedArticleResult(
                title: item.title ?? String(localized: "Untitled"),
                link: URL(string: item.url ?? item.externalURL ?? ""),
                description: item.summary ?? "",
                content: item.contentHTML ?? item.contentText ?? item.summary ?? "",
                author: item.authors?.first?.name ?? "",
                publishedDate: item.datePublished ?? item.dateModified ?? Date(),
                guid: item.uniqueID,
                imageURL: imageURL.flatMap { URL(string: $0) }
            )
        }

        // 获取图标 URL，如果 feed 没有提供则使用网站 favicon
        var imageURL: URL? = parsedFeed.iconURL.flatMap { URL(string: $0) }

        if imageURL == nil, let feedURL = URL(string: url),
            let host = feedURL.host
        {
            // 使用 Google Favicon 服务作为备选
            imageURL = URL(string: "https://www.google.com/s2/favicons?domain=\(host)&sz=128")
        }

        return ParsedFeedResult(
            title: parsedFeed.title ?? String(localized: "Unknown Feed"),
            description: parsedFeed.homePageURL ?? "",
            imageURL: imageURL,
            articles: articles
        )
    }

    private func extractImageURL(from item: RSParser.ParsedItem) -> String? {
        if let imageURL = item.imageURL {
            return imageURL
        }

        if let bannerImageURL = item.bannerImageURL {
            return bannerImageURL
        }

        // 尝试从content中提取图片
        if let content = item.contentHTML {
            return extractFirstImageURL(from: content)
        }

        return nil
    }

    private func extractFirstImageURL(from html: String) -> String? {
        let pattern = #"<img[^>]+src=[\"']([^\"']+)[\"']"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive)
        else {
            return nil
        }

        let range = NSRange(html.startIndex..., in: html)
        guard let match = regex.firstMatch(in: html, options: [], range: range) else {
            return nil
        }

        guard let urlRange = Range(match.range(at: 1), in: html) else {
            return nil
        }

        return String(html[urlRange])
    }
}
