# ReadOne - RSS Reader App

## 项目概述
ReadOne 是一个跨平台 RSS 阅读器，支持 macOS、iOS 和 visionOS，集成了 RSSHub 数据源支持。

## 技术栈
- **语言**: Swift
- **UI框架**: SwiftUI
- **数据持久化**: SwiftData (@Model, @Query)
- **RSS解析**: RSParser 库
- **最低版本**: iOS 26.1+, macOS 26.1+, visionOS

## 项目结构

```
ReadOne/
├── ReadOneApp.swift              # 应用入口，Schema 注册
├── ContentView.swift             # 主内容视图
├── Models/
│   ├── Feed.swift                # Feed 数据模型 (@Model)
│   ├── Article.swift             # Article 数据模型 (@Model)
│   ├── RSSHubInstance.swift      # RSSHub 实例配置 (@Model)
│   ├── RSSHubRoute.swift         # RSSHub 路由相关模型
│   └── MockData.swift            # 预览数据
├── Services/
│   ├── RSSService.swift          # RSS 订阅获取服务
│   ├── RSSHubService.swift       # RSSHub API 服务 (actor)
│   └── SummarizationService.swift # AI 摘要服务
├── Views/
│   ├── Main/
│   │   ├── SidebarView.swift     # 侧边栏
│   │   ├── FeedListView.swift    # Feed 列表
│   │   └── Components/
│   │       ├── SidebarSection.swift    # 侧边栏区块枚举
│   │       ├── ContentColumnView.swift # 内容列视图
│   │       └── FeedRowView.swift       # Feed 行视图
│   ├── Discover/
│   │   ├── DiscoverView.swift              # 发现页主视图（分类卡片 + 热门路由）
│   │   ├── DiscoverCategoryRoutesView.swift # 分类路由列表（sheet 弹框展示详情）
│   │   ├── RouteDetailView.swift           # RSSHubRouteDetailView（Form 布局）
│   │   ├── PopularRouteDetailView.swift    # RSSHubPopularRouteDetailView
│   │   ├── SearchFeedView.swift            # 搜索视图
│   │   └── AddFeedView.swift               # 添加 Feed（在 DiscoverView.swift 中定义）
│   ├── ArticleList/
│   │   ├── AllArticlesView.swift
│   │   ├── FeedArticleListView.swift
│   │   └── Components/ArticleRowView.swift
│   ├── ArticleDetail/
│   │   ├── ArticleDetailView.swift
│   │   ├── ArticleDetailWindow.swift
│   │   └── Components/
│   │       ├── HTMLContentView.swift
│   │       ├── AISummaryButton.swift
│   │       └── AISummaryPopoverView.swift
│   └── EditFeed/
│       └── EditFeedView.swift
└── Extensions/
    └── String+Extensions.swift
```

## 核心模型

### Feed (@Model)
- `title`, `url`, `feedDescription`, `imageURL`
- `useFullText`: 是否使用全文模式
- `articles`: 关联的文章

### Article (@Model)
- `title`, `link`, `content`, `author`, `publishedDate`
- `isRead`, `isStarred`: 阅读状态
- `feed`: 关联的 Feed

### RSSHubInstance (@Model)
- `name`, `baseURL`, `isDefault`
- 默认实例: `https://rsshub.isrss.com`

### RSSHub 路由模型 (RSSHubRoute.swift)
- `RSSHubCategory` - 静态分类列表（用于 Discover 页面分类卡片）
- `RSSHubCategoryData` - API 响应中的平台数据
- `RSSHubCategoryItem` - UI 显示的分类条目（包含路由列表）
- `RSSHubRouteItem` - 路由条目
- `RSSHubPopularRoute` - 预设热门路由
- `StringOrArray` - 处理 `path` 字段可能是字符串或数组
- `RSSHubCategoryParameter` - 处理 `parameters` 可能是字符串或对象

## RSSHub API

### 接口
- `/api/routes` - 获取所有路由
- `/api/routes/:namespace` - 获取指定命名空间路由
- `/api/category/:category` - 获取分类下的路由（按平台分组）

### RSSHubService 方法
- `fetchAllRoutes(from:)` - 获取所有路由
- `fetchRoutes(category:from:)` - 获取指定分类路由（旧接口）
- `fetchCategoryRoutes(category:from:)` - 获取分类路由（使用 /api/category/:category）
- `searchRoutes(keyword:from:)` - 搜索路由
- `validateInstance(_:)` - 验证实例可用性

### 分类 ID
`social-media`, `new-media`, `traditional-media`, `bbs`, `blog`, `programming`, `design`, `live`, `multimedia`, `picture`, `anime`, `program-update`, `university`, `shopping`, `game`, `reading`, `government`, `study`, `journal`, `finance`, `travel`, `other`

## 侧边栏区块 (SidebarSection)
- `.feeds` - 订阅源列表
- `.discover` - 发现页（RSSHub 分类浏览）
- `.search` - 搜索

## 跨平台颜色 (RouteDetailView.swift)
```swift
extension Color {
    static var platformBackground: Color       // 窗口背景
    static var platformCardBackground: Color   // 卡片背景
    static var platformTextBackground: Color   // 文本背景
}
```

## 常用命令

```bash
# 构建 macOS
xcodebuild -scheme ReadOne -destination 'platform=macOS' build

# 构建 iOS
xcodebuild -scheme ReadOne -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build

# 运行项目
open ReadOne.xcodeproj
```

## 注意事项
- 使用 `Color.platformBackground` 等跨平台颜色替代 `Color(nsColor:)`
- 使用 `#if os(iOS)` / `#if os(macOS)` 处理平台差异
- RSSHub API 响应中 `path` 字段可能是字符串或数组，使用 `StringOrArray` 枚举处理
- `parameters` 字段可能是字符串或对象，使用 `RSSHubCategoryParameter` 枚举处理
- `DiscoverCategoryRoutesView` 点击路由使用 `.sheet` 弹框展示 `RSSHubRouteDetailView`
- `RSSHubRouteDetailView` 使用 `Form` 布局，支持预览和添加 Feed
- 项目默认使用 MainActor，async 函数中不需要手动 `await MainActor.run {}`
