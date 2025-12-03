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
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.white)

                // 语言选项
                VStack(spacing: 10) {
                    ForEach(localizationManager.getAvailableLanguages(), id: \.code) { language in
                        Button(action: {
                            localizationManager.currentLanguage = language.code
                            isPresented = false
                        }) {
                            HStack {
                                Text(language.name)
                                    .font(.headline)
                                    .foregroundColor(.white)

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
                .font(.headline)
                .foregroundColor(.white)
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
