//
//  SpriteSheetAnimationView.swift
//  A004
//
//  Sprite Sheet 帧动画视图（进度同步版本）
//

import SwiftUI

struct SpriteSheetAnimationView: View {
    let imageName: String // Asset 中的图片名称
    let frameCount: Int // 总帧数
    let columns: Int // 每行的帧数
    let frameWidth: CGFloat // 单帧宽度
    let frameHeight: CGFloat // 单帧高度
    let animationDuration: Double // 动画持续时间（秒）
    
    var progress: Double // 0.0 - 1.0 的进度值
    
    @State private var currentFrame: Int = 0
    
    var body: some View {
        GeometryReader { geometry in
            Image(imageName)
                .resizable()
                .scaledToFit()
                .frame(
                    width: geometry.size.width * CGFloat(columns),
                    height: geometry.size.height * CGFloat((frameCount + columns - 1) / columns)
                )
                .clipped()
                .offset(
                    x: -CGFloat(currentFrame % columns) * frameWidth,
                    y: -CGFloat(currentFrame / columns) * frameHeight
                )
        }
        .frame(width: frameWidth, height: frameHeight)
        .clipped()
        .onChange(of: progress) { newProgress in
            updateFrame(for: newProgress)
        }
        .onAppear {
            updateFrame(for: progress)
        }
    }
    
    private func updateFrame(for progress: Double) {
        // 根据进度计算当前帧（0.0 - 1.0 映射到 0 - frameCount-1）
        let frameIndex = Int(progress * Double(frameCount))
        let clampedFrame = max(0, min(frameIndex, frameCount - 1))
        
        withAnimation(.linear(duration: 0.1)) {
            currentFrame = clampedFrame
        }
        
        print("📺 [SpriteSheet] 进度: \(Int(progress * 100))%, 当前帧: \(clampedFrame)/\(frameCount)")
    }
}

#Preview {
    SpriteSheetAnimationView(
        imageName: "loading bar",
        frameCount: 20,
        columns: 4,
        frameWidth: 134,
        frameHeight: 78.4,
        animationDuration: 2.0,
        progress: 0.5 // 显示中间帧进行预览
    )
}

