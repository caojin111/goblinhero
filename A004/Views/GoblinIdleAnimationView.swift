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
    
    @ObservedObject var audioManager = AudioManager.shared
    @State private var currentFrame: Int = 0
    @State private var animationTimer: Timer?
    @State private var showEmoji: Bool = false
    @State private var currentEmoji: Int = 1 // 当前显示的 emoji 编号（1-5）
    @State private var emojiTimer: Timer?
    @Binding var triggerEmoji1: Bool // 外部触发显示emoji1
    
    var body: some View {
        GeometryReader { geometry in
            let frameName = String(format: "goblin_%02d", currentFrame + 1)
            let emojiSize = min(80, geometry.size.width * 0.4)
            
            ZStack(alignment: .top) {
                // 哥布林动画（需要裁剪）
                Image(frameName)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .clipped()
                
                // 对话气泡（单独一层，覆盖在哥布林动画之上，不被裁剪，跟随哥布林一起浮动）
                // 注意：不单独应用 FloatingAnimation，让它跟随外层的 FloatingAnimation 一起浮动
                if showEmoji {
                    Image("emoji\(currentEmoji)")
                        .resizable()
                        .scaledToFit()
                        .frame(width: emojiSize, height: emojiSize)
                        .offset(y: -emojiSize / 2 - 10) // 在顶部上方，留10像素间距
                        .transition(.scale.combined(with: .opacity))
                        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: showEmoji)
                        .zIndex(1000) // 确保在最上层
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
        .contentShape(Rectangle()) // 确保整个区域可点击
        .onTapGesture {
            print("🎭 [首页] 点击哥布林动画")
            // 播放音效
            audioManager.playSoundEffect("greeting", fileExtension: "wav")
            showRandomEmoji()
        }
        .onAppear {
            startAnimation()
        }
        .onDisappear {
            stopAnimation()
            hideEmoji()
        }
        .onChange(of: triggerEmoji1) { triggered in
            if triggered {
                showEmoji1()
                // 重置触发标志
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    triggerEmoji1 = false
                }
            }
        }
    }
    
    /// 显示随机 emoji
    private func showRandomEmoji() {
        // 随机选择 1-5 的 emoji
        currentEmoji = Int.random(in: 1...5)
        showEmoji = true
        
        // 取消之前的定时器
        emojiTimer?.invalidate()
        
        // 2秒后自动消失
        emojiTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: false) { _ in
            hideEmoji()
        }
        // 将定时器添加到 common mode，确保在滚动等操作时也能正常运行
        if let timer = emojiTimer {
            RunLoop.current.add(timer, forMode: .common)
        }
    }
    
    /// 显示 emoji1
    private func showEmoji1() {
        currentEmoji = 1
        showEmoji = true
        
        // 取消之前的定时器
        emojiTimer?.invalidate()
        
        // 2秒后自动消失
        emojiTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: false) { _ in
            hideEmoji()
        }
        // 将定时器添加到 common mode，确保在滚动等操作时也能正常运行
        if let timer = emojiTimer {
            RunLoop.current.add(timer, forMode: .common)
        }
    }
    
    /// 隐藏 emoji
    private func hideEmoji() {
        withAnimation {
            showEmoji = false
        }
        emojiTimer?.invalidate()
        emojiTimer = nil
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
    GoblinIdleAnimationView(triggerEmoji1: .constant(false))
        .frame(width: 200, height: 200)
}

