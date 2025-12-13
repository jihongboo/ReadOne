//
//  ArticleTextSize.swift
//  ReadOne
//
//  Created by 纪洪波 on 12/14/25.
//

import Foundation
import SwiftUI

/// 文章文字大小设置
enum ArticleTextSize: Int, CaseIterable, Identifiable {
    case small = 1
    case medium = 2
    case large = 3
    case xLarge = 4
    case xxLarge = 5

    var id: Int { rawValue }

    /// CSS 类名
    var cssClass: String {
        switch self {
        case .small: return "smallText"
        case .medium: return "mediumText"
        case .large: return "largeText"
        case .xLarge: return "xlargeText"
        case .xxLarge: return "xxlargeText"
        }
    }

    /// 字体大小（pt）
    var fontSize: Int {
        switch self {
        case .small: return 14
        case .medium: return 17
        case .large: return 20
        case .xLarge: return 24
        case .xxLarge: return 28
        }
    }

    /// 显示名称
    var displayName: String {
        switch self {
        case .small: return String(localized: "Small")
        case .medium: return String(localized: "Medium")
        case .large: return String(localized: "Large")
        case .xLarge: return String(localized: "Extra Large")
        case .xxLarge: return String(localized: "Extra Extra Large")
        }
    }

    /// 图标
    var icon: String {
        switch self {
        case .small: return "textformat.size.smaller"
        case .medium: return "textformat.size"
        case .large: return "textformat.size.larger"
        case .xLarge: return "textformat.size.larger"
        case .xxLarge: return "textformat.size.larger"
        }
    }
}

// MARK: - AppStorage Key

extension ArticleTextSize {
    static let storageKey = "articleTextSize"

    static var `default`: ArticleTextSize {
        .medium
    }
}
