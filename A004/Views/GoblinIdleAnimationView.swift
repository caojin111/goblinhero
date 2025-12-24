//
//  GoblinIdleAnimationView.swift
//  A004
//
//  哥布林待机循环动画视图
//

import SwiftUI

struct GoblinIdleAnimationView: View {
    let frameCount: Int = 6 // 总帧数：goblin_01 到 goblin_06
    let animationDuration: Double = 1.0 // 完整循环的持续时间（秒）
    
    @State private var currentFrame: Int = 0
    @State private var animationTimer: Timer?
    
    var body: some View {
        GeometryReader { geometry in
            let frameName = String(format: "goblin_%02d", currentFrame + 1)
            
            Image(frameName)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: geometry.size.width, height: geometry.size.height)
        }
        .clipped()
        .onAppear {
            startAnimation()
        }
        .onDisappear {
            stopAnimation()
        }
    }
    
    private func startAnimation() {
        // 先停止可能存在的定时器
        stopAnimation()
        
        // 计算每帧的持续时间
        let frameDuration = animationDuration / Double(frameCount)
        
        // 创建定时器，循环播放动画
        // 不使用 withAnimation，直接更新帧索引以避免闪烁
        animationTimer = Timer.scheduledTimer(withTimeInterval: frameDuration, repeats: true) { _ in
            // 直接更新帧索引，SwiftUI 会自动处理 UI 更新
            currentFrame = (currentFrame + 1) % frameCount
        }
        
        // 将定时器添加到 common mode，确保在滚动等操作时也能正常运行
        if let timer = animationTimer {
            RunLoop.current.add(timer, forMode: .common)
        }
    }
    
    private func stopAnimation() {
        animationTimer?.invalidate()
        animationTimer = nil
    }
}

#Preview {
    GoblinIdleAnimationView()
        .frame(width: 200, height: 200)
}

