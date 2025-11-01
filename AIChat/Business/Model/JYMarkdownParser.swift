//
//  JYMarkdownParser.swift
//  AIChat
//
//  Created by JiangYing on 2025/11/2.
//

import Foundation
import MarkdownKit

@objc(JYMarkdownParser)
class JYMarkdownParser: NSObject {
    @objc
    static func parseThought(markdown: String) -> NSAttributedString {
        let parser = MarkdownParser(font: UIFont.systemFont(ofSize: 14), color: UIColor(red: 136 / 255.0, green: 136 / 255.0, blue: 136 / 255.0, alpha: 1))
        let attributedString = parser.parse(markdown)
        return attributedString
    }
    
    @objc
    static func parseContent(markdown: String) -> NSAttributedString {
        let parser = MarkdownParser(font: UIFont.systemFont(ofSize: 16), color: UIColor(red: 34.0 / 255.0, green: 34.0 / 255.0, blue: 34.0 / 255.0, alpha: 1))
        let attributedString = parser.parse(markdown)
        return attributedString
    }
}
