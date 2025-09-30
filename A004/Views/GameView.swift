//
//  GameView.swift
//  A004
//
//  主游戏界面
//

import SwiftUI

struct GameView: View {
    @StateObject private var viewModel = GameViewModel()
    @State private var showDifficultySelection = false
    
    var body: some View {
        ZStack {
            // 背景渐变
            LinearGradient(
                gradient: Gradient(colors: [Color.blue.opacity(0.3), Color.purple.opacity(0.3)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 20) {
                // 顶部信息栏
                TopInfoBar(viewModel: viewModel, showDifficultySelection: $showDifficultySelection)
                    .padding(.horizontal)
                
                // 老虎机主体
                SlotMachineView(viewModel: viewModel)
                    .padding()
                
                // 控制按钮区域
                ControlPanel(viewModel: viewModel)
                    .padding()
                
                Spacer()
            }
            .padding(.top, 20)
            
            // 符号选择弹窗
            if viewModel.showSymbolSelection {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                    .onTapGesture {
                        // 防止点击背景关闭
                    }
                
                SymbolSelectionView(viewModel: viewModel)
                    .transition(.scale)
            }
            
            // 游戏结束弹窗
            if viewModel.showGameOver {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                
                GameOverView(viewModel: viewModel)
                    .transition(.scale)
            }
            
            // 难度选择弹窗
            if showDifficultySelection {
                DifficultySelectionView(isPresented: $showDifficultySelection) { difficulty in
                    viewModel.restartGame()
                }
            }
            
            // 收益气泡提示
            if viewModel.showEarningsTip {
                EarningsTipView(text: viewModel.earningsTipText)
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .animation(.spring(), value: viewModel.showSymbolSelection)
        .animation(.spring(), value: viewModel.showGameOver)
        .animation(.spring(), value: viewModel.showEarningsTip)
    }
}

// MARK: - 顶部信息栏
struct TopInfoBar: View {
    @ObservedObject var viewModel: GameViewModel
    @Binding var showDifficultySelection: Bool
    
    var body: some View {
        VStack(spacing: 15) {
            // 第一行：金币和回合
            HStack {
                // 金币显示
                HStack(spacing: 8) {
                    Text("💰")
                        .font(.title2)
                    Text("\(viewModel.currentCoins)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.yellow)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 15)
                        .fill(Color.black.opacity(0.3))
                )
                
                Spacer()
                
                // 回合显示
                VStack(alignment: .trailing, spacing: 2) {
                    Text("回合 \(viewModel.currentRound)")
                        .font(.headline)
                        .fontWeight(.bold)
                    Text("剩余 \(viewModel.spinsRemaining) 次")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                // 难度选择按钮
                Button(action: {
                    showDifficultySelection = true
                }) {
                    Image(systemName: "gear")
                        .font(.title2)
                        .foregroundColor(.white)
                        .padding(8)
                        .background(
                            Circle()
                                .fill(Color.white.opacity(0.2))
                        )
                }
            }
            
            // 第二行：房租信息
            HStack {
                Text("🏠 房租")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Text("\(viewModel.rentAmount) 金币")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(viewModel.currentCoins >= viewModel.rentAmount ? .green : .red)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 15)
                    .fill(Color.white.opacity(0.2))
            )
        }
    }
}

// MARK: - 老虎机视图
struct SlotMachineView: View {
    @ObservedObject var viewModel: GameViewModel
    
    let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 5)
    
    var body: some View {
        VStack(spacing: 15) {
            // 老虎机格子
            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(viewModel.slotMachine) { cell in
                    SlotCellView(cell: cell, isSpinning: viewModel.isSpinning)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.white.opacity(0.15))
                    .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
            )
        }
    }
}

// MARK: - 老虎机格子视图
struct SlotCellView: View {
    let cell: SlotCell
    let isSpinning: Bool
    
    @State private var rotation: Double = 0
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [Color.white.opacity(0.3), Color.white.opacity(0.1)]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(height: 60)
            
            if let symbol = cell.symbol {
                VStack(spacing: 2) {
                    Text(symbol.icon)
                        .font(.system(size: 28))
                        .rotationEffect(.degrees(isSpinning ? rotation : 0))
                    
                    Text("\(symbol.baseValue)")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }
            } else {
                // 空格子显示
                VStack(spacing: 2) {
                    Text("⚪")
                        .font(.system(size: 20))
                        .foregroundColor(.white.opacity(0.3))
                    
                    Text("空")
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.4))
                }
            }
        }
        .onChange(of: isSpinning) { spinning in
            if spinning {
                withAnimation(.linear(duration: 0.5).repeatCount(2, autoreverses: false)) {
                    rotation = 360
                }
            } else {
                rotation = 0
            }
        }
    }
}

// MARK: - 控制面板
struct ControlPanel: View {
    @ObservedObject var viewModel: GameViewModel
    
    var body: some View {
        VStack(spacing: 15) {
            // 符号池展示
            VStack(alignment: .leading, spacing: 10) {
                Text("我的符号池 (\(viewModel.symbolPool.count) 种)")
                    .font(.headline)
                    .foregroundColor(.white)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(viewModel.symbolPool) { symbol in
                            SymbolBadgeView(symbol: symbol)
                        }
                    }
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 15)
                    .fill(Color.white.opacity(0.15))
            )
        }
    }
}

// MARK: - 符号徽章视图
struct SymbolBadgeView: View {
    let symbol: Symbol
    
    var body: some View {
        VStack(spacing: 5) {
            Text(symbol.icon)
                .font(.title2)
            
            Text(symbol.name)
                .font(.caption2)
                .foregroundColor(.white)
            
            Text("\(symbol.baseValue)💰")
                .font(.caption2)
                .fontWeight(.bold)
                .foregroundColor(.yellow)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(symbol.rarity.color.opacity(0.3))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(symbol.rarity.color, lineWidth: 2)
                )
        )
    }
}

// MARK: - 符号选择视图
struct SymbolSelectionView: View {
    @ObservedObject var viewModel: GameViewModel
    
    var body: some View {
        VStack(spacing: 25) {
            Text("🎯 选择一个符号加入符号池")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text("选择符号将增加它在老虎机中出现的概率")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.8))
            
            VStack(spacing: 15) {
                ForEach(viewModel.availableSymbols) { symbol in
                    Button(action: {
                        viewModel.selectSymbol(symbol)
                    }) {
                        HStack(spacing: 15) {
                            Text(symbol.icon)
                                .font(.system(size: 40))
                            
                            VStack(alignment: .leading, spacing: 5) {
                                HStack {
                                    Text(symbol.name)
                                        .font(.title3)
                                        .fontWeight(.bold)
                                    
                                    Text(symbol.rarity.rawValue)
                                        .font(.caption)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(symbol.rarity.color.opacity(0.3))
                                        .cornerRadius(8)
                                }
                                
                                Text(symbol.description)
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                
                                Text("💰 \(symbol.baseValue) 金币")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.yellow)
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .foregroundColor(.white.opacity(0.6))
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 15)
                                .fill(Color.white.opacity(0.2))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 15)
                                        .stroke(symbol.rarity.color, lineWidth: 2)
                                )
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
        .padding(30)
        .background(
            RoundedRectangle(cornerRadius: 25)
                .fill(Color.black.opacity(0.9))
        )
        .padding(40)
    }
}

// MARK: - 游戏结束视图
struct GameOverView: View {
    @ObservedObject var viewModel: GameViewModel
    
    var body: some View {
        VStack(spacing: 25) {
            Text("😢")
                .font(.system(size: 60))
            
            Text("游戏结束")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text(viewModel.gameOverMessage)
                .font(.body)
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.center)
            
            VStack(spacing: 10) {
                HStack {
                    Text("存活回合:")
                        .foregroundColor(.white.opacity(0.8))
                    Spacer()
                    Text("\(viewModel.currentRound)")
                        .fontWeight(.bold)
                        .foregroundColor(.yellow)
                }
                
                HStack {
                    Text("最终金币:")
                        .foregroundColor(.white.opacity(0.8))
                    Spacer()
                    Text("\(viewModel.currentCoins)")
                        .fontWeight(.bold)
                        .foregroundColor(.yellow)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.1))
            )
            
            Button(action: {
                viewModel.restartGame()
            }) {
                Text("再来一次！")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.blue, Color.purple]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(15)
            }
        }
        .padding(40)
        .background(
            RoundedRectangle(cornerRadius: 25)
                .fill(Color.black.opacity(0.95))
        )
        .padding(40)
    }
}

// MARK: - 收益气泡提示
struct EarningsTipView: View {
    let text: String
    @State private var offset: CGFloat = 30
    @State private var opacity: Double = 0
    @State private var scale: CGFloat = 0.8
    @State private var glowIntensity: Double = 0
    
    var body: some View {
        VStack {
            Spacer()
            
            ZStack {
                // 发光效果
                Text(text)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.clear)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 25)
                            .fill(Color.yellow.opacity(glowIntensity * 0.3))
                            .blur(radius: 8)
                    )
                
                // 主文本
                Text(text)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 25)
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color.green.opacity(0.95),
                                        Color.green.opacity(0.8),
                                        Color.green.opacity(0.7)
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .shadow(color: .black.opacity(0.4), radius: 12, x: 0, y: 6)
                            .overlay(
                                RoundedRectangle(cornerRadius: 25)
                                    .stroke(Color.white.opacity(0.3), lineWidth: 1)
                            )
                    )
            }
            .offset(y: offset)
            .opacity(opacity)
            .scaleEffect(scale)
            .onAppear {
                // 发光动画
                withAnimation(.easeInOut(duration: 0.3).repeatCount(3, autoreverses: true)) {
                    glowIntensity = 1.0
                }
                
                // 主动画
                withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                    offset = 0
                    opacity = 1
                    scale = 1.0
                }
                
                // 1.5秒后开始淡出
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    withAnimation(.easeOut(duration: 0.5)) {
                        offset = -20
                        opacity = 0
                        scale = 0.9
                        glowIntensity = 0
                    }
                }
            }
            
            Spacer()
        }
        .allowsHitTesting(false) // 不阻挡其他UI交互
    }
}

#Preview {
    GameView()
}
