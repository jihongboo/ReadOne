//
//  String+Extensions.swift
//  ReadOne
//
//  Created by 纪洪波 on 11/30/25.
//

import Foundation

extension String {
    /// 移除 HTML 标签，返回纯文本
    /// 采用纯正则方式，避免 NSAttributedString 的线程安全和性能问题
    func stripHTML() -> String {
        guard !self.isEmpty else { return self }

        var result = self

        // 1. 移除 script 和 style 标签及其内容
        result = result.replacingOccurrences(
            of: "<script[^>]*>[\\s\\S]*?</script>",
            with: "",
            options: .regularExpression
        )
        result = result.replacingOccurrences(
            of: "<style[^>]*>[\\s\\S]*?</style>",
            with: "",
            options: .regularExpression
        )

        // 2. 移除所有 HTML 标签
        result = result.replacingOccurrences(
            of: "<[^>]+>",
            with: "",
            options: .regularExpression
        )

        // 3. 解码常见 HTML 实体
        result = result.replacingOccurrences(of: "&nbsp;", with: " ")
        result = result.replacingOccurrences(of: "&amp;", with: "&")
        result = result.replacingOccurrences(of: "&lt;", with: "<")
        result = result.replacingOccurrences(of: "&gt;", with: ">")
        result = result.replacingOccurrences(of: "&quot;", with: "\"")
        result = result.replacingOccurrences(of: "&#39;", with: "'")
        result = result.replacingOccurrences(of: "&apos;", with: "'")

        // 4. 折叠多余空白字符
        result = result.replacingOccurrences(
            of: "\\s+",
            with: " ",
            options: .regularExpression
        )

        return result.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
