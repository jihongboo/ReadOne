//
//  ContentView.swift
//  ReadOne
//
//  Created by 纪洪波 on 11/30/25.
//

import SwiftData
import SwiftUI

struct ContentView: View {
    var body: some View {
        FeedListView()
    }
}

#Preview {
    ContentView()
        .modelContainer(PreviewContainer.shared)
}
