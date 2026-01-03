//
//  PlayerNameInputView.swift
//  A004
//
//  玩家名字输入弹窗
//

import SwiftUI

struct PlayerNameInputView: View {
    @ObservedObject var viewModel: GameViewModel
    @ObservedObject var localizationManager = LocalizationManager.shared
    @ObservedObject var audioManager = AudioManager.shared
    @Binding var isPresented: Bool
    @State private var inputName: String = ""
    @FocusState private var isTextFieldFocused: Bool
    
    // 获取自定义字体
    private func customFont(size: CGFloat) -> Font {
        return FontManager.shared.customFont(size: size)
    }
    
    var body: some View {
        ZStack {
            // 半透明背景
            Color.black.opacity(0.5)
                .ignoresSafeArea()
                .onTapGesture {
                    // 点击背景不关闭，必须输入名字
                }
            
            // 弹窗内容
            VStack(spacing: 20) {
                // 标题
                Text(localizationManager.localized("player_name.title"))
                    .font(customFont(size: 24))
                    .foregroundColor(.white)
                    .textStroke()
                    .padding(.top, 20)
                
                // 输入框
                TextField(localizationManager.localized("player_name.placeholder"), text: $inputName)
                    .font(customFont(size: 18))
                    .foregroundColor(.white)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white.opacity(0.2))
                    )
                    .focused($isTextFieldFocused)
                    .onChange(of: inputName) { newValue in
                        // 限制最多10个字符
                        if newValue.count > 10 {
                            inputName = String(newValue.prefix(10))
                        }
                    }
                    .onAppear {
                        // 自动聚焦输入框
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            isTextFieldFocused = true
                        }
                    }
                
                // 字符数提示
                Text("\(inputName.count)/10")
                    .font(customFont(size: 14))
                    .foregroundColor(.white.opacity(0.6))
                
                // 确认按钮
                Button(action: {
                    audioManager.playSoundEffect("click", fileExtension: "wav")
                    if !inputName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        viewModel.savePlayerName(inputName.trimmingCharacters(in: .whitespacesAndNewlines))
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            isPresented = false
                        }
                    }
                }) {
                    Text(localizationManager.localized("player_name.confirm"))
                        .font(customFont(size: 18))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(inputName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? Color.gray.opacity(0.5) : Color.blue.opacity(0.8))
                        )
                }
                .disabled(inputName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .padding(.bottom, 20)
            }
            .padding(30)
            .frame(width: 320)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(hex: "363739"))
                    .shadow(color: .black.opacity(0.4), radius: 15, x: 0, y: 8)
            )
            .transition(.scale.combined(with: .opacity))
        }
    }
}

