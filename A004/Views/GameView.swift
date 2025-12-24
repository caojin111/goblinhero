//
//  GameView.swift
//  A004
//
//  主游戏界面
//

import SwiftUI
import AVFoundation

struct GameView: View {
    @ObservedObject var viewModel: GameViewModel
    @ObservedObject var localizationManager = LocalizationManager.shared
    @ObservedObject var audioManager = AudioManager.shared
    @State private var showSettings = false
    @State private var zoomScale: CGFloat = 1.0 // 缩放比例
    @State private var zoomOffset: CGSize = .zero // 缩放时的偏移量
    @State private var isLongPressing: Bool = false // 是否正在长按
    
    /// 播放点击音效
    private func playClickSound() {
        audioManager.playSoundEffect("click", fileExtension: "wav")
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // 纯黑色背景
                Color.black
                    .ignoresSafeArea(.all)
                
                VStack(spacing: 12) {
                    // 顶部占位（固定高度，避免影响布局）
                    // 使用固定高度的占位，实际UI通过overlay显示
                    Color.clear
                        .frame(height: 80) // 固定高度占位
                        .frame(maxWidth: .infinity)
                    
                    // 老虎机主体（独立布局，不受顶部UI缩放影响）
                    SlotMachineView(viewModel: viewModel)
                        .padding(.horizontal)
                        .padding(.vertical, 8)
                        .scaleEffect(zoomScale)
                        .offset(zoomOffset)
                        .animation(.easeInOut(duration: 0.3 / viewModel.settlementAnimationSpeed), value: zoomScale)
                        .animation(.easeInOut(duration: 0.3 / viewModel.settlementAnimationSpeed), value: zoomOffset)
                    
                    // 控制按钮区域（zoom in 时隐藏）
                    ControlPanel(viewModel: viewModel)
                        .padding(.horizontal)
                        .padding(.bottom, 8)
                        .opacity(zoomScale > 1.0 ? 0 : 1)
                        .animation(.easeInOut(duration: 0.3 / viewModel.settlementAnimationSpeed), value: zoomScale)
                    
                    // 使用固定布局，避免结算结束时界面跳动
                    Color.clear
                        .frame(height: 0)
                }
                .overlay(alignment: .top) {
                    // 顶部UI通过overlay显示，不影响主布局
                    TopInfoBar(viewModel: viewModel, showSettings: $showSettings)
                        .padding(.horizontal)
                        .padding(.top, 10)
                        .allowsHitTesting(true) // 确保可以交互
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
            
            // 设置弹窗
            if showSettings {
                GameSettingsView(
                    viewModel: viewModel,
                    isPresented: $showSettings
                )
            }
            
            // 收益气泡提示（使用overlay避免影响主布局）
            if viewModel.showEarningsTip {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        EarningsTipView(text: viewModel.earningsTipText, isDismissing: viewModel.isTipDismissing)
                            .transition(.scale.combined(with: .opacity))
                        Spacer()
                    }
                    Spacer()
                }
                .allowsHitTesting(false) // 不拦截点击事件
            }
            
            // 哥布林buff气泡提示
            if viewModel.showGoblinBuffTip, let goblin = viewModel.selectedGoblin {
                GoblinBuffTipView(goblin: goblin, isDismissing: viewModel.isTipDismissing)
                    .transition(.scale.combined(with: .opacity))
            }
            
            // 符号buff气泡提示（带背景遮罩，点击关闭）
            if viewModel.showSymbolBuffTip, let symbol = viewModel.selectedSymbolForTip {
                ZStack {
                    // 背景遮罩，点击后关闭弹窗
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                        .onTapGesture {
                            viewModel.dismissSymbolBuffTip()
                        }
                    
                    // 符号提示弹窗
                SymbolBuffTipView(symbol: symbol, isDismissing: viewModel.isTipDismissing)
                    .id(symbol.id) // 使用符号ID作为视图ID，确保每次都是新的视图
                    .transition(.scale.combined(with: .opacity))
                }
            }
            
            // 骰子动画
            if viewModel.showDiceAnimation {
                DiceAnimationView(diceResult: viewModel.diceResult, diceCount: viewModel.currentDiceCount, individualResults: viewModel.individualDiceResults)
                    .transition(.scale.combined(with: .opacity))
            }
            
            // 调试面板
            if viewModel.showDebugPanel {
                DebugPanelView(viewModel: viewModel)
                    .transition(.move(edge: .trailing))
                }
            
            // 羁绊详情弹窗（屏幕中间弹出）
            if viewModel.showBondDescription, let bondBuff = viewModel.selectedBondForDescription {
                ZStack {
                    // 背景遮罩，点击后关闭弹窗
                    Color.black.opacity(0.5)
                        .ignoresSafeArea()
                        .onTapGesture {
                            withAnimation {
                                viewModel.dismissBondDescriptionView()
                            }
                        }
                    
                    // 弹窗内容
                    BondDescriptionView(bondBuff: bondBuff, isPresented: $viewModel.showBondDescription, viewModel: viewModel)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            
            // 结算加速提示（在屏幕下方）
            if viewModel.currentSettlingCellIndex != nil && zoomScale > 1.0 {
                VStack {
                    Spacer()
                    Button(action: {
                        // 点击加速结算动画
                        if viewModel.settlementAnimationSpeed < 2.0 {
                            viewModel.settlementAnimationSpeed = 2.0
                            print("⚡ [加速] 点击加速提示，结算动画加速到2倍速")
                        }
                    }) {
                        Text(localizationManager.localized("game.tap_to_accelerate"))
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(
                                Capsule()
                                    .fill(Color.white.opacity(0.2))
                            )
                    }
                    .padding(.bottom, 50)
                }
            }
        }
        // 移除长按手势，改用点击加速按钮
        .onChange(of: viewModel.showEarningsTip) { isShowing in
            // 当金币弹窗出现时播放音效
            if isShowing {
                audioManager.playSoundEffect("coin", fileExtension: "wav")
            }
        }
        .onChange(of: viewModel.currentSettlingCellIndex) { cellIndex in
            // 当开始结算某个格子时，进行 zoom in
            if let index = cellIndex {
                performZoomIn(to: index, geometry: geometry)
            } else {
                // 结算完成，恢复原状
                performZoomOut()
            }
        }
            .animation(.spring(), value: viewModel.showSymbolSelection)
            .animation(.spring(), value: viewModel.showGameOver)
            // 移除收益气泡的全局动画，避免影响主布局
            // .animation(.spring(), value: viewModel.showEarningsTip)
            .animation(.spring(), value: viewModel.showGoblinBuffTip)
            .animation(.spring(), value: viewModel.showSymbolBuffTip)
            .animation(.spring(), value: viewModel.showDiceAnimation)
            .animation(.spring(), value: viewModel.showDebugPanel)
        }
        .onAppear {
            print("🎮 [GameView] 视图出现，准备播放背景音乐")
            // 播放游戏内背景音乐（增加延迟确保视图完全显示）
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                print("🎮 [GameView] 开始播放游戏背景音乐")
                audioManager.playBackgroundMusic(fileName: "game_bg", fileExtension: "wav")
            }
        }
        .onDisappear {
            print("🎮 [GameView] 视图消失")
            // 延迟停止音乐，给HomeView足够时间开始播放新音乐
            // 如果是返回首页，HomeView会在0.5秒后播放音乐，所以我们延迟更长时间再停止
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                // 检查是否已经返回首页（goblinSelectionCompleted为false表示已返回首页）
                if !viewModel.goblinSelectionCompleted {
                    print("🎮 [GameView] 已返回首页，不停止音乐，由HomeView处理")
                } else {
                    print("🎮 [GameView] 非返回首页场景，停止背景音乐")
                    audioManager.stopMusic()
                }
            }
        }
        .onChange(of: viewModel.goblinSelectionCompleted) { completed in
            // 当游戏开始时，确保播放背景音乐
            if completed {
                print("🎮 [GameView] 游戏开始（onChange），播放背景音乐")
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    audioManager.playBackgroundMusic(fileName: "game_bg", fileExtension: "wav")
                }
            }
        }
        .onChange(of: viewModel.showSymbolSelection) { isShowing in
            // 当符号选择界面关闭后，确保播放背景音乐
            if !isShowing && viewModel.goblinSelectionCompleted {
                print("🎮 [GameView] 符号选择界面关闭，确保播放背景音乐")
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    audioManager.playBackgroundMusic(fileName: "game_bg", fileExtension: "wav")
                }
            }
        }
    }
    
    /// 执行 zoom in 效果，聚焦到指定格子
    private func performZoomIn(to cellIndex: Int, geometry: GeometryProxy) {
        // 计算格子的位置（5x5网格）
        let row = cellIndex / 5
        let col = cellIndex % 5
        
        // 计算格子中心相对于老虎机视图的位置
        // 实际格子大小 60x60，间距 8，padding 16（来自 SlotMachineView）
        let cellSize: CGFloat = 60
        let spacing: CGFloat = 8
        let padding: CGFloat = 16
        
        // 计算格子中心在网格中的位置（相对于网格左上角）
        let cellCenterXInGrid = padding + CGFloat(col) * (cellSize + spacing) + cellSize / 2
        let cellCenterYInGrid = padding + CGFloat(row) * (cellSize + spacing) + cellSize / 2
        
        // 计算老虎机视图的中心位置（考虑 padding）
        let slotMachineWidth = geometry.size.width - 32 // 减去左右 padding (16 * 2)
        let slotMachineHeight = geometry.size.height - 200 // 减去顶部和底部空间
        let slotMachineCenterX = slotMachineWidth / 2 + 16 // 加上左边 padding
        let slotMachineCenterY = slotMachineHeight / 2 + 100 // 加上顶部空间
        
        // 计算需要偏移的距离，使格子居中到屏幕中心
        // 缩放后，偏移量需要按比例调整
        let scaleFactor: CGFloat = 1.5
        let offsetX = (slotMachineCenterX - cellCenterXInGrid) * (scaleFactor - 1.0)
        let offsetY = (slotMachineCenterY - cellCenterYInGrid) * (scaleFactor - 1.0)
        
        // 执行 zoom in 动画（放大1.5倍），根据速度倍数调整动画时长
        let animationDuration = 0.3 / viewModel.settlementAnimationSpeed
        withAnimation(.easeInOut(duration: animationDuration)) {
            zoomScale = scaleFactor
            zoomOffset = CGSize(width: offsetX, height: offsetY)
        }
        
        print("🔍 [Zoom In] 聚焦到格子\(cellIndex) (行\(row), 列\(col))，缩放: \(zoomScale)，偏移: \(zoomOffset)，隐藏符号池和 roll 按钮，速度倍数: \(viewModel.settlementAnimationSpeed)")
    }
    
    /// 执行 zoom out 效果，恢复原状
    private func performZoomOut() {
        // 恢复缩放和偏移，根据速度倍数调整动画时长
        let animationDuration = 0.3 / viewModel.settlementAnimationSpeed
        withAnimation(.easeInOut(duration: animationDuration)) {
            zoomScale = 1.0
            zoomOffset = .zero
        }
        
        // 重置长按状态和速度倍数
        isLongPressing = false
        viewModel.settlementAnimationSpeed = 1.0
        
        print("🔍 [Zoom Out] 恢复原状，显示符号池和 roll 按钮")
    }
}

// MARK: - 顶部信息栏
struct TopInfoBar: View {
    @ObservedObject var viewModel: GameViewModel
    @ObservedObject var localizationManager = LocalizationManager.shared
    @ObservedObject var audioManager = AudioManager.shared
    @Binding var showSettings: Bool
    
    // 获取哥布林对应的头像图片名称
    private func getGoblinAvatarName(for goblin: Goblin) -> String? {
        switch goblin.nameKey {
        case "warrior_goblin":
            return "avatar_bravegoblin"
        case "king_goblin":
            return "avatar_kinggoblin"
        case "wizard_goblin":
            return "avatar_wizardgoblin"
        default:
            return nil
        }
    }
    
    var body: some View {
        VStack(spacing: 10) {
            // 第一行：哥布林、金币、回合
            HStack(spacing: 12) {
                // 哥布林显示（可点击）- 使用头像+头像框
                if let goblin = viewModel.selectedGoblin {
                    Button(action: {
                        audioManager.playSoundEffect("click", fileExtension: "wav")
                        print("🎭 [游戏界面] 点击哥布林头像")
                        viewModel.showGoblinBuffInfo()
                    }) {
                        ZStack {
                            // 如果有对应的头像图片，显示头像+头像框
                            if let avatarName = getGoblinAvatarName(for: goblin) {
                                // 头像图片（放大1.5倍）
                                Image(avatarName)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 75, height: 75)
                                
                                // 头像框（放大1.5倍，覆盖背景）
                                Image("avatar_frame")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 105, height: 105)
                            } else {
                                // 没有头像图片的哥布林，使用原来的emoji显示
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
                            }
                        }
                        .offset(x: 0) // 左移30像素（30 - 30 = 0）
                    }
                }
                
                Spacer()
                
                // 金币+关卡进度条（使用coin_bar背景，放大1.5倍）
                ZStack {
                    // coin_bar背景图（不动）
                    Image("coin_bar")
                        .resizable()
                        .scaledToFit()
                        .scaleEffect(1.04) // 整体放大1.04倍（1.25 / 1.2 = 1.04167）
                    
                    // 内容元素（右移40像素）
                    HStack(spacing: 24) { // spacing也放大1.5倍：16 * 1.5 = 24
                        // 金币显示（图标在黑底上层）
                        ZStack(alignment: .leading) {
                            // 金币数文字（带灰色底板）- 作为底层
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color.black.opacity(0.4))
                                .frame(height: 30)
                                .frame(minWidth: 60 * 1.2) // 横向拉长1.2倍
                                .overlay(
                                    CoinAmountView(amount: viewModel.currentCoins)
                                        .padding(.horizontal, 9)
                                        .padding(.vertical, 3)
                                )
                                .offset(x: -50) // 左移20像素（-30 - 20 = -50）
                            
                            // 金币图标 - 在上层
                            Image("coin_icon")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 36, height: 36) // 24 * 1.5 = 36
                                .offset(x: -75) // 向左移动，确保在左侧（-65 - 10 = -75）
                                .zIndex(1) // 确保在上层
                        }
                        .offset(x: 10) // 向右移动10像素
                        
                        // 关卡显示（图标在黑底上层）
                        ZStack(alignment: .leading) {
                            // 关卡进度文字（带灰色底板）- 作为底层
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color.black.opacity(0.4))
                                .frame(height: 30)
                                .frame(minWidth: 60 * 1.2 + 10) // 横向拉长1.2倍，再往左拉长10像素
                                .overlay(
                                    Text("\(viewModel.currentRound)-\(viewModel.currentSpinInRound)")
                                        .font(.system(size: 20, weight: .bold))
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 9)
                                        .padding(.vertical, 3)
                                        .contentTransition(.numericText())
                                        .animation(.easeInOut(duration: 0.3), value: viewModel.currentRound)
                                        .animation(.easeInOut(duration: 0.3), value: viewModel.currentSpinInRound)
                                )
                                .offset(x: -50) // 左移20像素（-30 - 20 = -50）
                            
                            // 关卡图标 - 在上层
                            Image("pickaxe_icon")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 36, height: 36) // 24 * 1.5 = 36
                                .offset(x: -65) // 向左移动，确保在左侧（-50 - 15 = -65）
                                .zIndex(1) // 确保在上层
                        }
                        .offset(x: 15) // 整体向右移动15像素
                    }
                    .padding(.horizontal, 18) // 12 * 1.5 = 18
                    .padding(.vertical, 12) // 8 * 1.5 = 12
                    .offset(x: 40) // 右移40像素
                }
                .offset(x: -20, y: -20) // 向右移动10像素，单独向上移动10像素
                .zIndex(5)
                
                // 右侧按钮组（垂直排列）
                VStack(alignment: .trailing, spacing: 4) {
                    // 设置按钮（使用settings图片）
                    Button(action: {
                        audioManager.playSoundEffect("click", fileExtension: "wav")
                        print("⚙️ [游戏界面] 点击设置按钮")
                        showSettings = true
                    }) {
                        Image("settings")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 32, height: 32)
                            .scaleEffect(1.2) // 放大1.2倍
                    }
                    .offset(x: -10, y: 0) // 右移20像素（-30 + 20 = -10）
                    
                    // 调试按钮组（透明+日志）
                    HStack(spacing: 6) {
                        // 透明模式按钮
                        Button(action: {
                            audioManager.playSoundEffect("click", fileExtension: "wav")
                            viewModel.toggleTransparentMode()
                        }) {
                            Image(systemName: viewModel.transparentMode ? "eye.fill" : "eye.slash.fill")
                                .font(.caption)
                                .foregroundColor(.white)
                                .padding(6)
                                .background(
                                    Circle()
                                        .fill(viewModel.transparentMode ? Color.green.opacity(0.3) : Color.white.opacity(0.2))
                                )
                        }
                        
                        // 日志按钮
                        Button(action: {
                            audioManager.playSoundEffect("click", fileExtension: "wav")
                            viewModel.toggleDebugPanel()
                        }) {
                            Image(systemName: "doc.text.fill")
                                .font(.caption)
                                .foregroundColor(.white)
                                .padding(6)
                                .background(
                                    Circle()
                                        .fill(viewModel.showDebugPanel ? Color.blue.opacity(0.3) : Color.white.opacity(0.2))
                                )
                        }
                    }
                }
                .offset(x: -40) // 向左移动40像素
            }
            
            // 第二行：next rent 字样展示（包含租金数字，宽度为一半，x坐标与金币进度条一致，紧贴下方）
            HStack {
                Text(localizationManager.localized("game.next_goal"))
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.white.opacity(0.8))
                
                Spacer()
                
                // 租金数字显示在右侧（使用富文本，颜色和金币数量一样）
                Text("\(viewModel.rentAmount)")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.yellow) // 和金币数量一样的颜色
            }
            .padding(.horizontal, 15)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.15))
            )
            .frame(width: UIScreen.main.bounds.width * 0.5 - 15) // 宽度缩短至一半，再变窄15像素
            .offset(x: 5, y: -50) // 向右移动15像素（-10 + 15 = 5），向上移动30像素（-20 - 30 = -50）
        }
        .offset(x: 20, y: -15) // 整体上移20像素（-10 - 20 = -30）
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
                ForEach(Array(viewModel.slotMachine.enumerated()), id: \.element.id) { index, cell in
                    SlotCellView(cell: cell, cellIndex: index, isSpinning: viewModel.isSpinning, viewModel: viewModel)
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
    let cellIndex: Int
    let isSpinning: Bool
    @ObservedObject var viewModel: GameViewModel
    @ObservedObject var localizationManager = LocalizationManager.shared
    
    @State private var rotation: Double = 0
    @State private var scale: CGFloat = 1.0
    @State private var settlingScale: CGFloat = 1.0
    @State private var glowOpacity: Double = 0.0
    @State private var shakeOffset: CGSize = .zero // 抖动偏移量
    @State private var showExplosion: Bool = false // 是否显示爆炸动画
    @State private var showContent: Bool = false // 是否显示内容（爆炸动画完成后）
    
    // 检测当前格子是否正在结算
    private var isSettling: Bool {
        viewModel.currentSettlingCellIndex == cellIndex
    }
    
    var body: some View {
        ZStack {
            // 未挖开：显示矿石（使用包含背景的完整图片）
            if !cell.isMined {
                ZStack {
                    // 矿石图标（包含背景）
                    Image("mine_icon")
                        .resizable()
                        .scaledToFill()
                        .frame(height: 60)
                        .clipped()
                        .opacity(viewModel.transparentMode ? 0.3 : 1.0)
                    
                    // 透明模式下显示下面的符号数值
                    if viewModel.transparentMode, let symbol = cell.symbol {
                        Text("\(symbol.baseValue)")
                            .font(.caption2)
                            .foregroundColor(.yellow.opacity(0.5))
                    }
                }
                .zIndex(1) // 未挖开的图标在底层
            } else {
                // 爆炸动画（在显示内容之前播放）
                if showExplosion {
                    MineExplosionAnimationView(onComplete: {
                        // 爆炸动画完成后，显示内容
                        showContent = true
                        showExplosion = false
                    })
                    .frame(width: 60, height: 60)
                }
                
                // 已挖开的内容（爆炸动画完成后显示）
                if showContent {
                    // 已挖开：显示符号或空格子
                    if let symbol = cell.symbol {
                        // 有符号：显示原来的背景 + 符号内容
                        ZStack {
                // 已挖开：显示原来的背景
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: 
                                [Color.white.opacity(0.3), Color.white.opacity(0.1)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                                .frame(width: 60 - 5, height: 60 - 5) // 挖出后的格子长和宽统一-5像素
                
                    VStack(spacing: 2) {
                                // 根据icon类型显示：图片资源或emoji文本
                                if symbol.isImageResource {
                                    Image(symbol.imageName)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 28, height: 28)
                                        .onAppear {
                                            print("🖼️ [显示图片] 加载图片资源: \(symbol.imageName) (来自icon: \(symbol.icon))")
                                        }
                                } else {
                        Text(symbol.icon)
                            .font(.system(size: 28))
                                }
                        
                        Text("\(symbol.baseValue)")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            }
                    }
                } else {
                        // 空格子：只显示 no_symbol.png 图片，不显示背景和文字
                        Image("no_symbol")
                            .resizable()
                            .scaledToFit()
                            .frame(width: (60 - 5) / 1.2, height: (60 - 5) / 1.2) // 挖出后的格子长和宽统一-5像素，再缩小1.2倍
                    }
                }
            }
            
            // 特殊格图标（classic tale 2 特殊格子标记）- 只在未挖开时显示
            if cell.isSpecial && !cell.isMined {
                Image("special_mine_icon")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 60, height: 60)
                    .zIndex(5) // 确保在符号之上但在金币数字之下
            }
            
            // 金币数字放在最上层，确保盖在未挖出的矿格之上
            if isSettling {
                CoinFloatView(earnings: viewModel.currentSettlingCellEarnings)
                    .zIndex(10) // 提高zIndex，确保在最上层
            }
        }
        .scaleEffect(scale * settlingScale * 1.2) // 整体放大1.1倍
        .rotationEffect(.degrees(isSettling ? sin(rotation / 10) * 3 : 0)) // 结算时轻微摇摆
        .offset(shakeOffset) // 抖动偏移
        .onTapGesture {
            // 点击已挖开且有符号的格子，显示符号信息
            if cell.isMined, let symbol = cell.symbol {
                viewModel.showSymbolBuffInfo(for: symbol)
            }
        }
        .onChange(of: isSpinning) { spinning in
            // 移除掷骰子时的旋转动画
                rotation = 0
        }
        .onChange(of: cell.isMined) { mined in
            if mined {
                // 挖开动画：先播放爆炸动画，再显示内容
                print("💥 [挖矿动画] 格子\(cellIndex)开始爆炸动画")
                
                // 重置状态
                showContent = false
                showExplosion = true
                
                // 创建抖动动画序列（与爆炸动画同时进行）
                let shakeDuration: TimeInterval = 0.15
                let shakeIntensity: CGFloat = 8.0 // 抖动强度
                
                // 第一下抖动：向右上
                withAnimation(.easeOut(duration: shakeDuration * 0.3)) {
                    shakeOffset = CGSize(width: shakeIntensity, height: -shakeIntensity)
                }
                
                // 第二下抖动：向左下
                DispatchQueue.main.asyncAfter(deadline: .now() + shakeDuration * 0.3) {
                    withAnimation(.easeOut(duration: shakeDuration * 0.3)) {
                        shakeOffset = CGSize(width: -shakeIntensity, height: shakeIntensity)
                    }
                }
                
                // 第三下抖动：向右下
                DispatchQueue.main.asyncAfter(deadline: .now() + shakeDuration * 0.6) {
                    withAnimation(.easeOut(duration: shakeDuration * 0.3)) {
                        shakeOffset = CGSize(width: shakeIntensity * 0.6, height: shakeIntensity * 0.6)
                    }
                }
                
                // 第四下抖动：向左上
                DispatchQueue.main.asyncAfter(deadline: .now() + shakeDuration * 0.9) {
                    withAnimation(.easeOut(duration: shakeDuration * 0.3)) {
                        shakeOffset = CGSize(width: -shakeIntensity * 0.4, height: -shakeIntensity * 0.4)
                    }
                }
                
                // 恢复原位
                DispatchQueue.main.asyncAfter(deadline: .now() + shakeDuration) {
                    withAnimation(.spring(response: 0.2, dampingFraction: 0.7)) {
                        shakeOffset = .zero
                    }
                }
            } else {
                // 重置状态
                shakeOffset = .zero
                showExplosion = false
                showContent = false
            }
        }
        .onChange(of: isSettling) { settling in
            if settling {
                // 播放符号加金币音效
                AudioManager.shared.playSoundEffect("score", fileExtension: "wav")
                
                // 开始结算动画：放大+振动+发光
                print("✨ [结算动画] 格子\(cellIndex)开始结算动画")
                
                // 发光脉冲（根据速度倍数调整）
                let glowDuration = 0.25 / viewModel.settlementAnimationSpeed
                withAnimation(.easeInOut(duration: glowDuration).repeatCount(2, autoreverses: true)) {
                    glowOpacity = 0.8
                }
                
                // 振动+放大（根据速度倍数调整）
                let springResponse = 0.2 / viewModel.settlementAnimationSpeed
                withAnimation(.spring(response: springResponse, dampingFraction: 0.3)) {
                    settlingScale = 1.3
                    rotation = 360
                }
                
                // 恢复（根据速度倍数调整延迟和动画时长）
                let recoveryDelay = 0.4 / viewModel.settlementAnimationSpeed
                let recoveryResponse = 0.3 / viewModel.settlementAnimationSpeed
                DispatchQueue.main.asyncAfter(deadline: .now() + recoveryDelay) {
                    withAnimation(.spring(response: recoveryResponse, dampingFraction: 0.6)) {
                        settlingScale = 1.0
                        glowOpacity = 0.0
                    }
                }
            }
        }
    }
}

// MARK: - 控制面板
struct ControlPanel: View {
    @ObservedObject var viewModel: GameViewModel
    @ObservedObject var localizationManager = LocalizationManager.shared
    
    // 获取自定义字体
    private func customFont(size: CGFloat) -> Font {
        return FontManager.shared.customFont(size: size)
    }
    
    var body: some View {
        VStack(spacing: 10) {
            // 符号池展示（移到上方）
            VStack(alignment: .leading, spacing: 8) {
                Text(localizationManager.localized("game.my_symbol_pool").replacingOccurrences(of: "{count}", with: "\(viewModel.symbolPool.count)"))
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
            
            // 羁绊展示区域
            ActiveBondsView(viewModel: viewModel)
            
            // 间距：羁绊区域和ROLL按钮之间只隔15像素
            Spacer()
                .frame(height: 15)
            
            // 掷骰子按钮（移到下方）
            VStack(spacing: 8) {
                Button(action: {
                    print("🔘 [UI] 玩家点击掷骰子按钮")
                    viewModel.manualSpin()
                }) {
                    // 使用roll_icon作为按钮，ROLL文字叠加在上面
                    ZStack {
                        Image("roll_icon")
                            .resizable()
                            .scaledToFit()
                            .frame(height: 40)
                        
                        // "ROLL"文案叠加在按钮上
                        Text(localizationManager.localized("game.roll"))
                            .font(customFont(size: 20))
                            .foregroundColor(.white)
                            .offset(y: -5) // 向上移动10像素
                    }
                    .scaleEffect(1.5) // 放大1.5倍
                    .opacity(viewModel.spinsRemaining > 0 && !viewModel.isSpinning && viewModel.gamePhase == .result ? 1.0 : 0.6)
                }
                .disabled(viewModel.spinsRemaining <= 0 || viewModel.isSpinning || viewModel.gamePhase != .result)
                
                // 按钮下方：骰子图标和数量展示
                HStack(spacing: 4) {
                    Image("dice_icon")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 20, height: 20)
                    
                    DiceCountAnimationView(diceCount: viewModel.currentDiceCount)
                }
            }
            .offset(y: viewModel.activeBonds.isEmpty ? 20 : -20) // 没有触发羁绊的情况下，整体向下移动20像素；有羁绊时向上移动20像素
        }
    }
}

// MARK: - 激活羁绊展示视图
struct ActiveBondsView: View {
    @ObservedObject var viewModel: GameViewModel
    @ObservedObject var localizationManager = LocalizationManager.shared
    
    // 获取自定义字体
    private func customFont(size: CGFloat) -> Font {
        return FontManager.shared.customFont(size: size)
    }
    
    var body: some View {
        let activeBonds = viewModel.activeBonds
        
        // 打印日志，方便追踪
        let _ = print("🔗 [羁绊系统] 当前激活的羁绊数量: \(activeBonds.count)")
        
        if !activeBonds.isEmpty {
            VStack(alignment: .leading, spacing: 6) {
                // 标题
                Text(localizationManager.localized("game.active_bonds"))
                    .font(customFont(size: 14))
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                // 羁绊卡片列表
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(activeBonds) { bondBuff in
                            BondCardView(bondBuff: bondBuff, viewModel: viewModel)
                        }
                    }
                    .padding(.horizontal, 4)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 7) // 从10减少到7（减少约1/3）
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.1))
            )
        }
    }
}

// MARK: - 羁绊卡片视图
struct BondCardView: View {
    let bondBuff: BondBuff
    @ObservedObject var viewModel: GameViewModel
    @ObservedObject var localizationManager = LocalizationManager.shared
    
    // 获取自定义字体
    private func customFont(size: CGFloat) -> Font {
        return FontManager.shared.customFont(size: size)
    }
    
    private var isFlashing: Bool {
        viewModel.flashingBondIDs.contains(bondBuff.id)
    }
    
    var body: some View {
        Button(action: {
            // 注意：羁绊卡片点击不播放 click 音效，因为用户要求只有 start 按钮外的其他按钮才播放
            // 但根据需求，应该是"除了start按钮，其他所有地方的点击音效"，所以这里也播放
            AudioManager.shared.playSoundEffect("click", fileExtension: "wav")
            viewModel.showBondDescriptionView(bondBuff: bondBuff)
        }) {
            // 只显示羁绊名称
            Text(bondBuff.name)
                .font(customFont(size: localizationManager.currentLanguage == "zh" ? 19 : 24)) // 中文19号，英文24号（增加5号）
                .fontWeight(.bold)
                .foregroundColor(.white)
                .textStroke() // 添加黑色描边
                .lineLimit(1)
                .frame(width: 140, height: 45) // 从60减少到45（减少1/4）
        .padding(.horizontal, 10)
                .padding(.vertical, 6) // 从8减少到6，保持比例
        .background(
            RoundedRectangle(cornerRadius: 10)
                        .fill(bondBuff.cardColor.opacity(0.8))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                )
        )
        }
        .shadow(color: Color.yellow.opacity(isFlashing ? 0.9 : 0.0), radius: isFlashing ? 10 : 0, x: 0, y: 0)
        .animation(.easeInOut(duration: 0.4), value: isFlashing)
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - 羁绊描述弹框视图
struct BondDescriptionView: View {
    let bondBuff: BondBuff
    @Binding var isPresented: Bool
    @ObservedObject var localizationManager = LocalizationManager.shared
    var viewModel: GameViewModel? = nil // 可选，用于通过 viewModel 关闭弹窗
    
    // 获取自定义字体
    private func customFont(size: CGFloat) -> Font {
        return FontManager.shared.customFont(size: size)
    }
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 20) {
                // 标题
                Text(bondBuff.name)
                    .font(customFont(size: 29)) // 从24增大5号到29
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .textStroke() // 黑色描边（已存在，确保保留）
                    .padding(.top, 20)
                
                // 描述内容（自适应高度，不使用ScrollView）
                Text(bondBuff.description)
                    .font(customFont(size: 21)) // 从16增大5号到21
                    .foregroundColor(.white.opacity(0.9))
                    .multilineTextAlignment(.leading)
                    .lineSpacing(8)
                    .padding(.horizontal, 30)
                    .fixedSize(horizontal: false, vertical: true)
                
                // 关闭按钮
                Button(action: {
                    withAnimation {
                        if let viewModel = viewModel {
                            viewModel.dismissBondDescriptionView()
                        } else {
                            isPresented = false
                        }
                    }
                }) {
                    Text(localizationManager.localized("settings.close"))
                        .font(customFont(size: 18))
                        .foregroundColor(.white)
                        .textStroke()
                        .padding(.horizontal, 40)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(bondBuff.cardColor.opacity(0.8))
                        )
                }
                .padding(.bottom, 30)
            }
            .frame(width: min(geometry.size.width * 0.85, 400)) // 弹窗宽度为屏幕宽度的85%，最大400
            .background(
                RoundedRectangle(cornerRadius: 25)
                    .fill(Color.black.opacity(0.9))
                    .shadow(color: .black.opacity(0.5), radius: 20, x: 0, y: 10)
            )
            .position(x: geometry.size.width / 2, y: geometry.size.height / 2) // 居中显示
        }
    }
}

// MARK: - 符号徽章视图
struct SymbolBadgeView: View {
    let symbol: Symbol
    @ObservedObject var viewModel: GameViewModel
    
    private var isFlashing: Bool {
        viewModel.flashingSymbolIDs.contains(symbol.id)
    }
    
    var body: some View {
        VStack(spacing: 3) {
            // 根据icon类型显示：图片资源或emoji文本
            if symbol.isImageResource {
                Image(symbol.imageName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 24, height: 24)
            } else {
            Text(symbol.icon)
                .font(.title3)
            }
            
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
        .shadow(color: Color.yellow.opacity(isFlashing ? 0.9 : 0.0), radius: isFlashing ? 10 : 0, x: 0, y: 0)
        .animation(.easeInOut(duration: 0.4), value: isFlashing)
        .onTapGesture {
            // 点击符号徽章，显示符号信息
            viewModel.showSymbolBuffInfo(for: symbol)
        }
    }
}

// MARK: - 符号选择视图
struct SymbolSelectionView: View {
    @ObservedObject var viewModel: GameViewModel
    @ObservedObject var localizationManager = LocalizationManager.shared
    @ObservedObject var audioManager = AudioManager.shared
    
    // 获取type的多语言名称
    private func getTypeLocalizedName(_ type: String) -> String {
        // 构建多语言key（先尝试原始大小写）
        var key = "symbol_type.\(type)"
        var localized = localizationManager.localized(key)
        
        // 如果返回的文本和key不同，说明找到了翻译
        if localized != key {
            return localized
        }
        
        // 如果没找到，尝试小写版本（处理 Extinction -> extinction）
        let lowercasedType = type.lowercased()
        if lowercasedType != type {
            key = "symbol_type.\(lowercasedType)"
            localized = localizationManager.localized(key)
            if localized != key {
                return localized
            }
        }
        
        // 如果还是没找到，返回首字母大写的原始文本
        return type.capitalized
    }
    
    var body: some View {
        GeometryReader { geometry in
            ScrollView {
        VStack(spacing: 25) {
            Text(viewModel.currentRound == 1 && viewModel.symbolPool.count == 3 ?
                 localizationManager.localized("game.select_first_symbol") :
                 localizationManager.localized("game.select_symbol"))
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text(viewModel.currentRound == 1 && viewModel.symbolPool.count == 3 ?
                 localizationManager.localized("game.first_round_hint") :
                 localizationManager.localized("game.symbol_hint"))
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.8))
            
            VStack(spacing: 15) {
                ForEach(viewModel.availableSymbols) { symbol in
                    Button(action: {
                                audioManager.playSoundEffect("click", fileExtension: "wav")
                        viewModel.selectSymbol(symbol)
                    }) {
                                HStack(alignment: .top, spacing: 15) {
                                    // Icon和Type区域（垂直排列）
                                    VStack(spacing: 8) {
                                        // 根据icon类型显示：图片资源或emoji文本
                                        if symbol.isImageResource {
                                            Image(symbol.imageName)
                                                .resizable()
                                                .scaledToFit()
                                                .frame(width: 40, height: 40)
                                        } else {
                                            Text(symbol.icon)
                                                .font(.system(size: 40))
                                        }
                                        
                                        // Type标签（支持多行）
                                        if !symbol.types.isEmpty {
                                            VStack(spacing: 4) {
                                                ForEach(symbol.types, id: \.self) { type in
                                                    Text(getTypeLocalizedName(type))
                                                        .font(.caption2)
                                                        .foregroundColor(.white.opacity(0.8))
                                                        .padding(.horizontal, 6)
                                                        .padding(.vertical, 2)
                                                        .background(
                                                            Capsule()
                                                                .fill(Color.white.opacity(0.2))
                                                        )
                                                }
                                            }
                                        }
                                    }
                            
                            VStack(alignment: .leading, spacing: 5) {
                                        HStack(spacing: 8) {
                                    Text(symbol.name)
                                                .font(.system(size: 13)) // 从.title3（约17pt）减小5号，约12pt，使用13pt更合适
                                        .fontWeight(.bold)
                                                .lineLimit(1) // 单行显示，不换行
                                    
                                    Text(symbol.rarity.displayName)
                                        .font(.caption)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(symbol.rarity.color.opacity(0.3))
                                        .cornerRadius(8)
                                }
                                
                                RichTextView(symbol.description, defaultColor: .gray, font: .caption)
                                            .fixedSize(horizontal: false, vertical: true) // 垂直方向自适应，不限制行数
                                            .lineSpacing(2) // 增加行间距，提高可读性
                                
                                Text(localizationManager.localized("game.symbol_value").replacingOccurrences(of: "{value}", with: "\(symbol.baseValue)"))
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.yellow)
                                            .lineLimit(1) // 单行显示
                                    }
                                    .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading) // 允许VStack向右扩展，最小宽度为0
                        }
                                .padding(.horizontal) // 水平方向padding，文本区域向右扩展接近框体边缘
                                .padding(.vertical)
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
            }
            .frame(maxHeight: geometry.size.height * 0.9) // 最大高度不超过屏幕的90%
        .padding(40)
        }
    }
}

// MARK: - 游戏结束视图
struct GameOverView: View {
    @ObservedObject var viewModel: GameViewModel
    @ObservedObject var localizationManager = LocalizationManager.shared
    @ObservedObject var audioManager = AudioManager.shared
    
    // 判断是否是胜利（通过检查消息是否包含胜利消息的关键词）
    private var isVictory: Bool {
        let message = viewModel.gameOverMessage
        let victoryMessage = localizationManager.localized("game_over.victory_message")
        // 如果消息与胜利消息匹配，或者包含胜利关键词
        return message == victoryMessage || 
               message.contains("恭喜") || 
               message.contains("完成") || 
               message.contains("Congratulations") || 
               message.contains("completed") ||
               message.contains("successfully")
    }
    
    var body: some View {
        VStack(spacing: 25) {
            Text(isVictory ? localizationManager.localized("game_over.you_win") : localizationManager.localized("game_over.title"))
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text(viewModel.gameOverMessage)
                .font(.body)
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.center)
            
            VStack(spacing: 10) {
                HStack {
                    Text(localizationManager.localized("game_over.survival_rounds"))
                        .foregroundColor(.white.opacity(0.8))
                        .font(.subheadline)
                    Spacer()
                    Text("\(viewModel.currentRound)")
                        .font(.body)
                        .fontWeight(.bold)
                        .foregroundColor(.yellow)
                }
                
                HStack {
                    Text(localizationManager.localized("game_over.final_coins"))
                        .foregroundColor(.white.opacity(0.8))
                        .font(.subheadline)
                    Spacer()
                    Text("\(viewModel.currentCoins)")
                        .font(.body)
                        .fontWeight(.bold)
                        .foregroundColor(.yellow)
                }
                
                HStack {
                    Text(localizationManager.localized("game_over.total_coins"))
                        .foregroundColor(.white.opacity(0.8))
                        .font(.subheadline)
                    Spacer()
                    Text("\(viewModel.accumulatedCoins)")
                        .font(.body)
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.1))
            )
            
            VStack(spacing: 15) {
                // Back home 按钮
                Button(action: {
                    audioManager.playSoundEffect("click", fileExtension: "wav")
                    viewModel.exitToHome()
                }) {
                    Text(localizationManager.localized("confirmations.back_to_home"))
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.gray, Color.gray.opacity(0.8)]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(15)
                }
                
                // Play again 按钮
                Button(action: {
                    audioManager.playSoundEffect("click", fileExtension: "wav")
                    viewModel.restartGame()
                }) {
                    Text(localizationManager.localized("game_over.play_again"))
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
    let isDismissing: Bool
    @State private var offset: CGFloat = 30
    @State private var opacity: Double = 0
    @State private var scale: CGFloat = 0.8
    @State private var glowIntensity: Double = 0
    
    // 从文本中提取金币数量（例如从 "+1金币" 提取 1）
    private var coinAmount: Int {
        // 尝试从文本中提取数字
        let numbers = text.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
        return Int(numbers) ?? 0
    }
    
    var body: some View {
        ZStack {
            // 发光效果
            HStack(spacing: 8) {
                Text("+\(coinAmount)")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.clear)
                
                Image("coin_icon")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 24, height: 24)
                    .opacity(0)
            }
                .padding(.horizontal, 24)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 25)
                        .fill(Color.yellow.opacity(glowIntensity * 0.3))
                        .blur(radius: 8)
                )
            
            // 主文本：+数量 和 coin_icon
            HStack(spacing: 8) {
                Text("+\(coinAmount)")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.yellow) // 使用与金币一致的黄色
                    .textStroke() // 黑色描边
                
                Image("coin_icon")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 24, height: 24)
            }
                .padding(.horizontal, 24)
                .padding(.vertical, 14)
                .background(
                    ZStack {
                        Image("coin_bg")
                            .resizable()
                            .scaledToFill()
                            .clipped()
                    }
                    .shadow(color: .black.opacity(0.4), radius: 12, x: 0, y: 6)
                )
        }
        .offset(y: offset - 50) // 整体上移50像素
        .opacity(opacity)
        .scaleEffect(scale)
        .allowsHitTesting(false) // 不阻挡其他UI交互
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
        }
        .onChange(of: isDismissing) { dismissing in
            if dismissing {
                // 强制消失动画
                withAnimation(.easeOut(duration: 0.3)) {
                    offset = -20
                    opacity = 0
                    scale = 0.9
                    glowIntensity = 0
                }
            }
        }
    }
}

// MARK: - 骰子动画视图
struct DiceAnimationView: View {
    let diceResult: Int
    let diceCount: Int
    let individualResults: [Int] // 每个骰子的单独结果
    @State private var currentFrame: Int = 1 // 当前动画帧（1-6循环）
    @State private var animationTimer: Timer?
    @State private var scale: CGFloat = 0.5
    @State private var opacity: Double = 0
    @State private var showResult: Bool = false
    @State private var diceSoundPlayer: AVAudioPlayer? = nil // 骰子音效播放器
    
    init(diceResult: Int, diceCount: Int = 1, individualResults: [Int] = []) {
        self.diceResult = diceResult
        self.diceCount = diceCount
        self.individualResults = individualResults
    }
    
    var body: some View {
        VStack {
            Spacer()
            
            ZStack {
                // 旋转阶段：循环播放 dice_01 到 dice_06 动画
                if !showResult {
                    HStack(spacing: 10) {
                        ForEach(0..<min(diceCount, 3), id: \.self) { _ in
                            Image("dice_\(String(format: "%02d", currentFrame))")
                                .resizable()
                                .scaledToFit()
                                .frame(width: diceCount == 1 ? 100 : 70, height: diceCount == 1 ? 100 : 70)
                        }
                        if diceCount > 3 {
                            Text("+\(diceCount - 3)")
                                .font(.system(size: 40, weight: .bold))
                                .foregroundColor(.yellow)
                        }
                    }
                    .scaleEffect(scale)
                    .opacity(opacity)
                }
                
                // 结果阶段：显示每个骰子的结果图片
                if showResult {
                    VStack(spacing: 10) {
                        HStack(spacing: 8) {
                            // 显示每个骰子的结果图片
                            ForEach(0..<min(individualResults.count, 3), id: \.self) { index in
                                let result = individualResults[index]
                                Image("dice_\(String(format: "%02d", result))")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: diceCount == 1 ? 100 : 70, height: diceCount == 1 ? 100 : 70)
                            }
                            if diceCount > 3 {
                                Text("+\(diceCount - 3)")
                                    .font(.system(size: 30, weight: .bold))
                                    .foregroundColor(.yellow)
                            }
                        }
                        
                        // 显示总和
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
                                        Color.yellow.opacity(0.9),
                                        Color.black.opacity(0.95)
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 30)
                                    .stroke(Color.black, lineWidth: 5)
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
            // 播放骰子动画音效（只在转动过程中播放）
            startDiceSound()
            
            // 开始循环播放骰子动画（dice_01 到 dice_06）
            startDiceAnimation()
            
            // 第一阶段：显示动画（0.8秒）
            withAnimation(.easeIn(duration: 0.2)) {
                opacity = 1.0
                scale = 1.2
            }
            
            // 第二阶段：显示结果（0.8秒后）
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                // 停止骰子转动音效
                stopDiceSound()
                stopDiceAnimation()
                showResult = true
                
                // 播放骰子展示音效
                AudioManager.shared.playSoundEffect("dice_show", fileExtension: "wav")
                
                // 弹出动画
                withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                    scale = 1.0
                }
            }
            
            // 第三阶段：淡出（0.8秒后开始淡出，即1.6秒后）
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) {
                withAnimation(.easeOut(duration: 0.3)) {
                    opacity = 0
                    scale = 0.8
                }
            }
        }
        .onDisappear {
            stopDiceSound()
            stopDiceAnimation()
        }
        .allowsHitTesting(false) // 不阻挡其他UI交互
    }
    
    /// 开始播放骰子转动音效
    private func startDiceSound() {
        guard let url = Bundle.main.url(forResource: "dice", withExtension: "mp3") else {
            print("⚠️ [骰子音效] 找不到音频文件: dice.mp3")
            return
        }
        
        do {
            diceSoundPlayer = try AVAudioPlayer(contentsOf: url)
            diceSoundPlayer?.numberOfLoops = -1 // 循环播放
            diceSoundPlayer?.volume = 1.0
            diceSoundPlayer?.play()
            print("🎲 [骰子音效] 开始播放转动音效")
        } catch {
            print("❌ [骰子音效] 播放失败: \(error)")
        }
    }
    
    /// 停止骰子转动音效
    private func stopDiceSound() {
        diceSoundPlayer?.stop()
        diceSoundPlayer = nil
        print("🎲 [骰子音效] 停止转动音效")
    }
    
    private func startDiceAnimation() {
        stopDiceAnimation()
        currentFrame = 1
        
        // 计算每帧的持续时间（快速循环，0.8秒内循环多次）
        let frameDuration = 0.1 // 每帧0.1秒，快速循环
        
        // 创建定时器，循环播放 dice_01 到 dice_06
        animationTimer = Timer.scheduledTimer(withTimeInterval: frameDuration, repeats: true) { timer in
            currentFrame = (currentFrame % 6) + 1 // 1-6循环
        }
        
        // 将定时器添加到 common mode，确保在滚动等操作时也能正常运行
        if let timer = animationTimer {
            RunLoop.current.add(timer, forMode: .common)
        }
    }
    
    private func stopDiceAnimation() {
        animationTimer?.invalidate()
        animationTimer = nil
    }
}

// MARK: - 符号Buff气泡提示
struct SymbolBuffTipView: View {
    let symbol: Symbol
    let isDismissing: Bool
    @ObservedObject var localizationManager = LocalizationManager.shared
    @State private var offset: CGFloat = 30
    @State private var opacity: Double = 0
    @State private var scale: CGFloat = 0.8
    
    // 获取type的多语言名称
    private func getTypeLocalizedName(_ type: String) -> String {
        // 构建多语言key（先尝试原始大小写）
        var key = "symbol_type.\(type)"
        var localized = localizationManager.localized(key)
        
        // 如果返回的文本和key不同，说明找到了翻译
        if localized != key {
            return localized
        }
        
        // 如果没找到，尝试小写版本（处理 Extinction -> extinction）
        let lowercasedType = type.lowercased()
        if lowercasedType != type {
            key = "symbol_type.\(lowercasedType)"
            localized = localizationManager.localized(key)
            if localized != key {
                return localized
            }
        }
        
        // 如果还是没找到，返回首字母大写的原始文本
        return type.capitalized
    }
    
    var body: some View {
        VStack {
            VStack(spacing: 12) {
                // 符号图标
                if symbol.isImageResource {
                    Image(symbol.imageName)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 100, height: 100) // 放大至原先2倍
                } else {
                Text(symbol.icon)
                        .font(.system(size: 100)) // 放大至原先2倍
                }
                
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
                Text(symbol.rarity.displayName)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(symbol.rarity.color.opacity(0.3))
                    )
                    .foregroundColor(.white)
                
                // 类型标签
                if !symbol.types.isEmpty {
                    HStack(spacing: 6) {
                        ForEach(symbol.types, id: \.self) { type in
                            Text(getTypeLocalizedName(type))
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
                    
                    RichTextView(symbol.description, defaultColor: .white, font: .body, multilineTextAlignment: .center)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.horizontal, 10)
                }
            }
            .padding(25)
            .background(
                RoundedRectangle(cornerRadius: 25)
                    .fill(Color(hex: "363739"))
                    .shadow(color: .black.opacity(0.4), radius: 15, x: 0, y: 8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 25)
                            .stroke(symbol.rarity.color, lineWidth: 2)
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
        }
        .onChange(of: isDismissing) { dismissing in
            if dismissing {
                // 触发消失动画（由用户手动关闭触发）
                withAnimation(.easeOut(duration: 0.3)) {
                    offset = -20
                    opacity = 0
                    scale = 0.9
                }
            }
        }
        .allowsHitTesting(true) // 允许点击，但点击弹窗本身不关闭
    }
}

// MARK: - 哥布林Buff气泡提示
struct GoblinBuffTipView: View {
    let goblin: Goblin
    let isDismissing: Bool
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
        }
        .onChange(of: isDismissing) { dismissing in
            if dismissing {
                // 强制消失动画
                withAnimation(.easeOut(duration: 0.3)) {
                    offset = -20
                    opacity = 0
                    scale = 0.9
                }
            }
        }
        .allowsHitTesting(false) // 不阻挡其他UI交互
    }
}

// MARK: - 调试面板
struct DebugPanelView: View {
    @ObservedObject var viewModel: GameViewModel
    @ObservedObject var localizationManager = LocalizationManager.shared
    @ObservedObject var audioManager = AudioManager.shared
    @State private var selectedTab: Int = 0
    
    var body: some View {
        HStack {
            Spacer()
            
            VStack(spacing: 0) {
                // 标题栏
                HStack {
                    Text(localizationManager.localized("game.debug_panel"))
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Button(action: {
                        audioManager.playSoundEffect("click", fileExtension: "wav")
                        viewModel.toggleDebugPanel()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title3)
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
                .padding()
                .background(Color.blue.opacity(0.8))
                
                // 标签切换
                Picker("", selection: $selectedTab) {
                    Text(localizationManager.localized("game.settlement_logs")).tag(0)
                    Text(localizationManager.localized("game.board_status")).tag(1)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal)
                .padding(.vertical, 8)
                .background(Color.white.opacity(0.1))
                
                // 内容区域
                ScrollView {
                    VStack(alignment: .leading, spacing: 8) {
                        if selectedTab == 0 {
                            // 结算日志
                            if viewModel.settlementLogs.isEmpty {
                                Text(localizationManager.localized("game.no_logs"))
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                    .padding()
                            } else {
                                ForEach(Array(viewModel.settlementLogs.enumerated()), id: \.offset) { index, log in
                                    Text(log)
                                        .font(.system(.caption, design: .monospaced))
                                        .foregroundColor(.white)
                                }
                            }
                        } else {
                            // 棋盘状态
                            Text(viewModel.getBoardDebugInfo())
                                .font(.system(.caption, design: .monospaced))
                                .foregroundColor(.white)
                        }
                    }
                    .padding()
                }
                .frame(maxHeight: .infinity)
                
                // 底部操作栏
                HStack(spacing: 12) {
                    Button(action: {
                        audioManager.playSoundEffect("click", fileExtension: "wav")
                        viewModel.toggleTransparentMode()
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: viewModel.transparentMode ? "eye.fill" : "eye.slash.fill")
                            Text(viewModel.transparentMode ?
                                 localizationManager.localized("game.hide") :
                                 localizationManager.localized("game.show"))
                                .font(.caption)
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(viewModel.transparentMode ? Color.green.opacity(0.5) : Color.gray.opacity(0.3))
                        )
                    }
                    
                    Spacer()
                    
                    // 复制日志按钮
                    Button(action: {
                        audioManager.playSoundEffect("click", fileExtension: "wav")
                        let logText = viewModel.settlementLogs.joined(separator: "\n")
                        UIPasteboard.general.string = logText
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "doc.on.doc")
                            Text(localizationManager.localized("game.copy"))
                                .font(.caption)
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.gray.opacity(0.3))
                        )
                    }
                }
                .padding()
                .background(Color.white.opacity(0.1))
            }
            .frame(width: 320)
            .background(Color.black.opacity(0.95))
            .cornerRadius(20, corners: [.topLeft, .bottomLeft])
            .shadow(color: .black.opacity(0.5), radius: 10, x: -5, y: 0)
        }
    }
}

// MARK: - 圆角扩展
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

// MARK: - 金币飞出动画组件
struct CoinFloatView: View {
    let earnings: Int
    
    @State private var offset: CGFloat = 0
    @State private var opacity: Double = 1.0
    @State private var scale: CGFloat = 0.5
    
    var body: some View {
        Text("+\(earnings)")
            .font(.system(size: 32, weight: .bold))
            .foregroundColor(.yellow)
            .shadow(color: .orange, radius: 3, x: 0, y: 0)
            .shadow(color: .black.opacity(0.6), radius: 5, x: 0, y: 2)
            .scaleEffect(scale)
            .opacity(opacity)
            .offset(y: offset)
            .onAppear {
                // 第一阶段：快速放大到位（0.2秒）
                withAnimation(.easeOut(duration: 0.2)) {
                    scale = 1.8
                    offset = -20
                }
                
                // 第二阶段：停留并保持清晰（0.8秒后开始淡出）
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                    withAnimation(.easeOut(duration: 0.3)) {
                        offset = -60
                        opacity = 0
                    }
                }
            }
    }
}

#Preview {
    let viewModel = GameViewModel()
    viewModel.selectedGoblin = Goblin.allGoblins[0]
    viewModel.goblinSelectionCompleted = true
    return GameView(viewModel: viewModel)
}

// MARK: - 金币数量动画视图
struct CoinAmountView: View {
    let amount: Int
    @State private var previousAmount: Int = 0
    @State private var scale: CGFloat = 1.0
    @State private var color: Color = .yellow
    
    var body: some View {
        Text("\(amount)")
            .font(.system(size: 14, weight: .bold))
            .foregroundColor(color)
            .scaleEffect(scale)
            .onChange(of: amount) { newAmount in
                if newAmount != previousAmount {
                    print("💰 [金币动画] 金币变化: \(previousAmount) → \(newAmount)")
                    // 金币变化动画
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                        scale = 1.3
                        color = newAmount > previousAmount ? .green : .red
                    }
                    
                    // 恢复动画
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                            scale = 1.0
                            color = .yellow
                        }
                    }
                    
                    previousAmount = newAmount
                }
            }
            .onAppear {
                previousAmount = amount
            }
    }
}

// MARK: - 特殊格子闪光效果视图
struct SpecialCellGlowView: View {
    @State private var glowOpacity: Double = 0.5
    
    var body: some View {
        RoundedRectangle(cornerRadius: 12)
            .stroke(
                LinearGradient(
                    gradient: Gradient(colors: [Color.red.opacity(0.9), Color.pink.opacity(0.7)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                lineWidth: 3
            )
            .blur(radius: 1.5)
            .shadow(color: .red.opacity(0.8), radius: 10, x: 0, y: 0)
            .frame(width: 60, height: 60)
            .opacity(glowOpacity)
            .onAppear {
                withAnimation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true)) {
                    glowOpacity = 1.0
                }
            }
    }
}

// MARK: - 骰子数量动画视图
struct DiceCountAnimationView: View {
    let diceCount: Int
    @State private var previousCount: Int = 1
    @State private var scale: CGFloat = 1.0
    @State private var glowOpacity: Double = 0.0
    @State private var rotation: Double = 0
    
    var body: some View {
        Text("x\(diceCount)")
            .font(.system(size: 14, weight: .semibold))
            .foregroundColor(.white)
            .scaleEffect(scale)
            .rotationEffect(.degrees(rotation))
            .overlay(
                // 闪光效果
                RoundedRectangle(cornerRadius: 4)
                    .fill(
                        LinearGradient(
                            colors: [.yellow.opacity(glowOpacity), .orange.opacity(glowOpacity * 0.5)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .blur(radius: 8)
                    .opacity(glowOpacity)
            )
            .onChange(of: diceCount) { newValue in
                if newValue > previousCount {
                    // 骰子数量增加，播放动画
                    print("✨ [骰子动画] 骰子数量增加: \(previousCount) → \(newValue)")
                    playAnimation()
                }
                previousCount = newValue
            }
            .onAppear {
                previousCount = diceCount
            }
    }
    
    private func playAnimation() {
        // 重置状态
        scale = 1.0
        glowOpacity = 0.0
        rotation = 0
        
        // 第一阶段：放大+旋转+闪光
        withAnimation(.easeOut(duration: 0.2)) {
            scale = 1.5
            rotation = 10
            glowOpacity = 1.0
        }
        
        // 第二阶段：恢复+继续闪光
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                scale = 1.0
                rotation = 0
            }
            
            // 闪光逐渐消失
            withAnimation(.easeOut(duration: 0.4)) {
                glowOpacity = 0.0
            }
        }
    }
}
