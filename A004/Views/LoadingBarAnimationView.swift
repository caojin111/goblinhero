//
//  LoadingBarAnimationView.swift
//  A004
//
//  Loading Bar 动画视图（使用单独图片）
//

import SwiftUI

struct LoadingBarAnimationView: View {
    let frameCount: Int = 20 // 总帧数
    var progress: Double // 0.0 - 1.0 的进度值
    
    var body: some View {
        GeometryReader { geometry in
            let currentFrame = Int(progress * Double(frameCount))
            let frameName = String(format: "loading_%02d", currentFrame + 1)
            
            Image(frameName)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: geometry.size.width, height: geometry.size.height)
        }
        .clipped()
        .onChange(of: progress) { newProgress in
            let currentFrame = Int(newProgress * Double(frameCount))
            let frameName = String(format: "loading_%02d", currentFrame + 1)
            print("📺 [LoadingBar] 进度: \(Int(newProgress * 100))%, 显示: \(frameName)")
        }
    }
}

#Preview {
    LoadingBarAnimationView(progress: 0.5)
}
