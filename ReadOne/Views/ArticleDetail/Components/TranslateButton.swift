//
//  TranslateButton.swift
//  ReadOne
//
//  Created by 纪洪波 on 12/14/25.
//

import SwiftUI
import Translation

struct TranslateButton: View {
    let title: String
    let content: String

    @Binding var translatedTitle: String?
    @Binding var translatedContent: String?
    @Binding var isTranslated: Bool

    @State private var translationConfiguration: TranslationSession.Configuration?

    var body: some View {
        Button(
            isTranslated
                ? String(localized: "Show Original")
                : String(localized: "Translate"),
            systemImage: "translate"
        ) {
            if isTranslated {
                isTranslated = false
            } else {
                triggerTranslation()
            }
        }
        .translationTask(translationConfiguration) { @Sendable session in
            let requests = await [
                TranslationSession.Request(sourceText: title),
                TranslationSession.Request(sourceText: content.stripHTML()),
            ]

            do {
                let responses = try await session.translations(from: requests)
                if responses.count >= 2 {
                    await MainActor.run {
                        translatedTitle = responses[0].targetText
                        translatedContent = responses[1].targetText
                        isTranslated = true
                    }
                }
            } catch {
                print("Translation failed: \(error)")
            }
        }
    }

    private func triggerTranslation() {
        if translatedContent != nil {
            isTranslated = true
        } else {
            translationConfiguration = .init()
        }
    }
}

#Preview {
    TranslateButton(
        title: "Hello World",
        content: "<p>This is a test content.</p>",
        translatedTitle: .constant(nil),
        translatedContent: .constant(nil),
        isTranslated: .constant(false)
    )
}
