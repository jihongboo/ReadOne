//
//  RSSHubInstance.swift
//  ReadOne
//
//  Created by Claude on 12/13/25.
//

import Foundation
import SwiftData

@Model
final class RSSHubInstance {
    var name: String
    var baseURL: String
    var isDefault: Bool
    var createdAt: Date

    static let officialURL = "https://rsshub.isrss.com"
    static let officialName = "RSSHub Official"

    init(name: String, baseURL: String, isDefault: Bool = false) {
        self.name = name
        self.baseURL = baseURL.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        self.isDefault = isDefault
        self.createdAt = Date()
    }

    /// 构建完整的 Feed URL
    func buildFeedURL(path: String) -> URL? {
        let normalizedPath = path.hasPrefix("/") ? path : "/\(path)"
        return URL(string: baseURL + normalizedPath)
    }

    /// 构建 API URL
    func buildAPIURL(endpoint: String) -> URL? {
        let normalizedEndpoint = endpoint.hasPrefix("/") ? endpoint : "/\(endpoint)"
        return URL(string: baseURL + normalizedEndpoint)
    }

    /// 创建官方实例
    static func createOfficialInstance() -> RSSHubInstance {
        RSSHubInstance(name: officialName, baseURL: officialURL, isDefault: true)
    }
}
