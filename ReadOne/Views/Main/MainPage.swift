//
//  MainView.swift
//  ReadOne
//
//  Created by 纪洪波 on 11/30/25.
//

import SwiftUI
import SwiftData

struct MainPage: View {
#if os(iOS)
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    private var isCompact: Bool {
        horizontalSizeClass == .compact
    }
#endif
    
    var body: some View {
#if os(iOS)
        if isCompact {
            MainCompactView()
        } else {
            MainRegularView()
        }
#else
        MainRegularView()
#endif
    }
}

#Preview {
    MainPage()
        .modelContainer(PreviewContainer.shared)
}
