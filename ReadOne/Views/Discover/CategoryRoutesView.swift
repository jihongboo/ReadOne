//
//  DiscoverCategoryRoutesView.swift
//  ReadOne
//
//  Created by Claude on 12/13/25.
//

import SwiftUI

struct CategoryRoutesView: View {
    @Environment(\.rssHubService) private var rssHubService

    let category: RSSHubCategory
    let instance: RSSHubInstance

    @State private var categoryItems: [RSSHubCategoryItem] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var selectedRoute: RSSHubRouteItem?

    var body: some View {
        Group {
            if isLoading {
                ProgressView("Loading routes...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let error = errorMessage {
                ContentUnavailableView {
                    Label("Error", systemImage: "exclamationmark.triangle")
                } description: {
                    Text(error)
                } actions: {
                    Button("Retry") {
                        Task {
                            await loadRoutes()
                        }
                    }
                }
            } else if categoryItems.isEmpty {
                ContentUnavailableView {
                    Label("No Routes", systemImage: "tray")
                } description: {
                    Text("No routes found in this category")
                }
            } else {
                List {
                    ForEach(categoryItems) { item in
                        Section(item.name) {
                            ForEach(item.routes) { route in
                                Button {
                                    selectedRoute = route
                                } label: {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(route.name)
                                                .fontWeight(.medium)
                                                .foregroundStyle(.primary)
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
                                        Spacer()
                                        Image(systemName: "chevron.right")
                                            .font(.caption)
                                            .foregroundStyle(.tertiary)
                                    }
                                    .padding(.vertical, 2)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle(category.name)
        .sheet(item: $selectedRoute) { route in
            NavigationStack {
                RSSHubRouteDetailView(route: route, instance: instance)
            }
        }
        .task {
            await loadRoutes()
        }
    }

    private func loadRoutes() async {
        isLoading = true
        errorMessage = nil

        do {
            categoryItems = try await rssHubService.fetchCategoryRoutes(
                category: category.id, from: instance)
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }
}

#Preview {
    NavigationStack {
        CategoryRoutesView(
            category: RSSHubCategory(id: "social-media", name: "社交媒体", icon: "person.2"),
            instance: RSSHubInstance.createOfficialInstance()
        )
    }
}
