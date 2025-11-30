//
//  FeedRowView.swift
//  ReadOne
//
//  Created by 纪洪波 on 11/30/25.
//

import SwiftData
import SwiftUI

struct FeedRowView: View {
    let feed: Feed
    var onDelete: (() -> Void)?

    @State private var showingEditSheet = false

    var body: some View {
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
                Text("\(feed.unreadCount)")
                    .font(.callout)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
            }
        }
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
                onDelete?()
            } label: {
                Label("Delete Feed", systemImage: "trash")
            }
        }
        .sheet(isPresented: $showingEditSheet) {
            EditFeedView(feed: feed)
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
}

#Preview {
    FeedRowView(feed: MockData.sampleFeed)
        .modelContainer(PreviewContainer.shared)
}
