//
//  GameView.swift
//  A004
//
//  主游戏界面
//

import SwiftUI

struct GameView: View {
    @ObservedObject var viewModel: GameViewModel
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
            
            VStack(spacing: 12) {
                // 顶部信息栏（包含哥布林）
                TopInfoBar(viewModel: viewModel, showDifficultySelection: $showDifficultySelection)
                    .padding(.horizontal)
                    .padding(.top, 10)
                
                // 老虎机主体
                SlotMachineView(viewModel: viewModel)
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                
                // 控制按钮区域
                ControlPanel(viewModel: viewModel)
                    .padding(.horizontal)
                    .padding(.bottom, 8)
                
                Spacer(minLength: 0)
            }
            
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
            
            // 哥布林buff气泡提示
            if viewModel.showGoblinBuffTip, let goblin = viewModel.selectedGoblin {
                GoblinBuffTipView(goblin: goblin)
                    .transition(.scale.combined(with: .opacity))
            }
            
            // 符号buff气泡提示
            if viewModel.showSymbolBuffTip, let symbol = viewModel.selectedSymbolForTip {
                SymbolBuffTipView(symbol: symbol)
                    .id(symbol.id) // 使用符号ID作为视图ID，确保每次都是新的视图
                    .transition(.scale.combined(with: .opacity))
            }
            
            // 骰子动画
            if viewModel.showDiceAnimation {
                DiceAnimationView(diceResult: viewModel.diceResult)
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .animation(.spring(), value: viewModel.showSymbolSelection)
        .animation(.spring(), value: viewModel.showGameOver)
        .animation(.spring(), value: viewModel.showEarningsTip)
        .animation(.spring(), value: viewModel.showGoblinBuffTip)
        .animation(.spring(), value: viewModel.showSymbolBuffTip)
        .animation(.spring(), value: viewModel.showDiceAnimation)
    }
}

// MARK: - 顶部信息栏
struct TopInfoBar: View {
    @ObservedObject var viewModel: GameViewModel
    @Binding var showDifficultySelection: Bool
    
    var body: some View {
        VStack(spacing: 10) {
            // 第一行：哥布林、金币、回合
            HStack(spacing: 12) {
                // 哥布林显示（可点击）
                if let goblin = viewModel.selectedGoblin {
                    Button(action: {
                        viewModel.showGoblinBuffInfo()
                    }) {
                        HStack(spacing: 8) {
                            ZStack {
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            gradient: Gradient(colors: [
                                                Color.white.opacity(0.3),
                                                Color.white.opacity(0.1)
                                            ]),
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 50, height: 50)
                                
                                Text(goblin.icon)
                                    .font(.system(size: 30))
                            }
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(goblin.name)
                                    .font(.subheadline)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                
                                Text("点击查看")
                                    .font(.caption2)
                                    .foregroundColor(.white.opacity(0.6))
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.white.opacity(0.15))
                        )
                    }
                }
                
                Spacer()
                
                // 金币显示
                HStack(spacing: 6) {
                    Text("💰")
                        .font(.title3)
                    Text("\(viewModel.currentCoins)")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.yellow)
                }
                .padding(.horizontal, 15)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.black.opacity(0.3))
                )
                
                // 回合显示
                VStack(alignment: .trailing, spacing: 2) {
                    Text("回合 \(viewModel.currentRound)")
                        .font(.subheadline)
                        .fontWeight(.bold)
                    Text("剩余 \(viewModel.spinsRemaining)")
                        .font(.caption2)
                        .foregroundColor(.gray)
                }
                
                // 难度选择按钮
                Button(action: {
                    showDifficultySelection = true
                }) {
                    Image(systemName: "gear")
                        .font(.title3)
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
                    .font(.caption)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Text("\(viewModel.rentAmount) 金币")
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(viewModel.currentCoins >= viewModel.rentAmount ? .green : .red)
            }
            .padding(.horizontal, 15)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.15))
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
                    SlotCellView(cell: cell, isSpinning: viewModel.isSpinning, viewModel: viewModel)
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
    @ObservedObject var viewModel: GameViewModel
    
    @State private var rotation: Double = 0
    @State private var scale: CGFloat = 1.0
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: cell.isMined ? 
                            [Color.white.opacity(0.3), Color.white.opacity(0.1)] :
                            [Color.gray.opacity(0.6), Color.gray.opacity(0.4)]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(height: 60)
            
            // 未挖开：显示矿石
            if !cell.isMined {
                VStack(spacing: 2) {
                    Text("🪨")
                        .font(.system(size: 28))
                        .rotationEffect(.degrees(isSpinning ? rotation : 0))
                    
                    Text("矿石")
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.6))
                }
            }
            // 已挖开：显示符号或空格子
            else if let symbol = cell.symbol {
                VStack(spacing: 2) {
                    Text(symbol.icon)
                        .font(.system(size: 28))
                    
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
        .scaleEffect(scale)
        .onTapGesture {
            // 点击已挖开且有符号的格子，显示符号信息
            if cell.isMined, let symbol = cell.symbol {
                viewModel.showSymbolBuffInfo(for: symbol)
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
        .onChange(of: cell.isMined) { mined in
            if mined {
                // 挖开动画
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    scale = 1.2
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                        scale = 1.0
                    }
                }
            }
        }
    }
}

// MARK: - 控制面板
struct ControlPanel: View {
    @ObservedObject var viewModel: GameViewModel
    
    var body: some View {
        VStack(spacing: 10) {
            // 掷骰子按钮
            Button(action: {
                print("🔘 [UI] 玩家点击掷骰子按钮")
                viewModel.manualSpin()
            }) {
                HStack(spacing: 10) {
                    Text("🎲")
                        .font(.title2)
                    
                    VStack(alignment: .leading, spacing: 1) {
                        Text("掷骰子 (1-6)")
                            .font(.body)
                            .fontWeight(.bold)
                        
                        Text("剩余 \(viewModel.spinsRemaining) 次")
                            .font(.caption2)
                            .foregroundColor(.white.opacity(0.8))
                    }
                    
                    Spacer()
                    
                    Image(systemName: "arrow.right.circle.fill")
                        .font(.title3)
                }
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            viewModel.spinsRemaining > 0 && !viewModel.isSpinning && viewModel.gamePhase == .result ? Color.orange : Color.gray,
                            viewModel.spinsRemaining > 0 && !viewModel.isSpinning && viewModel.gamePhase == .result ? Color.red : Color.gray.opacity(0.5)
                        ]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(12)
                .shadow(color: .black.opacity(0.3), radius: 5, x: 0, y: 3)
                .opacity(viewModel.spinsRemaining > 0 && !viewModel.isSpinning && viewModel.gamePhase == .result ? 1.0 : 0.6)
            }
            .disabled(viewModel.spinsRemaining <= 0 || viewModel.isSpinning || viewModel.gamePhase != .result)
            
            // 符号池展示
            VStack(alignment: .leading, spacing: 8) {
                Text("我的符号池 (\(viewModel.symbolPool.count) 种)")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(viewModel.symbolPool) { symbol in
                            SymbolBadgeView(symbol: symbol, viewModel: viewModel)
                        }
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.15))
            )
        }
    }
}

// MARK: - 符号徽章视图
struct SymbolBadgeView: View {
    let symbol: Symbol
    @ObservedObject var viewModel: GameViewModel
    
    var body: some View {
        VStack(spacing: 3) {
            Text(symbol.icon)
                .font(.title3)
            
            Text(symbol.name)
                .font(.caption2)
                .foregroundColor(.white)
                .lineLimit(1)
            
            Text("\(symbol.baseValue)💰")
                .font(.caption2)
                .fontWeight(.bold)
                .foregroundColor(.yellow)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(symbol.rarity.color.opacity(0.3))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(symbol.rarity.color, lineWidth: 1.5)
                )
        )
        .onTapGesture {
            // 点击符号徽章，显示符号信息
            viewModel.showSymbolBuffInfo(for: symbol)
        }
    }
}

// MARK: - 符号选择视图
struct SymbolSelectionView: View {
    @ObservedObject var viewModel: GameViewModel
    
    var body: some View {
        VStack(spacing: 25) {
            Text(viewModel.currentRound == 1 && viewModel.symbolPool.count == 3 ? "🎯 选择你的第一个符号" : "🎯 选择一个符号加入符号池")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text(viewModel.currentRound == 1 && viewModel.symbolPool.count == 3 ? "选择符号开始你的第一回合" : "选择符号将增加它在老虎机中出现的概率")
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

// MARK: - 骰子动画视图
struct DiceAnimationView: View {
    let diceResult: Int
    @State private var rotation: Double = 0
    @State private var scale: CGFloat = 0.5
    @State private var opacity: Double = 0
    @State private var showResult: Bool = false
    
    var body: some View {
        VStack {
            Spacer()
            
            ZStack {
                // 旋转阶段：显示骰子图标
                if !showResult {
                    Text("🎲")
                        .font(.system(size: 100))
                        .rotationEffect(.degrees(rotation))
                        .scaleEffect(scale)
                        .opacity(opacity)
                }
                
                // 结果阶段：显示数字
                if showResult {
                    VStack(spacing: 10) {
                        Text("🎲")
                            .font(.system(size: 80))
                        
                        Text("\(diceResult)")
                            .font(.system(size: 80, weight: .bold))
                            .foregroundColor(.white)
                    }
                    .padding(40)
                    .background(
                        RoundedRectangle(cornerRadius: 30)
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color.orange.opacity(0.95),
                                        Color.red.opacity(0.9)
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .shadow(color: .black.opacity(0.5), radius: 20, x: 0, y: 10)
                    )
                    .scaleEffect(scale)
                    .opacity(opacity)
                }
            }
            
            Spacer()
        }
        .onAppear {
            // 第一阶段：旋转骰子（0.8秒）
            withAnimation(.easeIn(duration: 0.2)) {
                opacity = 1.0
                scale = 1.2
            }
            
            withAnimation(.linear(duration: 0.8).repeatCount(4, autoreverses: false)) {
                rotation = 360 * 4
            }
            
            // 第二阶段：显示结果（0.8秒后）
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                showResult = true
                
                // 弹出动画
                withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                    scale = 1.0
                }
            }
            
            // 第三阶段：淡出（1.0秒后开始淡出）
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                withAnimation(.easeOut(duration: 0.3)) {
                    opacity = 0
                    scale = 0.8
                }
            }
        }
        .allowsHitTesting(false) // 不阻挡其他UI交互
    }
}

// MARK: - 符号Buff气泡提示
struct SymbolBuffTipView: View {
    let symbol: Symbol
    @State private var offset: CGFloat = 30
    @State private var opacity: Double = 0
    @State private var scale: CGFloat = 0.8
    
    var body: some View {
        VStack {
            VStack(spacing: 12) {
                // 符号图标
                Text(symbol.icon)
                    .font(.system(size: 50))
                
                // 符号名称和金币值
                HStack(spacing: 8) {
                    Text(symbol.name)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text("\(symbol.baseValue)💰")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.yellow)
                }
                
                // 稀有度标签
                Text(symbol.rarity.rawValue)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(symbol.rarity.color.opacity(0.3))
                    )
                    .foregroundColor(symbol.rarity.color)
                
                // 类型标签
                if !symbol.types.isEmpty {
                    HStack(spacing: 6) {
                        ForEach(symbol.types, id: \.self) { type in
                            Text(type)
                                .font(.caption2)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(
                                    Capsule()
                                        .fill(Color.white.opacity(0.2))
                                )
                                .foregroundColor(.white.opacity(0.8))
                        }
                    }
                }
                
                // 效果描述
                if !symbol.description.isEmpty {
                    Divider()
                        .background(Color.white.opacity(0.3))
                    
                    HStack(spacing: 8) {
                        Text("✨")
                            .font(.body)
                        
                        Text(symbol.description)
                            .font(.body)
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.horizontal, 10)
                }
            }
            .padding(25)
            .background(
                RoundedRectangle(cornerRadius: 25)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                symbol.rarity.color.opacity(0.9),
                                symbol.rarity.color.opacity(0.7)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(color: .black.opacity(0.4), radius: 15, x: 0, y: 8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 25)
                            .stroke(Color.white.opacity(0.3), lineWidth: 2)
                    )
            )
            .padding(.horizontal, 30)
        }
        .offset(y: offset)
        .opacity(opacity)
        .scaleEffect(scale)
        .onAppear {
            // 入场动画
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
                }
            }
        }
        .allowsHitTesting(false) // 不阻挡其他UI交互
    }
}

// MARK: - 哥布林Buff气泡提示
struct GoblinBuffTipView: View {
    let goblin: Goblin
    @State private var offset: CGFloat = 30
    @State private var opacity: Double = 0
    @State private var scale: CGFloat = 0.8
    
    var body: some View {
        VStack {
            VStack(spacing: 12) {
                // 哥布林图标
                Text(goblin.icon)
                    .font(.system(size: 50))
                
                // 哥布林名称
                Text(goblin.name)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                // buff描述
                HStack(spacing: 8) {
                    Text("⭐")
                        .font(.body)
                    
                    Text(goblin.buff)
                        .font(.body)
                        .foregroundColor(.yellow)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.horizontal, 10)
            }
            .padding(25)
            .background(
                RoundedRectangle(cornerRadius: 25)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.purple.opacity(0.95),
                                Color.blue.opacity(0.9)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(color: .black.opacity(0.4), radius: 15, x: 0, y: 8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 25)
                            .stroke(Color.white.opacity(0.3), lineWidth: 2)
                    )
            )
            .padding(.horizontal, 30)
        }
        .offset(y: offset)
        .opacity(opacity)
        .scaleEffect(scale)
        .onAppear {
            // 入场动画
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
                }
            }
        }
        .allowsHitTesting(false) // 不阻挡其他UI交互
    }
}

#Preview {
    let viewModel = GameViewModel()
    viewModel.selectedGoblin = Goblin.allGoblins[0]
    viewModel.goblinSelectionCompleted = true
    return GameView(viewModel: viewModel)
}
