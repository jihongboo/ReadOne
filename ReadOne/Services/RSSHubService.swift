//
//  RSSHubService.swift
//  ReadOne
//
//  Created by Claude on 12/13/25.
//

import Foundation
import SwiftUI

enum RSSHubError: LocalizedError {
    case invalidURL
    case networkError(Error)
    case parseError(Error)
    case noData
    case instanceUnavailable

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return String(localized: "Invalid RSSHub URL")
        case .networkError(let error):
            return String(localized: "Network error: \(error.localizedDescription)")
        case .parseError(let error):
            return String(localized: "Parse error: \(error.localizedDescription)")
        case .noData:
            return String(localized: "No data received")
        case .instanceUnavailable:
            return String(localized: "RSSHub instance is unavailable")
        }
    }
}

@Observable
@MainActor
final class RSSHubService {
    private var cachedRoutes: [String: [RSSHubRouteItem]] = [:]
    private var allRoutes: [RSSHubRouteItem]?

    init() {}

    // MARK: - Public Methods

    /// 获取热门分类路由
    func fetchPopularCategories(from instance: RSSHubInstance) async throws -> [RSSHubCategoryItem]
    {
        guard let url = instance.buildAPIURL(endpoint: "/api/category/popular") else {
            throw RSSHubError.invalidURL
        }

        let data: Data
        do {
            let (responseData, response) = try await URLSession.shared.data(from: url)
            if let httpResponse = response as? HTTPURLResponse {
                guard httpResponse.statusCode == 200 else {
                    throw RSSHubError.instanceUnavailable
                }
            }
            data = responseData
        } catch let error as RSSHubError {
            throw error
        } catch {
            throw RSSHubError.networkError(error)
        }

        guard !data.isEmpty else {
            return []
        }

        do {
            let decoder = JSONDecoder()
            let response = try decoder.decode([String: RSSHubCategoryData].self, from: data)
            return parsePopularCategories(from: response)
        } catch {
            throw RSSHubError.parseError(error)
        }
    }

    private func parsePopularCategories(from response: [String: RSSHubCategoryData])
        -> [RSSHubCategoryItem]
    {
        var items: [RSSHubCategoryItem] = []

        for (namespace, categoryData) in response {
            let routes = categoryData.routes.map { (_, detail) in
                // 转换参数格式
                var parameters: [String: RSSHubParameter]? = nil
                if let params = detail.parameters {
                    parameters = [:]
                    for (key, value) in params {
                        switch value {
                        case .string(let desc):
                            parameters?[key] = RSSHubParameter(
                                description: desc, options: nil, default: nil)
                        case .object(let obj):
                            parameters?[key] = RSSHubParameter(
                                description: obj.description,
                                options: obj.options?.compactMap { opt in
                                    guard let v = opt.value, let l = opt.label else { return nil }
                                    return RSSHubParameterOption(value: v, label: l)
                                },
                                default: obj.default
                            )
                        }
                    }
                }

                return RSSHubRouteItem(
                    namespace: namespace,
                    path: detail.pathString,
                    detail: RSSHubRouteDetail(
                        path: detail.pathString,
                        name: detail.name ?? "",
                        categories: detail.categories,
                        maintainers: detail.maintainers,
                        description: detail.description,
                        parameters: parameters,
                        features: nil,
                        example: detail.example
                    )
                )
            }

            let item = RSSHubCategoryItem(
                namespace: namespace,
                name: categoryData.name,
                url: categoryData.url ?? "",
                description: categoryData.description ?? "",
                routes: routes
            )
            items.append(item)
        }

        return items.sorted { $0.name < $1.name }
    }

    /// 获取所有路由
    func fetchAllRoutes(from instance: RSSHubInstance) async throws -> [RSSHubRouteItem] {
        if let cached = allRoutes {
            return cached
        }

        guard let url = instance.buildAPIURL(endpoint: "/api/routes") else {
            throw RSSHubError.invalidURL
        }

        let routes = try await fetchRoutes(from: url)
        allRoutes = routes
        return routes
    }

    /// 获取指定分类的路由（使用旧接口）
    func fetchRoutes(category: String, from instance: RSSHubInstance) async throws
        -> [RSSHubRouteItem]
    {
        if let cached = cachedRoutes[category] {
            return cached
        }

        guard let url = instance.buildAPIURL(endpoint: "/api/routes/\(category)") else {
            throw RSSHubError.invalidURL
        }

        let routes = try await fetchRoutes(from: url)
        cachedRoutes[category] = routes
        return routes
    }

    /// 获取指定分类的路由（使用 /api/category/<category> 接口）
    func fetchCategoryRoutes(category: String, from instance: RSSHubInstance) async throws
        -> [RSSHubCategoryItem]
    {
        guard
            let url = instance.buildAPIURL(endpoint: "/api/category/\(category)")
        else {
            throw RSSHubError.invalidURL
        }

        let data: Data
        do {
            let (responseData, response) = try await URLSession.shared.data(from: url)
            if let httpResponse = response as? HTTPURLResponse {
                guard httpResponse.statusCode == 200 else {
                    throw RSSHubError.instanceUnavailable
                }
            }
            data = responseData
        } catch let error as RSSHubError {
            throw error
        } catch {
            throw RSSHubError.networkError(error)
        }

        guard !data.isEmpty else {
            return []
        }

        do {
            let decoder = JSONDecoder()
            let response = try decoder.decode([String: RSSHubCategoryData].self, from: data)
            return parsePopularCategories(from: response)
        } catch {
            throw RSSHubError.parseError(error)
        }
    }

    /// 搜索路由
    func searchRoutes(keyword: String, from instance: RSSHubInstance) async throws
        -> [RSSHubRouteItem]
    {
        let allRoutes = try await fetchAllRoutes(from: instance)
        let lowercasedKeyword = keyword.lowercased()

        return allRoutes.filter { route in
            route.name.lowercased().contains(lowercasedKeyword)
                || route.namespace.lowercased().contains(lowercasedKeyword)
                || route.description.lowercased().contains(lowercasedKeyword)
                || route.path.lowercased().contains(lowercasedKeyword)
        }
    }

    /// 验证实例是否可用
    func validateInstance(_ instance: RSSHubInstance) async throws -> Bool {
        guard let url = instance.buildAPIURL(endpoint: "/") else {
            throw RSSHubError.invalidURL
        }

        do {
            let (_, response) = try await URLSession.shared.data(from: url)
            guard let httpResponse = response as? HTTPURLResponse else {
                return false
            }
            return httpResponse.statusCode == 200
        } catch {
            throw RSSHubError.networkError(error)
        }
    }

    /// 清除缓存
    func clearCache() {
        cachedRoutes.removeAll()
        allRoutes = nil
    }

    // MARK: - Private Methods

    private func fetchRoutes(from url: URL) async throws -> [RSSHubRouteItem] {
        let data: Data
        do {
            let (responseData, response) = try await URLSession.shared.data(from: url)

            // 检查 HTTP 状态码
            if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode == 204 {
                    // 没有匹配的路由
                    return []
                }
                guard httpResponse.statusCode == 200 else {
                    throw RSSHubError.instanceUnavailable
                }
            }

            data = responseData
        } catch let error as RSSHubError {
            throw error
        } catch {
            throw RSSHubError.networkError(error)
        }

        guard !data.isEmpty else {
            return []
        }

        do {
            let decoder = JSONDecoder()
            let response = try decoder.decode(RSSHubRoutesResponse.self, from: data)
            return parseRoutes(from: response)
        } catch {
            throw RSSHubError.parseError(error)
        }
    }

    private func parseRoutes(from response: RSSHubRoutesResponse) -> [RSSHubRouteItem] {
        var items: [RSSHubRouteItem] = []

        for (namespace, namespaceData) in response.data {
            for (_, routeDetail) in namespaceData.routes {
                let item = RSSHubRouteItem(
                    namespace: namespace,
                    path: routeDetail.path,
                    detail: routeDetail
                )
                items.append(item)
            }
        }

        // 按命名空间和名称排序
        return items.sorted { ($0.namespace, $0.name) < ($1.namespace, $1.name) }
    }
}

// MARK: - Environment Key

extension EnvironmentValues {
    @Entry var rssHubService = RSSHubService()
}
