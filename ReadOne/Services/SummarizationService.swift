//
//  SummarizationService.swift
//  ReadOne
//
//  Created by 纪洪波 on 11/30/25.
//

import Foundation

#if canImport(FoundationModels)
    import FoundationModels
#endif

/// 文章内容总结服务，使用 Apple Foundation Models 框架
@Observable
final class SummarizationService {
    var summary: String = ""
    var isLoading: Bool = false
    var error: String?
    var isAvailable: Bool = false
    var unavailableReason: String?

    init() {
        checkAvailability()
    }

    /// 检查设备是否支持 Foundation Models
    func checkAvailability() {
        #if canImport(FoundationModels)
            if #available(iOS 26.0, macOS 26.0, *) {
                let model = SystemLanguageModel.default
                switch model.availability {
                case .available:
                    isAvailable = true
                    unavailableReason = nil
                case .unavailable(let reason):
                    isAvailable = false
                    switch reason {
                    case .deviceNotEligible:
                        unavailableReason = "设备不支持 Apple Intelligence"
                    case .appleIntelligenceNotEnabled:
                        unavailableReason = "请在系统设置中启用 Apple Intelligence"
                    case .modelNotReady:
                        unavailableReason = "AI 模型正在下载中，请稍后再试"
                    @unknown default:
                        unavailableReason = "AI 功能暂时不可用"
                    }
                @unknown default:
                    isAvailable = false
                    unavailableReason = "未知状态"
                }
            } else {
                isAvailable = false
                unavailableReason = "需要 iOS 26.0 或 macOS 26.0 以上系统"
            }
        #else
            isAvailable = false
            unavailableReason = "当前系统不支持 Foundation Models"
        #endif
    }

    /// 总结文章内容
    /// - Parameters:
    ///   - title: 文章标题
    ///   - content: 文章内容（HTML或纯文本）
    func summarize(title: String, content: String) async {
        guard isAvailable else {
            error = unavailableReason ?? "AI 总结功能不可用"
            return
        }

        isLoading = true
        error = nil
        summary = ""

        #if canImport(FoundationModels)
            if #available(iOS 26.0, macOS 26.0, *) {
                do {
                    let session = LanguageModelSession()

                    // 清理HTML标签获取纯文本
                    let plainText = content.stripHTMLForSummary()

                    // 限制内容长度以避免超出模型限制
                    let truncatedContent = String(plainText.prefix(4000))

                    let prompt = """
                        请用中文总结以下文章的核心内容，要求：
                        1. 总结要简洁明了，控制在200字以内
                        2. 提取文章的主要观点和关键信息
                        3. 使用清晰的语言表达

                        文章标题：\(title)

                        文章内容：
                        \(truncatedContent)
                        """

                    let response = try await session.respond(to: prompt)
                    summary = response.content
                } catch {
                    self.error = "总结失败：\(error.localizedDescription)"
                }
            }
        #endif

        isLoading = false
    }

    /// 清除当前总结
    func clear() {
        summary = ""
        error = nil
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
