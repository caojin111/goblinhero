//
//  LaunchScreenView.swift
//  A004
//
//  启动页视图（基于 Figma 设计）
//

import SwiftUI

struct LaunchScreenView: View {
    // Figma 设计参数
    private let backgroundColor = Color(hex: "#3D7B52") // 背景色
    private let figmaWidth: CGFloat = 390
    private let figmaHeight: CGFloat = 844

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // 背景层
                backgroundColor
                    .ignoresSafeArea()
                
                // 背景图片层
                Image("loading BG")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .ignoresSafeArea()
                    .clipped()
                
                // Logo 层（Figma 位置：x: 39, y: 70, 尺寸：329×176，缩小 1.2 倍）
                if UIImage(named: "loading_image1") != nil {
                    Image("loading_image1")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(
                            width: (329 / 1.2) * (geometry.size.width / figmaWidth),
                            height: (176 / 1.2) * (geometry.size.height / figmaHeight)
                        )
                        .position(
                            x: (39 + 329/2) * (geometry.size.width / figmaWidth),
                            y: (70 + 176/2) * (geometry.size.height / figmaHeight)
                        )
                } else {
                    // 调试：如果图片不存在，显示占位符
                    Text("Logo 未找到")
                        .foregroundColor(.red)
                        .position(
                            x: (39 + 329/2) * (geometry.size.width / figmaWidth),
                            y: (70 + 176/2) * (geometry.size.height / figmaHeight)
                        )
                }
                
                // LaunchScreen 不显示 Loading Bar（Loading 在 LoadingScreenView 中显示）
            }
        }
        .ignoresSafeArea()
        .onAppear {
            // 启动页只显示图标，不显示 loading
        }
    }
}

// MARK: - Color Extension for Hex
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

#Preview {
    LaunchScreenView()
}
