//
//  SearchFeedView.swift
//  ReadOne
//
//  Created by Claude on 12/13/25.
//

import SwiftData
import SwiftUI

struct SearchFeedView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.rssHubService) private var rssHubService
    @Query(sort: \RSSHubInstance.createdAt) private var allInstances: [RSSHubInstance]

    @State private var searchText = ""
    @State private var searchResults: [RSSHubRouteItem] = []
    @State private var isSearching = false
    @State private var hasSearched = false
    @State private var errorMessage: String?

    private var currentInstance: RSSHubInstance {
        if let defaultInstance = allInstances.first(where: { $0.isDefault }) {
            return defaultInstance
        }
        if let firstInstance = allInstances.first {
            return firstInstance
        }
        let official = RSSHubInstance.createOfficialInstance()
        modelContext.insert(official)
        return official
    }

    var body: some View {
        NavigationStack {
            Group {
                if !hasSearched && searchResults.isEmpty {
                    ContentUnavailableView {
                        Label("Search Feeds", systemImage: "magnifyingglass")
                    } description: {
                        Text("Search for RSSHub routes by name or keyword")
                    }
                } else if isSearching {
                    ProgressView("Searching...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let error = errorMessage {
                    ContentUnavailableView {
                        Label("Error", systemImage: "exclamationmark.triangle")
                    } description: {
                        Text(error)
                    }
                } else if searchResults.isEmpty && hasSearched {
                    ContentUnavailableView {
                        Label("No Results", systemImage: "magnifyingglass")
                    } description: {
                        Text("No routes found for \"\(searchText)\"")
                    }
                } else {
                    List {
                        ForEach(searchResults) { route in
                            NavigationLink(value: route) {
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack {
                                        Text(route.name)
                                            .fontWeight(.medium)
                                        Spacer()
                                        Text(route.namespace)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    if !route.description.isEmpty {
                                        Text(route.description)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                            .lineLimit(2)
                                    }
                                    Text(route.path)
                                        .font(.system(.caption2, design: .monospaced))
                                        .foregroundStyle(.tertiary)
                                }
                                .padding(.vertical, 2)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Search")
            .searchable(text: $searchText, prompt: "Search RSSHub routes...")
            .onSubmit(of: .search) {
                Task {
                    await performSearch()
                }
            }
            .onChange(of: searchText) { _, newValue in
                if newValue.isEmpty {
                    searchResults = []
                    hasSearched = false
                }
            }
            .navigationDestination(for: RSSHubRouteItem.self) { route in
                RSSHubRouteDetailView(route: route, instance: currentInstance)
            }
        }
    }

    private func performSearch() async {
        guard !searchText.trimmingCharacters(in: .whitespaces).isEmpty else {
            return
        }

        isSearching = true
        errorMessage = nil
        hasSearched = true

        do {
            searchResults = try await rssHubService.searchRoutes(
                keyword: searchText,
                from: currentInstance
            )
        } catch {
            errorMessage = error.localizedDescription
        }

        isSearching = false
    }
}

#Preview {
    SearchFeedView()
        .modelContainer(PreviewContainer.shared)
}
