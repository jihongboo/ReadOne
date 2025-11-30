//
//  ArticleDetailWindow.swift
//  ReadOne
//
//  Created by 纪洪波 on 11/30/25.
//

import SwiftData
import SwiftUI

struct ArticleDetailWindow: View {
    @Bindable var article: Article

    var body: some View {
        ArticleDetailView(article: article)
            .frame(minWidth: 600, minHeight: 400)
    }
}

#Preview {
    ArticleDetailWindow(article: MockData.sampleArticle)
        .modelContainer(PreviewContainer.shared)
}
