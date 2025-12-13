//
//  ReadOneApp.swift
//  ReadOne
//
//  Created by 纪洪波 on 11/30/25.
//

import SwiftData
import SwiftUI

// MARK: - FocusedValue for selected article

struct SelectedArticleFocusedValueKey: FocusedValueKey {
    typealias Value = Article
}

extension FocusedValues {
    var selectedArticle: Article? {
        get { self[SelectedArticleFocusedValueKey.self] }
        set { self[SelectedArticleFocusedValueKey.self] = newValue }
    }
}

@main
struct ReadOneApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Feed.self,
            Article.self,
            RSSHubInstance.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            MainPage()
        }
        .modelContainer(sharedModelContainer)
        .commands {
            CommandGroup(after: .newItem) {
                OpenInNewWindowCommand()
            }
        }

        WindowGroup("Article Detail", for: PersistentIdentifier.self) { $articleID in
            if let articleID {
                ArticleWindowContainer(articleID: articleID)
                    .modelContainer(sharedModelContainer)
            }
        }
    }
}

// MARK: - 在新窗口中打开命令

struct OpenInNewWindowCommand: View {
    @FocusedValue(\.selectedArticle) var selectedArticle
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        Button("Open in New Window") {
            if let article = selectedArticle {
                openWindow(value: article.persistentModelID)
            }
        }
        .keyboardShortcut(.return, modifiers: [.command])
        .disabled(selectedArticle == nil)
    }
}

// MARK: - 文章窗口容器

struct ArticleWindowContainer: View {
    @Environment(\.modelContext) private var modelContext
    let articleID: PersistentIdentifier

    var body: some View {
        if let article = modelContext.model(for: articleID) as? Article {
            ArticleDetailWindow(article: article)
        } else {
            ContentUnavailableView(
                "Article Not Found",
                systemImage: "doc.questionmark",
                description: Text("Unable to find this article")
            )
        }
    }
}
