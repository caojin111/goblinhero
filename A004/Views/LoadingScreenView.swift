//
//  LoadingScreenView.swift
//  A004
//
//  Loading 页面视图（带 loading 动画）
//

import SwiftUI

struct LoadingScreenView: View {
    @State private var progress: Double = 0.0
    @State private var logoScale: CGFloat = 1.0 // Logo 缩放动画
    @ObservedObject var audioManager = AudioManager.shared
    let onComplete: () -> Void // Loading 完成后的回调
    
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
                
                // Logo 层（Figma 位置：x: 39, y: 70, 尺寸：329×176，缩小 1.2 倍，带呼吸动画）
                if UIImage(named: "loading_image1") != nil {
                    Image("loading_image1")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(
                            width: (329 / 1.2) * (geometry.size.width / figmaWidth),
                            height: (176 / 1.2) * (geometry.size.height / figmaHeight)
                        )
                        .scaleEffect(logoScale)
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
                
                // Loading Bar 动画层（Figma 位置：x: 53, y: 654, 尺寸：300×114，扩大 1.5 倍）
                LoadingBarAnimationView(progress: progress)
                    .frame(
                        width: (300 * 1.15) * (geometry.size.width / figmaWidth),
                        height: (114 * 1.15) * (geometry.size.height / figmaHeight)
                    )
                    .position(
                        x: (53 + 300/2) * (geometry.size.width / figmaWidth),
                        y: (654 + 114/2) * (geometry.size.height / figmaHeight)
                    )
            }
        }
        .ignoresSafeArea()
        .onAppear {
            print("⏳ [LoadingScreen] 视图出现，准备播放首页背景音乐")
            // 播放首页背景音乐
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                audioManager.playBackgroundMusic(fileName: "homepage", fileExtension: "mp3")
            }
            startLoading()
            startLogoAnimation()
        }
        .onDisappear {
            print("⏳ [LoadingScreen] 视图消失")
            // Loading界面消失时不停止音乐，因为会转到首页继续播放
        }
    }
    
    private func startLoading() {
        // 模拟加载过程（2秒内完成）
        let totalSteps = 100
        let duration = 2.0 // 2 秒完成
        let stepDuration = duration / Double(totalSteps)

        for step in 1...totalSteps {
            DispatchQueue.main.asyncAfter(deadline: .now() + stepDuration * Double(step)) {
                self.progress = Double(step) / Double(totalSteps)
            }
        }
        
        // 2 秒后调用完成回调
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
            print("✅ [LoadingScreen] Loading 完成，跳转到首页")
            onComplete()
        }
    }
    
    private func startLogoAnimation() {
        // Logo 呼吸动画：轻微缩放效果（1.0 -> 1.05 -> 1.0，循环）
        withAnimation(
            Animation.easeInOut(duration: 1.5)
                .repeatForever(autoreverses: true)
        ) {
            logoScale = 1.05
        }
    }
}

#Preview {
    LoadingScreenView {
        print("Loading 完成")
    }
}

