//
//  LanguageSelectionView.swift
//  A004
//
//  语言选择视图
//

import SwiftUI

struct LanguageSelectionView: View {
    @ObservedObject var localizationManager = LocalizationManager.shared
    @Binding var isPresented: Bool
    
    // 获取自定义字体
    private func customFont(size: CGFloat) -> Font {
        return FontManager.shared.customFont(size: size)
    }

    var body: some View {
        ZStack {
            // 背景
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {
                    isPresented = false
                }

            VStack(spacing: 25) {
                // 标题
                Text(localizationManager.localized("settings.language"))
                    .font(customFont(size: 28))
                    .foregroundColor(.white)
                    .textStroke()

                // 语言选项
                VStack(spacing: 10) {
                    ForEach(localizationManager.getAvailableLanguages(), id: \.code) { language in
                        Button(action: {
                            localizationManager.currentLanguage = language.code
                            isPresented = false
                        }) {
                            HStack {
                                Text(language.name)
                                    .font(
                                        // 英文界面时，如果显示的是"中文"，使用系统默认字体
                                        localizationManager.currentLanguage == "en" && language.code == "zh" 
                                            ? .system(size: 17) 
                                            : customFont(size: 17)
                                    )
                                    .foregroundColor(.white)
                                    .textStroke()

                                Spacer()

                                if localizationManager.currentLanguage == language.code {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.green)
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 15)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(localizationManager.currentLanguage == language.code ?
                                          Color.green.opacity(0.3) :
                                          Color.white.opacity(0.1))
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }

                // 关闭按钮
                Button(localizationManager.localized("settings.close")) {
                    isPresented = false
                }
                .font(customFont(size: 17))
                .foregroundColor(.white)
                .textStroke()
                .padding(.horizontal, 30)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.white.opacity(0.2))
                )
            }
            .padding(30)
            .background(
                RoundedRectangle(cornerRadius: 25)
                    .fill(Color.black.opacity(0.9))
            )
            .padding(40)
        }
        .transition(.scale)
    }
}

#Preview {
    LanguageSelectionView(isPresented: .constant(true))
}
