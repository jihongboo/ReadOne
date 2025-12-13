//
//  AISummaryButton.swift
//  ReadOne
//
//  Created by 纪洪波 on 11/30/25.
//

import SwiftUI

struct AISummaryButton: View {
    let article: Article

    @State private var showSummary = false

    var body: some View {
        Button(String(localized: "AI Summary"), systemImage: "apple.intelligence") {
            showSummary = true
        }
        .popover(isPresented: $showSummary) {
            AISummaryPopoverView(article: article)
        }
    }
}

#Preview {
    AISummaryButton(article: MockData.sampleArticle)
        .padding()
}
