//
//  PopularRouteDetailView.swift
//  ReadOne
//
//  Created by Claude on 12/13/25.
//

import SwiftData
import SwiftUI

struct RSSHubPopularRouteDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let popularRoute: RSSHubPopularRoute
    let instance: RSSHubInstance

    @State private var parameterValues: [String: String] = [:]
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var parsedFeed: ParsedFeedResult?
    @State private var useFullText = false
    @State private var feedAdded = false

    private var generatedPath: String {
        var path = popularRoute.path
        for (name, _) in popularRoute.parameters {
            let value = parameterValues[name] ?? ""
            let isOptional = popularRoute.path.contains(":\(name)?")
            let placeholder = isOptional ? ":\(name)?" : ":\(name)"

            if value.isEmpty && isOptional {
                path = path.replacingOccurrences(of: "/\(placeholder)", with: "")
                path = path.replacingOccurrences(of: placeholder, with: "")
            } else {
                path = path.replacingOccurrences(of: placeholder, with: value)
            }
        }
        return path
    }

    private var generatedURL: String {
        instance.baseURL + generatedPath
    }

    private var isValid: Bool {
        for (name, _) in popularRoute.parameters {
            let isOptional = popularRoute.path.contains(":\(name)?")
            if !isOptional {
                let value = parameterValues[name] ?? ""
                if value.isEmpty {
                    return false
                }
            }
        }
        return true
    }

    var body: some View {
        Form {
            Section("Route") {
                Text(popularRoute.name)
                    .font(.headline)
                Text(popularRoute.path)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(.secondary)
            }

            if !popularRoute.parameters.isEmpty {
                Section("Parameters") {
                    ForEach(popularRoute.parameters, id: \.name) { param in
                        let isOptional = popularRoute.path.contains(":\(param.name)?")
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                TextField(
                                    param.name,
                                    text: Binding(
                                        get: { parameterValues[param.name] ?? "" },
                                        set: { parameterValues[param.name] = $0 }
                                    ))
                                if !isOptional {
                                    Text("*")
                                        .foregroundStyle(.red)
                                }
                            }
                            Text(param.placeholder)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }

            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Generated URL")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(generatedURL)
                        .font(.system(.caption, design: .monospaced))
                        .textSelection(.enabled)
                }
            }

            Section {
                Button {
                    Task {
                        await previewFeed()
                    }
                } label: {
                    HStack {
                        Text("Preview Feed")
                        Spacer()
                        if isLoading {
                            ProgressView()
                        }
                    }
                }
                .disabled(!isValid || isLoading)
            }

            if let error = errorMessage {
                Section {
                    Label(error, systemImage: "exclamationmark.triangle")
                        .foregroundStyle(.red)
                }
            }

            if let feed = parsedFeed {
                Section("Preview") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(feed.title)
                            .font(.headline)

                        if !feed.description.isEmpty {
                            Text(feed.description)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }

                        Text("\(feed.articles.count) articles")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Section {
                    Toggle("Full Text Mode", isOn: $useFullText)
                } footer: {
                    Text("Use FeedEx service to fetch full article content")
                }

                Section {
                    Button("Add Feed") {
                        addFeed()
                    }
                    .frame(maxWidth: .infinity)
                    .disabled(feedAdded)
                }

                if feedAdded {
                    Section {
                        Label("Feed added successfully!", systemImage: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                    }
                }
            }
        }
        .navigationTitle("Add Feed")
        #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
        #endif
    }

    private func previewFeed() async {
        guard let url = URL(string: generatedURL) else {
            errorMessage = String(localized: "Invalid URL")
            return
        }

        isLoading = true
        errorMessage = nil
        parsedFeed = nil
        feedAdded = false

        do {
            parsedFeed = try await RSSService.shared.fetchFeed(from: url)
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    private func addFeed() {
        guard let parsed = parsedFeed,
            let feedURL = URL(string: generatedURL)
        else { return }

        let feed = Feed(
            title: parsed.title,
            url: feedURL,
            feedDescription: parsed.description,
            imageURL: parsed.imageURL,
            useFullText: useFullText
        )

        modelContext.insert(feed)

        for parsedArticle in parsed.articles {
            guard let articleLink = parsedArticle.link else { continue }
            let article = Article(
                title: parsedArticle.title,
                link: articleLink,
                articleDescription: parsedArticle.description,
                content: parsedArticle.content,
                author: parsedArticle.author,
                publishedDate: parsedArticle.publishedDate,
                guid: parsedArticle.guid,
                imageURL: parsedArticle.imageURL
            )
            article.feed = feed
            modelContext.insert(article)
        }

        feedAdded = true
    }
}

#Preview {
    NavigationStack {
        RSSHubPopularRouteDetailView(
            popularRoute: RSSHubPopularRoute(
                name: "Bilibili 用户动态",
                path: "/bilibili/user/dynamic/:uid",
                parameters: [("uid", "用户 UID")]
            ),
            instance: RSSHubInstance.createOfficialInstance()
        )
    }
}
