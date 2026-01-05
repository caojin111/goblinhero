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

                    // 音乐开关
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
                    
                    // 音效开关
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

                    // 图鉴按钮
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

                    // 测试按钮：添加测试符号
                    Button(action: {
                        viewModel.addTestSymbols()
                    }) {
                        HStack {
                            Image(systemName: "wrench.and.screwdriver.fill")
                                .font(.title2)
                                    .foregroundColor(.orange)

                            Text("测试：添加符号")
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
                                    .fill(Color.orange.opacity(0.2))
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    // 退出游戏按钮
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
                    
                    // 羁绊测试区域
                    VStack(alignment: .leading, spacing: 10) {
                        Text("羁绊测试")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .textStroke()
                            .padding(.horizontal)
                        
                        // 所有羁绊测试按钮
                        ForEach(BondBuffConfigManager.shared.getAllBondBuffs(), id: \.id) { bondBuff in
                            Button(action: {
                                viewModel.addSymbolsForBond(nameKey: bondBuff.nameKey)
                                isPresented = false
                            }) {
                                HStack {
                                    // 羁绊颜色指示器
                                    Circle()
                                        .fill(bondBuff.cardColor)
                                        .frame(width: 12, height: 12)
                                    
                                    VStack(alignment: .leading, spacing: 3) {
                                        Text(bondBuff.name)
                                            .font(.subheadline)
                                            .fontWeight(.semibold)
                                            .foregroundColor(.white)
                                            .textStroke()
                                        
                                        Text(bondBuff.description)
                                            .font(.caption)
                                            .foregroundColor(.white.opacity(0.7))
                                            .textStroke()
                                            .lineLimit(2)
                                    }
                                    
                                    Spacer()
                                    
                                    Image(systemName: "plus.circle.fill")
                                        .foregroundColor(.green)
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 10)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.white.opacity(0.1))
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(.top, 10)
                    }
                    .padding(.horizontal, 20)
                }
                .frame(maxHeight: UIScreen.main.bounds.height * 0.6)
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
