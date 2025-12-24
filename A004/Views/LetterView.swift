//
//  LetterView.swift
//  A004
//
//  信页面视图（哥布林选择后显示）
//

import SwiftUI

struct LetterView: View {
    @ObservedObject var localizationManager = LocalizationManager.shared
    @ObservedObject var audioManager = AudioManager.shared
    let opacity: Double // 从外部传入的透明度值
    let onDismiss: () -> Void // 点击后关闭并进入游戏的回调
    @State private var hasPlayedSound: Bool = false // 标记是否已播放音效
    
    // 根据当前语言获取信图片名称
    private var letterImageName: String {
        localizationManager.currentLanguage == "zh" ? "letter_Chinese" : "letter_English"
    }
    
    var body: some View {
        ZStack {
            // 黑色背景
            Color.black
                .ignoresSafeArea()
            
            // 信图片（居中显示）
            Image(letterImageName)
                .resizable()
                .scaledToFit()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding()
        }
        .opacity(opacity) // 使用外部传入的透明度
        .onTapGesture {
            print("📜 [信页面] 玩家点击，进入游戏")
            onDismiss()
        }
        .onAppear {
            print("📜 [信页面] 视图出现，当前opacity: \(opacity)")
        }
        .onChange(of: opacity) { newOpacity in
            // 当信页面开始显示时（opacity从0变为>0.1），播放音效
            if newOpacity > 0.1 && !hasPlayedSound {
                print("📜 [信页面] 开始显示（opacity: \(newOpacity)），播放音效 letter.wav")
                audioManager.playSoundEffect("letter", fileExtension: "wav")
                hasPlayedSound = true
            }
        }
    }
}

#Preview {
    LetterView(opacity: 1.0) {
        print("信页面关闭")
    }
}
