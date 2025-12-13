//
//  SidebarSection.swift
//  ReadOne
//
//  Created by 纪洪波 on 11/30/25.
//

import Foundation

enum SidebarSection: Hashable {
    case allArticles
    case discover
    case search
    case feed(Feed)
}
