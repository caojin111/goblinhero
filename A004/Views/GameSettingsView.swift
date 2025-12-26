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
    @State private var showLanguageSelection = false
    @State private var showSymbolBook = false
    
    // 通用羁绊测试按钮
    private func BondTestButton(title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Image(systemName: "wand.and.stars")
                    .font(.title2)
                    .foregroundColor(.purple)
                
                Text(title)
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
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.purple.opacity(0.18))
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
                
                // 可滚动的内容区域
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

                        // 羁绊测试区域标题
                        Text("🧪 羁绊测试")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.purple)
                            .textStroke()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.top, 10)
                        
                        // 羁绊测试按钮（分组显示）
                        VStack(spacing: 10) {
                            // 类型羁绊组
                            Group {
                                BondTestButton(title: "human-3", action: { viewModel.addSymbolsForBond(nameKey: "human_3_bond") })
                                BondTestButton(title: "human-5", action: { viewModel.addSymbolsForBond(nameKey: "human_5_bond") })
                                BondTestButton(title: "human-10", action: { viewModel.addSymbolsForBond(nameKey: "human_10_bond") })
                                BondTestButton(title: "material-2", action: { viewModel.addSymbolsForBond(nameKey: "material_2_bond") })
                                BondTestButton(title: "material-4", action: { viewModel.addSymbolsForBond(nameKey: "material_4_bond") })
                                BondTestButton(title: "cozylife-3", action: { viewModel.addSymbolsForBond(nameKey: "cozylife_3_bond") })
                                BondTestButton(title: "cozylife-6", action: { viewModel.addSymbolsForBond(nameKey: "cozylife_6_bond") })
                                BondTestButton(title: "tools-2", action: { viewModel.addSymbolsForBond(nameKey: "tools_2_bond") })
                                BondTestButton(title: "tools-4", action: { viewModel.addSymbolsForBond(nameKey: "tools_4_bond") })
                                BondTestButton(title: "classictale-2", action: { viewModel.addSymbolsForBond(nameKey: "classictale_2_bond") })
                                BondTestButton(title: "classictale-4", action: { viewModel.addSymbolsForBond(nameKey: "classictale_4_bond") })
                                BondTestButton(title: "classictale-6", action: { viewModel.addSymbolsForBond(nameKey: "classictale_6_bond") })
                            }
                            
                            // 特殊羁绊组
                            Group {
                                BondTestButton(title: "merchant-trading", action: { viewModel.addSymbolsForBond(nameKey: "merchant_trading_bond") })
                                BondTestButton(title: "vampire-curse", action: { viewModel.addSymbolsForBond(nameKey: "vampire_curse_bond") })
                                BondTestButton(title: "death-blessing", action: { viewModel.addSymbolsForBond(nameKey: "death_blessing_bond") })
                                BondTestButton(title: "wolf-hunter", action: { viewModel.addSymbolsForBond(nameKey: "wolf_hunter_bond") })
                                BondTestButton(title: "element-master", action: { viewModel.addSymbolsForBond(nameKey: "element_master_bond") })
                                BondTestButton(title: "justice", action: { viewModel.addSymbolsForBond(nameKey: "justice_bond") })
                                BondTestButton(title: "apocalypse", action: { viewModel.addSymbolsForBond(nameKey: "apocalypse_bond") })
                                BondTestButton(title: "human-extinction", action: { viewModel.addSymbolsForBond(nameKey: "human_extinction_bond") })
                                BondTestButton(title: "raccoon-city", action: { viewModel.addSymbolsForBond(nameKey: "raccoon_city_bond") })
                            }
                        }
                        
                        // 测试功能：跳过所有关卡按钮
                    Button(action: {
                            viewModel.skipToLastRound()
                            isPresented = false
                    }) {
                        HStack {
                                Image(systemName: "forward.fill")
                                .font(.title2)
                                    .foregroundColor(.orange)

                            VStack(alignment: .leading, spacing: 5) {
                                    Text("🧪 跳过所有关卡")
                                    .font(.headline)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                    .textStroke()

                                    Text("测试用：直接跳到第30关")
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
                                    .fill(Color.orange.opacity(0.2))
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                        .padding(.top, 10)
                    
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
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                }
                
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
            .frame(maxHeight: UIScreen.main.bounds.height * 0.85)
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
