//
//  FontManager.swift
//  A004
//
//  字体管理器
//

import SwiftUI
import CoreText

class FontManager {
    static let shared = FontManager()
    
    private var fibberishFontName: String?
    
    private init() {
        loadCustomFont()
    }
    
    /// 加载自定义字体
    private func loadCustomFont() {
        // 尝试多种路径查找字体文件
        var fontURL: URL?
        
        // 方式1: 在 Fonts 子目录中查找
        if let url = Bundle.main.url(forResource: "fibberish", withExtension: "ttf", subdirectory: "Fonts") {
            fontURL = url
        }
        // 方式2: 直接在 Bundle 根目录查找
        else if let url = Bundle.main.url(forResource: "fibberish", withExtension: "ttf") {
            fontURL = url
        }
        // 方式3: 使用完整路径查找
        else if let url = Bundle.main.url(forResource: "A004/Fonts/fibberish", withExtension: "ttf") {
            fontURL = url
        }
        
        guard let url = fontURL else {
            print("⚠️ [字体] 未找到 fibberish.ttf 文件，请确保文件已添加到 Xcode 项目中")
            return
        }
        
        guard let fontDataProvider = CGDataProvider(url: url as CFURL),
              let font = CGFont(fontDataProvider) else {
            print("⚠️ [字体] 无法加载字体文件")
            return
        }
        
        var error: Unmanaged<CFError>?
        if CTFontManagerRegisterGraphicsFont(font, &error) {
            if let postScriptName = font.postScriptName {
                fibberishFontName = postScriptName as String
                print("✅ [字体] 成功加载字体: \(fibberishFontName ?? "未知")")
            } else {
                // 如果无法获取 PostScript 名称，尝试从字体中获取名称
                if let fullName = font.fullName {
                    fibberishFontName = fullName as String
                    print("✅ [字体] 字体已加载，使用完整名称: \(fibberishFontName ?? "未知")")
                } else {
                    fibberishFontName = "Fibberish"
                    print("✅ [字体] 字体已加载，使用默认名称: Fibberish")
                }
            }
        } else {
            if let error = error?.takeUnretainedValue() {
                let errorDescription = CFErrorCopyDescription(error)
                print("❌ [字体] 字体注册失败: \(errorDescription ?? "未知错误" as CFString)")
                // 如果字体已经注册过，尝试直接使用字体名称
                if let postScriptName = font.postScriptName {
                    fibberishFontName = postScriptName as String
                    print("✅ [字体] 字体可能已注册，使用名称: \(fibberishFontName ?? "未知")")
                }
            }
        }
    }
    
    /// 获取自定义字体
    func customFont(size: CGFloat) -> Font {
        if let fontName = fibberishFontName {
            return .custom(fontName, size: size)
        } else {
            // 如果字体未找到，使用系统字体
            return .system(size: size)
        }
    }
}

