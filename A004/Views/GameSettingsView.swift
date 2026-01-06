//
//  GameSettingsView.swift
//  A004
//
//  游戏设置界面
//

import SwiftUI

struct GameSettingsView: View {
    @ObservedObject var viewModel: GameViewModel
    @ObservedObject var configManager = GameConfigManager.shared
    @ObservedObject var localizationManager = LocalizationManager.shared
    @ObservedObject var audioManager = AudioManager.shared
    @Binding var isPresented: Bool
    @State private var showLanguageSelection = false
    @State private var showSymbolBook = false
    
    // 语言选择按钮
    private var languageButton: some View {
        Button(action: {
            showLanguageSelection = true
        }) {
            HStack {
                Image(systemName: "globe")
                    .font(.title2)
                    .foregroundColor(.green)

                VStack(alignment: .leading, spacing: 5) {
                    Text(localizationManager.localized("settings.language"))
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .textStroke()

                    Text("\(localizationManager.getAvailableLanguages().first { $0.code == localizationManager.currentLanguage }?.name ?? "Unknown")")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                        .textStroke()
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .foregroundColor(.white.opacity(0.6))
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 15)
                    .fill(Color.white.opacity(0.1))
            )
        }
        .buttonStyle(PlainButtonStyle())
    }

    // 音乐开关
    private var musicToggle: some View {
        HStack {
            Image(systemName: "music.note")
                .font(.title2)
                .foregroundColor(.purple)

            Text(localizationManager.localized("settings.music"))
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .textStroke()

            Spacer()

            Toggle("", isOn: $audioManager.isMusicEnabled)
                .labelsHidden()
                .tint(.purple)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color.white.opacity(0.1))
        )
    }

    // 音效开关
    private var soundToggle: some View {
        HStack {
            Image(systemName: "speaker.wave.2")
                .font(.title2)
                .foregroundColor(.blue)

            Text(localizationManager.localized("settings.sound_effects"))
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .textStroke()

            Spacer()

            Toggle("", isOn: $audioManager.isSoundEffectsEnabled)
                .labelsHidden()
                .tint(.blue)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color.white.opacity(0.1))
        )
    }

    // 图鉴按钮
    private var bookButton: some View {
        Button(action: {
            showSymbolBook = true
        }) {
            HStack {
                Image(systemName: "book.fill")
                    .font(.title2)
                    .foregroundColor(.blue)

                Text(localizationManager.localized("settings.book"))
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .textStroke()

                Spacer()

                Image(systemName: "chevron.right")
                    .foregroundColor(.white.opacity(0.6))
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 15)
                    .fill(Color.white.opacity(0.1))
            )
        }
        .buttonStyle(PlainButtonStyle())
    }


    // 退出游戏按钮
    private var exitButton: some View {
        Button(action: {
            viewModel.exitToHome()
            isPresented = false
        }) {
            HStack {
                Image(systemName: "house.fill")
                    .font(.title2)
                    .foregroundColor(.red)

                VStack(alignment: .leading, spacing: 5) {
                    Text(localizationManager.localized("settings.exit_game"))
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .textStroke()

                    Text(localizationManager.localized("settings.back_to_home"))
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                        .textStroke()
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .foregroundColor(.white.opacity(0.6))
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 15)
                    .fill(Color.red.opacity(0.2))
            )
        }
        .buttonStyle(PlainButtonStyle())
    }

    var body: some View {
        ZStack {
            // 背景
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {
                    isPresented = false
                }

            VStack(spacing: 0) {
                // 标题
                Text(localizationManager.localized("settings.title"))
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .textStroke()
                    .padding(.top, 20)
                    .padding(.bottom, 15)

                // 内容区域 - 可滚动
                ScrollView {
                VStack(spacing: 15) {
                    languageButton
                    musicToggle
                    soundToggle
                    bookButton
                    exitButton
                    }
                    .padding(.horizontal, 20)
                }
                .fixedSize(horizontal: false, vertical: true) // 自适应高度
                .padding(.bottom, 15)
                
                // 关闭按钮（固定在底部）
                Button(localizationManager.localized("settings.close")) {
                    isPresented = false
                }
                .font(.headline)
                .foregroundColor(.white)
                .textStroke()
                .padding(.horizontal, 30)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.white.opacity(0.2))
                )
                .padding(.bottom, 20)
            }
            .frame(maxWidth: 500)
            .background(
                RoundedRectangle(cornerRadius: 25)
                    .fill(Color.black.opacity(0.9))
            )
            .padding(40)

            // 语言选择弹窗
            if showLanguageSelection {
                LanguageSelectionView(isPresented: $showLanguageSelection)
            }
            
            // 图鉴弹窗
            if showSymbolBook {
                SymbolBookView(isPresented: $showSymbolBook, viewModel: viewModel)
            }
        }
        .transition(.scale)
    }
}

#Preview {
    GameSettingsView(
        viewModel: GameViewModel(),
        isPresented: .constant(true)
    )
}
