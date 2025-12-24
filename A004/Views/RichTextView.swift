//
//  RichTextView.swift
//  A004
//
//  Created for parsing rich text with color tags
//

import SwiftUI

struct RichTextView: View {
    let text: String
    let defaultColor: Color
    let font: Font?
    let multilineTextAlignment: TextAlignment?
    
    init(_ text: String, defaultColor: Color = .white, font: Font? = nil, multilineTextAlignment: TextAlignment? = nil) {
        self.text = text
        self.defaultColor = defaultColor
        self.font = font
        self.multilineTextAlignment = multilineTextAlignment
    }
    
    var body: some View {
        parseRichText(text)
    }
    
    @ViewBuilder
    private func parseRichText(_ text: String) -> some View {
        let components = parseTextComponents(text)
        let textView = buildText(from: components)
        
        if let alignment = multilineTextAlignment {
            textView.multilineTextAlignment(alignment)
        } else {
            textView
        }
    }
    
    private func buildText(from components: [TextComponent]) -> Text {
        if components.count == 1 {
            // 单个组件，直接构建
            var textView = Text(components[0].text)
            if let font = font {
                textView = textView.font(font)
            }
            return textView.foregroundColor(components[0].color)
        } else {
            // 多个组件，组合 Text
            var combinedText = Text("")
            for component in components {
                var componentText = Text(component.text)
                if let font = font {
                    componentText = componentText.font(font)
                }
                componentText = componentText.foregroundColor(component.color)
                combinedText = combinedText + componentText
            }
            return combinedText
        }
    }
    
    private func parseTextComponents(_ text: String) -> [TextComponent] {
        var components: [TextComponent] = []
        var currentIndex = text.startIndex
        var currentColor = defaultColor
        
        while currentIndex < text.endIndex {
            // 查找 <color=#hex> 标签
            if let colorStart = text.range(of: "<color=", range: currentIndex..<text.endIndex),
               let colorEnd = text.range(of: ">", range: colorStart.upperBound..<text.endIndex) {
                
                // 添加标签前的文本（如果有）
                let beforeText = String(text[currentIndex..<colorStart.lowerBound])
                if !beforeText.isEmpty {
                    components.append(TextComponent(text: beforeText, color: currentColor))
                }
                
                // 提取颜色值
                let colorHex = String(text[colorStart.upperBound..<colorEnd.lowerBound])
                currentColor = Color(hex: colorHex)
                
                // 查找对应的 </color> 标签
                if let closeTag = text.range(of: "</color>", range: colorEnd.upperBound..<text.endIndex) {
                    // 提取标签内的文本
                    let coloredText = String(text[colorEnd.upperBound..<closeTag.lowerBound])
                    if !coloredText.isEmpty {
                        components.append(TextComponent(text: coloredText, color: currentColor))
                    }
                    
                    // 重置颜色为默认值
                    currentColor = defaultColor
                    currentIndex = closeTag.upperBound
                } else {
                    // 没有找到闭合标签，添加剩余文本
                    let remainingText = String(text[colorEnd.upperBound...])
                    if !remainingText.isEmpty {
                        components.append(TextComponent(text: remainingText, color: currentColor))
                    }
                    break
                }
            } else {
                // 没有找到更多标签，添加剩余文本
                let remainingText = String(text[currentIndex...])
                if !remainingText.isEmpty {
                    components.append(TextComponent(text: remainingText, color: currentColor))
                }
                break
            }
        }
        
        return components.isEmpty ? [TextComponent(text: text, color: defaultColor)] : components
    }
}

struct TextComponent {
    let text: String
    let color: Color
}
