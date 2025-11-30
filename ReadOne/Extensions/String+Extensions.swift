//
//  String+Extensions.swift
//  ReadOne
//
//  Created by 纪洪波 on 11/30/25.
//

import Foundation

#if canImport(AppKit)
    import AppKit
#elseif canImport(UIKit)
    import UIKit
#endif

extension String {
    func stripHTML() -> String {
        guard let data = self.data(using: .utf8) else { return self }

        let options: [NSAttributedString.DocumentReadingOptionKey: Any] = [
            .documentType: NSAttributedString.DocumentType.html,
            .characterEncoding: String.Encoding.utf8.rawValue,
        ]

        guard
            let attributedString = try? NSAttributedString(
                data: data, options: options, documentAttributes: nil)
        else {
            return self.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
        }

        return attributedString.string
    }
}
