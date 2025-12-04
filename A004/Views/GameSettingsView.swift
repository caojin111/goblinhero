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
    @Binding var isPresented: Bool
    @State private var showDifficultySelection = false
    @State private var showExitConfirm = false
    @State private var showLanguageSelection = false
    
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
                Text(localizationManager.localized("settings.title"))
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .textStroke()
                
                // 设置选项
                VStack(spacing: 15) {
                    // 语言选择按钮
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

                    // 难度选择按钮
                    Button(action: {
                        showDifficultySelection = true
                    }) {
                        HStack {
                            Image(systemName: "slider.horizontal.3")
                                .font(.title2)
                                .foregroundColor(.blue)

                            VStack(alignment: .leading, spacing: 5) {
                                Text(localizationManager.localized("settings.difficulty_settings"))
                                    .font(.headline)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                    .textStroke()

                                Text("\(localizationManager.localized("settings.current")): \(localizationManager.getDifficultyName(configManager.currentDifficulty))")
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
                    
                    // 退出游戏按钮
                    Button(action: {
                        showExitConfirm = true
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
                
                // 关闭按钮
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
            }
            .padding(30)
            .background(
                RoundedRectangle(cornerRadius: 25)
                    .fill(Color.black.opacity(0.9))
            )
            .padding(40)
            
            // 难度选择弹窗
            if showDifficultySelection {
                DifficultySelectionView(isPresented: $showDifficultySelection) { difficulty in
                    viewModel.restartGame()
                }
            }

            // 语言选择弹窗
            if showLanguageSelection {
                LanguageSelectionView(isPresented: $showLanguageSelection)
            }
        }
        .transition(.scale)
        // 退出确认弹窗
        .alert(localizationManager.localized("confirmations.exit_game"), isPresented: $showExitConfirm) {
            Button(localizationManager.localized("confirmations.cancel"), role: .cancel) { }
            Button(localizationManager.localized("confirmations.confirm_exit"), role: .destructive) {
                viewModel.exitToHome()
                isPresented = false
            }
        } message: {
            Text(localizationManager.localized("confirmations.exit_message"))
        }
    }
    
    private func getDifficultyName(_ difficulty: String) -> String {
        return localizationManager.getDifficultyName(difficulty)
    }
}

#Preview {
    GameSettingsView(
        viewModel: GameViewModel(),
        isPresented: .constant(true)
    )
}
