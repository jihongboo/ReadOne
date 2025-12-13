//
//  FeedRowView.swift
//  ReadOne
//
//  Created by 纪洪波 on 11/30/25.
//

import SwiftData
import SwiftUI

struct FeedRowView: View {
    @Environment(\.modelContext) private var modelContext
    #if os(iOS)
        @Environment(\.navigationPath) private var path
        @Environment(\.horizontalSizeClass) private var horizontalSizeClass

        private var isCompact: Bool {
            horizontalSizeClass == .compact
        }
    #endif

    let feed: Feed
    var selectedSection: Binding<SidebarSection?>?

    @State private var showingEditSheet = false
    @State private var showingDeleteConfirmation = false

    var body: some View {
        Button {
            handleTap()
        } label: {
            rowContent
        }
        .buttonStyle(.plain)
        .tag(SidebarSection.feed(feed))
        .contentShape(Rectangle())
        .contextMenu {
            Button {
                showingEditSheet = true
            } label: {
                Label("Edit Feed", systemImage: "pencil")
            }

            Button {
                markAllAsRead()
            } label: {
                Label("Mark All as Read", systemImage: "checkmark.circle")
            }

            Divider()

            Button {
                copyFeedURL()
            } label: {
                Label("Copy Feed URL", systemImage: "doc.on.doc")
            }

            Divider()

            Button(role: .destructive) {
                showingDeleteConfirmation = true
            } label: {
                Label("Delete Feed", systemImage: "trash")
            }
        }
        #if os(iOS)
            .swipeActions(edge: .trailing) {
                Button(role: .destructive) {
                    showingDeleteConfirmation = true
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            }
            .swipeActions(edge: .leading) {
                Button {
                    markAllAsRead()
                } label: {
                    Label("Mark All as Read", systemImage: "checkmark.circle")
                }
                .tint(.blue)
            }
        #endif
        .confirmationDialog(
            "Delete \"\(feed.title)\"?",
            isPresented: $showingDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                deleteFeed()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will delete the feed and all its articles. This action cannot be undone.")
        }
        .sheet(isPresented: $showingEditSheet) {
            EditFeedView(feed: feed)
        }
    }

    private func handleTap() {
        #if os(iOS)
            if isCompact {
                path.wrappedValue.append(feed)
            } else {
                selectedSection?.wrappedValue = .feed(feed)
            }
        #else
            selectedSection?.wrappedValue = .feed(feed)
        #endif
    }

    private var rowContent: some View {
        HStack {
            AsyncImage(url: feed.imageURL) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Rectangle()
                    .fill(.secondary)
            }
            .frame(width: 32, height: 32)
            .clipShape(RoundedRectangle(cornerRadius: 6))

            Text(feed.title)
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)

            if feed.unreadCount > 0 {
                Text(verbatim: "\(feed.unreadCount)")
                    .font(.callout)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func markAllAsRead() {
        for article in feed.articles {
            article.isRead = true
        }
    }

    private func copyFeedURL() {
        #if os(macOS)
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(feed.url.absoluteString, forType: .string)
        #else
            UIPasteboard.general.string = feed.url.absoluteString
        #endif
    }

    private func deleteFeed() {
        // 如果当前选中的是这个 feed，清除选择
        if case .feed(let selectedFeed) = selectedSection?.wrappedValue,
            selectedFeed.id == feed.id
        {
            selectedSection?.wrappedValue = .allArticles
        }
        modelContext.delete(feed)
    }
}

#Preview {
    List {
        FeedRowView(feed: MockData.sampleFeed)
    }
    .modelContainer(PreviewContainer.shared)
}
