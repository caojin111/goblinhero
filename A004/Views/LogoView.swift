//
//  LogoView.swift
//  A004
//
//  工作室Logo页面
//

import SwiftUI

struct LogoView: View {
    @Binding var isPresented: Bool
    @State private var logoOpacity: Double = 0.0
    @State private var backgroundOpacity: Double = 1.0
    @ObservedObject var audioManager = AudioManager.shared
    
    var body: some View {
        ZStack {
            // 黑色背景
            Color.black
                .ignoresSafeArea()
                .opacity(backgroundOpacity)
            
            // Logo图片居中
            Image("logo")
                .resizable()
                .scaledToFit()
                .frame(maxWidth: 300, maxHeight: 300)
                .opacity(logoOpacity)
        }
        .onAppear {
            // Logo渐现动画（1秒）
            withAnimation(.easeIn(duration: 1.0)) {
                logoOpacity = 1.0
            }
            
            // Logo出现0.5秒后播放音效
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                audioManager.playSoundEffect("cat", fileExtension: "mp3")
            }
            
            // 1.5秒后直接关闭Logo页面，跳转到splash页面（不要渐隐效果）
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                isPresented = false
            }
        }
    }
}

