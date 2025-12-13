//
//  SplitView.swift
//  ReadOne
//
//  Created by 纪洪波 on 11/30/25.
//

import SwiftUI
import SwiftData

struct MainRegularView: View {
    @State private var selectedSection: SidebarSection? = .allArticles
    @State private var selectedArticle: Article?

    var body: some View {
        NavigationSplitView(columnVisibility: .constant(.all)) {
            SidebarView(selectedSection: $selectedSection)
                .navigationSplitViewColumnWidth(min: 180, ideal: 200)
        } content: {
            ContentColumnView(
                selectedSection: selectedSection,
                selectedArticle: $selectedArticle
            )
            .navigationSplitViewColumnWidth(min: 240, ideal: 300)
        } detail: {
            if let selectedArticle {
                ArticleDetailView(article: selectedArticle)
            } else {
                ContentUnavailableView(
                    "Select an Article",
                    systemImage: "doc.plaintext",
                    description: Text("Choose an article from the list to read")
                )
            }
        }
    }
}

#Preview {
    MainRegularView()
        .modelContainer(PreviewContainer.shared)
}
