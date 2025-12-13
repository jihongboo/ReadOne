//
//  RouteDetailView.swift
//  ReadOne
//
//  Created by Claude on 12/13/25.
//

import SwiftData
import SwiftUI

// MARK: - Platform Colors

extension Color {
    static var platformBackground: Color {
        #if os(macOS)
            Color(nsColor: .windowBackgroundColor)
        #else
            Color(uiColor: .systemGroupedBackground)
        #endif
    }

    static var platformCardBackground: Color {
        #if os(macOS)
            Color(nsColor: .controlBackgroundColor)
        #else
            Color(uiColor: .secondarySystemGroupedBackground)
        #endif
    }

    static var platformTextBackground: Color {
        #if os(macOS)
            Color(nsColor: .textBackgroundColor)
        #else
            Color(uiColor: .tertiarySystemGroupedBackground)
        #endif
    }
}

// MARK: - RSSHub Route Detail View

struct RSSHubRouteDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let route: RSSHubRouteItem
    let instance: RSSHubInstance

    @State private var parameterValues: [String: String] = [:]
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var parsedFeed: ParsedFeedResult?
    @State private var useFullText = false
    @State private var feedAdded = false

    private var generatedPath: String {
        route.buildPath(with: parameterValues)
    }

    private var generatedURL: String {
        instance.baseURL + generatedPath
    }

    private var isValid: Bool {
        for param in route.parameters where param.isRequired {
            let value = parameterValues[param.name] ?? ""
            if value.isEmpty {
                return false
            }
        }
        return true
    }

    var body: some View {
        Form {
            // Route Info Section
            Section {
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [.orange, .pink],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 44, height: 44)

                        Image(systemName: "antenna.radiowaves.left.and.right")
                            .font(.title3)
                            .foregroundStyle(.white)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text(route.name)
                            .font(.headline)
                        Text(route.namespace)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }

                if !route.description.isEmpty {
                    Text(route.description)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                if let example = route.example {
                    LabeledContent("Example") {
                        Text(example)
                            .font(.system(.caption, design: .monospaced))
                            .foregroundStyle(.secondary)
                    }
                }
            }

            // Parameters Section
            if !route.parameters.isEmpty {
                Section("Parameters") {
                    ForEach(route.parameters) { param in
                        parameterInput(for: param)
                    }
                }
            }

            // Generated URL Section
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text(generatedURL)
                        .font(.system(.caption, design: .monospaced))
                        .textSelection(.enabled)
                }
            } header: {
                Text("Generated URL")
            }

            // Preview Button Section
            Section {
                Button {
                    Task {
                        await previewFeed()
                    }
                } label: {
                    HStack {
                        Spacer()
                        if isLoading {
                            ProgressView()
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "eye")
                        }
                        Text("Preview Feed")
                        Spacer()
                    }
                }
                .disabled(!isValid || isLoading)
            }

            // Error Section
            if let error = errorMessage {
                Section {
                    Label(error, systemImage: "exclamationmark.triangle.fill")
                        .foregroundStyle(.red)
                }
            }

            // Feed Preview Section
            if let feed = parsedFeed {
                Section("Preview") {
                    HStack(spacing: 12) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(
                                    LinearGradient(
                                        colors: [.green, .mint],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 40, height: 40)

                            Image(systemName: "checkmark.circle")
                                .font(.title3)
                                .foregroundStyle(.white)
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text(feed.title)
                                .font(.headline)
                            Text("\(feed.articles.count) articles")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }

                    if !feed.description.isEmpty {
                        Text(feed.description)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .lineLimit(3)
                    }
                }

                Section {
                    Toggle("Full Text Mode", isOn: $useFullText)
                } footer: {
                    Text("Use FeedEx service to fetch full article content")
                }

                Section {
                    Button {
                        addFeed()
                    } label: {
                        HStack {
                            Spacer()
                            Image(
                                systemName: feedAdded ? "checkmark.circle.fill" : "plus.circle.fill"
                            )
                            Text(feedAdded ? "Added!" : "Add to My Feeds")
                            Spacer()
                        }
                    }
                    .disabled(feedAdded)
                    .foregroundStyle(feedAdded ? .green : .accentColor)
                }
            }
        }
        .navigationTitle(route.name)
        #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
        #endif
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    dismiss()
                }
            }
        }
        .onAppear {
            initializeDefaultValues()
        }
    }

    // MARK: - Parameter Input

    @ViewBuilder
    private func parameterInput(for param: RSSHubRouteParameter) -> some View {
        let binding = Binding<String>(
            get: { parameterValues[param.name] ?? param.defaultValue ?? "" },
            set: { parameterValues[param.name] = $0 }
        )

        VStack(alignment: .leading) {
            HStack {
                Text(param.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                if param.isRequired {
                    Text("*")
                        .foregroundStyle(.red)
                }
                if !param.description.isEmpty {
                    Text(param.description)
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }

            if let options = param.options, !options.isEmpty {
                Picker("", selection: binding) {
                    if !param.isRequired {
                        Text("None").tag("")
                    }
                    ForEach(options, id: \.value) { option in
                        Text(option.label).tag(option.value)
                    }
                }
                .labelsHidden()
                .pickerStyle(.menu)
            } else {
                TextField("Enter \(param.name)", text: binding)
                    .textFieldStyle(.roundedBorder)
            }
        }
    }

    private func initializeDefaultValues() {
        for param in route.parameters {
            if let defaultValue = param.defaultValue {
                parameterValues[param.name] = defaultValue
            }
        }
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

#Preview("Route Detail") {
    NavigationStack {
        RSSHubRouteDetailView(
            route: RSSHubRouteItem(
                namespace: "bilibili",
                path: "/bilibili/user/dynamic/:uid",
                detail: RSSHubRouteDetail(
                    path: "/bilibili/user/dynamic/:uid",
                    name: "UP 主动态",
                    categories: ["social-media"],
                    maintainers: ["DIYgod"],
                    description: "获取指定 UP 主的动态更新",
                    parameters: [
                        "uid": RSSHubParameter(
                            description: "用户 UID，可在 UP 主主页 URL 中找到",
                            options: nil,
                            default: nil
                        )
                    ],
                    features: nil,
                    example: "/bilibili/user/dynamic/208259"
                )
            ),
            instance: RSSHubInstance.createOfficialInstance()
        )
    }
}
