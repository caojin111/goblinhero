//
//  MineExplosionAnimationView.swift
//  A004
//
//  矿坑爆炸动画视图（帧动画）
//

import SwiftUI

struct MineExplosionAnimationView: View {
    let frameCount: Int = 12 // 总帧数：mine_1 到 mine_12
    let animationDuration: Double = 0.5 // 动画持续时间（秒）
    
    @State private var currentFrame: Int = 0
    @State private var animationTimer: Timer?
    @State private var isAnimating: Bool = false
    @State private var hasPlayedSound: Bool = false // 标记是否已播放音效
    var onComplete: (() -> Void)? // 动画完成回调
    
    var body: some View {
        GeometryReader { geometry in
            let frameName = String(format: "mine_%d", currentFrame + 1)
            
            Image(frameName)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: geometry.size.width, height: geometry.size.height)
        }
        .clipped()
        .opacity(isAnimating ? 1.0 : 0.0)
        .onAppear {
            // 重置音效播放标记，确保每次新的爆炸动画都能播放音效
            hasPlayedSound = false
            startAnimation()
        }
        .onDisappear {
            stopAnimation()
        }
    }
    
    private func startAnimation() {
        // 播放爆炸音效（只播放一次）
        if !hasPlayedSound {
            AudioManager.shared.playSoundEffect("boom", fileExtension: "wav")
            hasPlayedSound = true
        }
        
        // 先停止可能存在的定时器
        stopAnimation()
        
        isAnimating = true
        currentFrame = 0
        
        // 计算每帧的持续时间
        let frameDuration = animationDuration / Double(frameCount)
        
        // 创建定时器，播放一次动画
        // 注意：结构体不需要 weak 引用，直接使用 self
        animationTimer = Timer.scheduledTimer(withTimeInterval: frameDuration, repeats: true) { timer in
            // 更新帧索引
            currentFrame += 1
            
            // 如果播放完所有帧，停止动画
            if currentFrame >= frameCount {
                timer.invalidate()
                animationTimer = nil
                isAnimating = false
                // 调用完成回调
                onComplete?()
            }
        }
        
        // 将定时器添加到 common mode，确保在滚动等操作时也能正常运行
        if let timer = animationTimer {
            RunLoop.current.add(timer, forMode: .common)
        }
    }
    
    private func stopAnimation() {
        animationTimer?.invalidate()
        animationTimer = nil
        isAnimating = false
    }
}

#Preview {
    MineExplosionAnimationView()
        .frame(width: 60, height: 60)
}
