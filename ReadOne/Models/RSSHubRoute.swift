//
//  RSSHubRoute.swift
//  ReadOne
//
//  Created by Claude on 12/13/25.
//

import Foundation

// MARK: - API Response Models

/// RSSHub /api/routes 响应
struct RSSHubRoutesResponse: Codable {
    let data: [String: RSSHubNamespace]
}

/// 命名空间（如 bilibili, weibo 等）
struct RSSHubNamespace: Codable {
    let routes: [String: RSSHubRouteDetail]
}

/// 路由详情
struct RSSHubRouteDetail: Codable, Identifiable {
    let path: String
    let name: String
    let categories: [String]?
    let maintainers: [String]?
    let description: String?
    let parameters: [String: RSSHubParameter]?
    let features: RSSHubFeatures?
    let example: String?

    var id: String { path }

    enum CodingKeys: String, CodingKey {
        case path, name, categories, maintainers, description, parameters, features, example
    }
}

/// 路由参数
struct RSSHubParameter: Codable {
    let description: String?
    let options: [RSSHubParameterOption]?
    let `default`: String?
}

/// 参数选项
struct RSSHubParameterOption: Codable {
    let value: String
    let label: String
}

/// 路由特性
struct RSSHubFeatures: Codable {
    let requireConfig: Bool?
    let requirePuppeteer: Bool?
    let antiCrawler: Bool?
    let supportBT: Bool?
    let supportPodcast: Bool?
    let supportScihub: Bool?
}

// MARK: - Display Models

/// 用于 UI 显示的路由模型
struct RSSHubRouteItem: Identifiable, Hashable {
    let id: String
    let namespace: String
    let path: String
    let name: String
    let description: String
    let categories: [String]
    let parameters: [RSSHubRouteParameter]
    let example: String?

    init(namespace: String, path: String, detail: RSSHubRouteDetail) {
        self.id = "\(namespace)\(path)"
        self.namespace = namespace
        self.path = path
        self.name = detail.name
        self.description = detail.description ?? ""
        self.categories = detail.categories ?? []
        self.example = detail.example

        // 解析路径中的参数
        self.parameters = RSSHubRouteItem.parseParameters(
            from: path,
            definitions: detail.parameters
        )
    }

    /// 从路径解析参数
    private static func parseParameters(
        from path: String,
        definitions: [String: RSSHubParameter]?
    ) -> [RSSHubRouteParameter] {
        let pattern = #":(\w+)(\?)?"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else {
            return []
        }

        let range = NSRange(path.startIndex..., in: path)
        let matches = regex.matches(in: path, range: range)

        return matches.compactMap { match -> RSSHubRouteParameter? in
            guard let nameRange = Range(match.range(at: 1), in: path) else {
                return nil
            }
            let name = String(path[nameRange])
            let isOptional = match.range(at: 2).location != NSNotFound

            let definition = definitions?[name]
            return RSSHubRouteParameter(
                name: name,
                description: definition?.description ?? "",
                isRequired: !isOptional,
                defaultValue: definition?.default,
                options: definition?.options?.map { ($0.value, $0.label) }
            )
        }
    }

    /// 构建完整路径
    func buildPath(with values: [String: String]) -> String {
        var result = path
        for param in parameters {
            let placeholder = param.isRequired ? ":\(param.name)" : ":\(param.name)?"
            let value = values[param.name] ?? param.defaultValue ?? ""
            if value.isEmpty && !param.isRequired {
                // 移除可选参数占位符
                result = result.replacingOccurrences(of: "/\(placeholder)", with: "")
                result = result.replacingOccurrences(of: placeholder, with: "")
            } else {
                result = result.replacingOccurrences(of: placeholder, with: value)
            }
        }
        return result
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: RSSHubRouteItem, rhs: RSSHubRouteItem) -> Bool {
        lhs.id == rhs.id
    }
}

/// 路由参数
struct RSSHubRouteParameter: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let description: String
    let isRequired: Bool
    let defaultValue: String?
    let options: [(value: String, label: String)]?

    func hash(into hasher: inout Hasher) {
        hasher.combine(name)
    }

    static func == (lhs: RSSHubRouteParameter, rhs: RSSHubRouteParameter) -> Bool {
        lhs.name == rhs.name
    }
}

// MARK: - Category

/// 预定义的 RSSHub 分类
struct RSSHubCategory: Identifiable, Hashable {
    let id: String
    let name: String
    let icon: String

    static let all: [RSSHubCategory] = [
        RSSHubCategory(id: "social-media", name: "社交媒体", icon: "person.2"),
        RSSHubCategory(id: "new-media", name: "新媒体", icon: "doc.richtext"),
        RSSHubCategory(id: "traditional-media", name: "传统媒体", icon: "newspaper"),
        RSSHubCategory(id: "bbs", name: "论坛", icon: "bubble.left.and.bubble.right"),
        RSSHubCategory(id: "blog", name: "博客", icon: "text.book.closed"),
        RSSHubCategory(
            id: "programming", name: "编程", icon: "chevron.left.forwardslash.chevron.right"),
        RSSHubCategory(id: "design", name: "设计", icon: "paintbrush"),
        RSSHubCategory(id: "live", name: "直播", icon: "video"),
        RSSHubCategory(id: "multimedia", name: "多媒体", icon: "play.rectangle"),
        RSSHubCategory(id: "picture", name: "图片", icon: "photo"),
        RSSHubCategory(id: "anime", name: "动漫", icon: "sparkles"),
        RSSHubCategory(id: "program-update", name: "程序更新", icon: "arrow.down.app"),
        RSSHubCategory(id: "university", name: "大学通知", icon: "graduationcap"),
        RSSHubCategory(id: "shopping", name: "购物", icon: "cart"),
        RSSHubCategory(id: "game", name: "游戏", icon: "gamecontroller"),
        RSSHubCategory(id: "reading", name: "阅读", icon: "book"),
        RSSHubCategory(id: "government", name: "政务", icon: "building.columns"),
        RSSHubCategory(id: "study", name: "学习", icon: "book.closed"),
        RSSHubCategory(id: "journal", name: "科学期刊", icon: "text.book.closed"),
        RSSHubCategory(id: "finance", name: "金融", icon: "chart.line.uptrend.xyaxis"),
        RSSHubCategory(id: "travel", name: "出行", icon: "airplane"),
        RSSHubCategory(id: "other", name: "其他", icon: "ellipsis.circle"),
    ]
}

// MARK: - API Category Response Models

/// /api/category/<category> 响应中每个平台的数据
struct RSSHubCategoryData: Codable {
    let name: String
    let url: String?
    let lang: String?
    let description: String?
    let routes: [String: RSSHubCategoryRouteDetail]
    let apiRoutes: [String: RSSHubCategoryRouteDetail]?
}

/// 分类中的路由详情
struct RSSHubCategoryRouteDetail: Codable {
    let path: StringOrArray
    let name: String?
    let categories: [String]?
    let maintainers: [String]?
    let description: String?
    let example: String?
    let parameters: [String: RSSHubCategoryParameter]?
    let features: RSSHubCategoryFeatures?
    let location: String?
    let view: Int?

    var pathString: String {
        path.stringValue
    }
}

/// 处理字段可能是字符串或数组的情况
enum StringOrArray: Codable {
    case string(String)
    case array([String])

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let stringValue = try? container.decode(String.self) {
            self = .string(stringValue)
        } else if let arrayValue = try? container.decode([String].self) {
            self = .array(arrayValue)
        } else {
            self = .string("")
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .string(let value):
            try container.encode(value)
        case .array(let value):
            try container.encode(value)
        }
    }

    var stringValue: String {
        switch self {
        case .string(let value):
            return value
        case .array(let values):
            return values.first ?? ""
        }
    }
}

/// 参数可以是字符串或复杂对象
enum RSSHubCategoryParameter: Codable {
    case string(String)
    case object(RSSHubParameterDetail)

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let stringValue = try? container.decode(String.self) {
            self = .string(stringValue)
        } else if let objectValue = try? container.decode(RSSHubParameterDetail.self) {
            self = .object(objectValue)
        } else {
            self = .string("")
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .string(let value):
            try container.encode(value)
        case .object(let value):
            try container.encode(value)
        }
    }

    var descriptionText: String {
        switch self {
        case .string(let text):
            return text
        case .object(let detail):
            return detail.description ?? ""
        }
    }
}

/// 参数详情对象
struct RSSHubParameterDetail: Codable {
    let description: String?
    let options: [RSSHubParameterOptionItem]?
    let `default`: String?
}

/// 参数选项
struct RSSHubParameterOptionItem: Codable {
    let value: String?
    let label: String?
}

/// 路由特性
struct RSSHubCategoryFeatures: Codable {
    let requireConfig: RSSHubRequireConfig?
    let requirePuppeteer: Bool?
    let antiCrawler: Bool?
    let supportBT: Bool?
    let supportPodcast: Bool?
    let supportScihub: Bool?
    let supportRadar: Bool?
}

/// requireConfig 可以是 bool 或数组
enum RSSHubRequireConfig: Codable {
    case bool(Bool)
    case array([RSSHubConfigRequirement])

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let boolValue = try? container.decode(Bool.self) {
            self = .bool(boolValue)
        } else if let arrayValue = try? container.decode([RSSHubConfigRequirement].self) {
            self = .array(arrayValue)
        } else {
            self = .bool(false)
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .bool(let value):
            try container.encode(value)
        case .array(let value):
            try container.encode(value)
        }
    }
}

/// 配置需求
struct RSSHubConfigRequirement: Codable {
    let name: String?
    let description: String?
    let optional: Bool?
}

/// 用于 UI 显示的分类条目（从 API 获取）
struct RSSHubCategoryItem: Identifiable, Hashable {
    let id: String
    let namespace: String
    let name: String
    let url: String
    let description: String
    let routes: [RSSHubRouteItem]

    init(
        namespace: String, name: String, url: String, description: String, routes: [RSSHubRouteItem]
    ) {
        self.id = namespace
        self.namespace = namespace
        self.name = name
        self.url = url
        self.description = description
        self.routes = routes
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: RSSHubCategoryItem, rhs: RSSHubCategoryItem) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Popular Routes

/// 热门路由预设
struct RSSHubPopularRoute: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let path: String
    let parameters: [(name: String, placeholder: String)]

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: RSSHubPopularRoute, rhs: RSSHubPopularRoute) -> Bool {
        lhs.id == rhs.id
    }

    static let all: [RSSHubPopularRoute] = [
        RSSHubPopularRoute(
            name: "Bilibili 用户动态",
            path: "/bilibili/user/dynamic/:uid",
            parameters: [("uid", "用户 UID")]
        ),
        RSSHubPopularRoute(
            name: "Bilibili 用户视频",
            path: "/bilibili/user/video/:uid",
            parameters: [("uid", "用户 UID")]
        ),
        RSSHubPopularRoute(
            name: "微博用户",
            path: "/weibo/user/:uid",
            parameters: [("uid", "用户 UID")]
        ),
        RSSHubPopularRoute(
            name: "知乎热榜",
            path: "/zhihu/hot",
            parameters: []
        ),
        RSSHubPopularRoute(
            name: "GitHub Trending",
            path: "/github/trending/:since/:language?",
            parameters: [("since", "daily/weekly/monthly"), ("language", "编程语言 (可选)")]
        ),
        RSSHubPopularRoute(
            name: "Twitter/X 用户",
            path: "/twitter/user/:id",
            parameters: [("id", "用户名")]
        ),
        RSSHubPopularRoute(
            name: "YouTube 频道",
            path: "/youtube/channel/:id",
            parameters: [("id", "频道 ID")]
        ),
        RSSHubPopularRoute(
            name: "Telegram 频道",
            path: "/telegram/channel/:username",
            parameters: [("username", "频道用户名")]
        ),
        RSSHubPopularRoute(
            name: "即刻用户动态",
            path: "/jike/user/:id",
            parameters: [("id", "用户 ID")]
        ),
        RSSHubPopularRoute(
            name: "小红书用户笔记",
            path: "/xiaohongshu/user/:user_id/notes",
            parameters: [("user_id", "用户 ID")]
        ),
        RSSHubPopularRoute(
            name: "豆瓣小组",
            path: "/douban/group/:groupid",
            parameters: [("groupid", "小组 ID")]
        ),
        RSSHubPopularRoute(
            name: "抖音用户",
            path: "/douyin/user/:uid",
            parameters: [("uid", "用户 sec_uid")]
        ),
    ]
}
