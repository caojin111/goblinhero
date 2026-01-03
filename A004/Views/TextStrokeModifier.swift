//
//  TextStrokeModifier.swift
//  A004
//
//  文字描边修饰符
//

import SwiftUI

/// 文字描边修饰符（变细的黑色描边）- 优化版本
struct TextStrokeModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .shadow(color: .black, radius: 0, x: -0.5, y: 0)
            .shadow(color: .black, radius: 0, x: 0.5, y: 0)
            .shadow(color: .black, radius: 0, x: 0, y: -0.5)
            .shadow(color: .black, radius: 0, x: 0, y: 0.5)
            .shadow(color: .black, radius: 0, x: -0.5, y: -0.5)
            .shadow(color: .black, radius: 0, x: 0.5, y: -0.5)
            .shadow(color: .black, radius: 0, x: -0.5, y: 0.5)
            .shadow(color: .black, radius: 0, x: 0.5, y: 0.5)
    }
}

extension View {
    /// 添加 1 像素黑色描边
    func textStroke() -> some View {
        modifier(TextStrokeModifier())
    }
    
    /// 添加自定义颜色和宽度的描边
    func textStroke(color: Color, width: CGFloat) -> some View {
        self
            .shadow(color: color, radius: 0, x: -width, y: 0)
            .shadow(color: color, radius: 0, x: width, y: 0)
            .shadow(color: color, radius: 0, x: 0, y: -width)
            .shadow(color: color, radius: 0, x: 0, y: width)
            .shadow(color: color, radius: 0, x: -width, y: -width)
            .shadow(color: color, radius: 0, x: width, y: -width)
            .shadow(color: color, radius: 0, x: -width, y: width)
            .shadow(color: color, radius: 0, x: width, y: width)
    }
}

