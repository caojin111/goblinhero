//
//  TextStrokeModifier.swift
//  A004
//
//  文字描边修饰符
//

import SwiftUI

/// 文字描边修饰符（1像素黑色描边）
struct TextStrokeModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .shadow(color: .black, radius: 0, x: -1, y: 0)
            .shadow(color: .black, radius: 0, x: 1, y: 0)
            .shadow(color: .black, radius: 0, x: 0, y: -1)
            .shadow(color: .black, radius: 0, x: 0, y: 1)
            .shadow(color: .black, radius: 0, x: -1, y: -1)
            .shadow(color: .black, radius: 0, x: 1, y: -1)
            .shadow(color: .black, radius: 0, x: -1, y: 1)
            .shadow(color: .black, radius: 0, x: 1, y: 1)
    }
}

extension View {
    /// 添加 1 像素黑色描边
    func textStroke() -> some View {
        modifier(TextStrokeModifier())
    }
}

