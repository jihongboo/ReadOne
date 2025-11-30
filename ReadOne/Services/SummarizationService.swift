//
//  SummarizationService.swift
//  ReadOne
//
//  Created by 纪洪波 on 11/30/25.
//

import Foundation
import Observation

#if canImport(FoundationModels)
    import FoundationModels
#endif

enum SummarizationError: LocalizedError {
    case deviceNotEligible
    case appleIntelligenceNotEnabled
    case modelNotReady
    case unsupportedSystemVersion
    case foundationModelsNotSupported
    case unknownStatus

    var errorDescription: String? {
        switch self {
        case .deviceNotEligible:
            return String(localized: "Device does not support Apple Intelligence")
        case .appleIntelligenceNotEnabled:
            return String(localized: "Please enable Apple Intelligence in System Settings")
        case .modelNotReady:
            return String(localized: "AI model is downloading, please try again later")
        case .unsupportedSystemVersion:
            return String(localized: "Requires iOS 26.0 or macOS 26.0 or later")
        case .foundationModelsNotSupported:
            return String(localized: "Current system does not support Foundation Models")
        case .unknownStatus:
            return String(localized: "AI feature is temporarily unavailable")
        }
    }
}

/// 文章内容总结服务，使用 Apple Foundation Models 框架
@Observable
final class SummarizationService {
    /// 检查设备是否支持 Foundation Models
    /// - Throws: 当 AI 功能不可用时抛出 SummarizationError
    static func checkAvailability() throws(SummarizationError) {
        #if canImport(FoundationModels)
            if #available(iOS 26.0, macOS 26.0, *) {
                let model = SystemLanguageModel.default
                switch model.availability {
                case .available:
                    return
                case .unavailable(let reason):
                    switch reason {
                    case .deviceNotEligible:
                        throw SummarizationError.deviceNotEligible
                    case .appleIntelligenceNotEnabled:
                        throw SummarizationError.appleIntelligenceNotEnabled
                    case .modelNotReady:
                        throw SummarizationError.modelNotReady
                    @unknown default:
                        throw SummarizationError.unknownStatus
                    }
                @unknown default:
                    throw SummarizationError.unknownStatus
                }
            } else {
                throw SummarizationError.unsupportedSystemVersion
            }
        #else
            throw SummarizationError.foundationModelsNotSupported
        #endif
    }

    /// 总结文章内容
    /// - Parameters:
    ///   - title: 文章标题
    ///   - content: 文章内容（HTML或纯文本）
    /// - Returns: 生成的摘要文本
    /// - Throws: 当 AI 功能不可用或总结失败时抛出错误
    static func summarize(article: Article) async throws -> String {
        try Self.checkAvailability()

        #if canImport(FoundationModels)
            if #available(iOS 26.0, macOS 26.0, *) {
                let session = LanguageModelSession()

                // 清理HTML标签获取纯文本
                let content = article.content.isEmpty ? article.articleDescription : article.content
                let plainText = content.stripHTMLForSummary()

                // 限制内容长度以避免超出模型限制
                let truncatedContent = String(plainText.prefix(4000))

                let promptTemplate = String(
                    localized: """
                        Please summarize the core content of the following article. Requirements:
                        1. The summary should be concise and clear, within 200 words
                        2. Extract the main points and key information
                        3. Use clear language

                        Article title: %@

                        Article content:
                        %@
                        """)
                let prompt = String(format: promptTemplate, article.title, truncatedContent)

                let response = try await session.respond(to: prompt)
                return response.content
            }
        #endif

        return ""
    }
}

// MARK: - String Extension for Summary
extension String {
    /// 移除HTML标签用于AI总结
    func stripHTMLForSummary() -> String {
        // 移除script和style标签及其内容
        var result = self.replacingOccurrences(
            of: "<script[^>]*>[\\s\\S]*?</script>",
            with: "",
            options: .regularExpression
        )
        result = result.replacingOccurrences(
            of: "<style[^>]*>[\\s\\S]*?</style>",
            with: "",
            options: .regularExpression
        )

        // 移除所有HTML标签
        result = result.replacingOccurrences(
            of: "<[^>]+>",
            with: "",
            options: .regularExpression
        )

        // 解码HTML实体
        result = result.replacingOccurrences(of: "&nbsp;", with: " ")
        result = result.replacingOccurrences(of: "&amp;", with: "&")
        result = result.replacingOccurrences(of: "&lt;", with: "<")
        result = result.replacingOccurrences(of: "&gt;", with: ">")
        result = result.replacingOccurrences(of: "&quot;", with: "\"")
        result = result.replacingOccurrences(of: "&#39;", with: "'")

        // 清理多余空白
        result = result.replacingOccurrences(
            of: "\\s+",
            with: " ",
            options: .regularExpression
        )

        return result.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
