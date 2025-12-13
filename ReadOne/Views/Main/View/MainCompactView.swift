//
//  iPhoneTabView.swift
//  ReadOne
//
//  Created by 纪洪波 on 11/30/25.
//

#if os(iOS)
    import SwiftData
    import SwiftUI

    // MARK: - Navigation Path Environment

    extension EnvironmentValues {
        @Entry var navigationPath: Binding<NavigationPath> = .constant(NavigationPath())
    }

    // MARK: - Main Compact View

    struct MainCompactView: View {
        @State private var selectedArticle: Article?
        @State private var selectedTab: TabItem = .feeds
        @State private var feedsPath = NavigationPath()
        @State private var searchPath = NavigationPath()

        enum TabItem: Hashable {
            case feeds
            case search
            case discover
        }

        var body: some View {
            TabView(selection: $selectedTab) {
                // 订阅源首页（包含全部文章入口和订阅源列表）
                Tab("Feeds", systemImage: "list.bullet", value: TabItem.feeds) {
                    NavigationStack(path: $feedsPath) {
                        FeedsHomeView(selectedArticle: $selectedArticle)
                            .environment(\.navigationPath, $feedsPath)
                    }
                }

                // 发现
                Tab("Discover", systemImage: "sparkles", value: TabItem.discover) {
                    DiscoverView()
                }
                
                // 搜索
                Tab("Search", systemImage: "magnifyingglass", value: TabItem.search, role: .search) {
                    NavigationStack(path: $searchPath) {
                        ArticleSearchView(selectedArticle: $selectedArticle)
                            .environment(\.navigationPath, $searchPath)
                    }
                }
            }
        }
    }

    #Preview {
        MainCompactView()
            .modelContainer(PreviewContainer.shared)
    }
#endif
