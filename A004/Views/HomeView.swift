//
//  HomeView.swift
//  A004
//
//  游戏首页
//

import SwiftUI

// 用于标识要打开的商城标签页
struct StoreTabIdentifier: Identifiable {
    let id = UUID()
    let tab: PaidStoreView.StoreTab
}

struct HomeView: View {
    @ObservedObject var viewModel: GameViewModel
    @ObservedObject var localizationManager = LocalizationManager.shared
    @State private var showGoblinSelection = false
    @State private var storeTabIdentifier: StoreTabIdentifier? = nil
    @State private var showDailySignIn = false
    @State private var showSettings = false
    @State private var showTutorial = false
    
    // 检查是否需要显示教程
    private var shouldShowTutorial: Bool {
        !UserDefaults.standard.bool(forKey: "hasCompletedTutorial")
    }

    var body: some View {
        ZStack {
            // 背景图片（放在最外层，确保填充整个屏幕包括安全区域）
            Image("homeBG")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .ignoresSafeArea(.all)
                .clipped()
            
            GeometryReader { geometry in
                // iPhone 17 设计规格：390 × 922
                let designWidth: CGFloat = 390
                let designHeight: CGFloat = 922
                let scaleX = geometry.size.width / designWidth
                let scaleY = geometry.size.height / designHeight
                
                ZStack {

                VStack(spacing: 0) {
                    // 顶部标题区域（基于设计稿位置）
                    VStack(spacing: 15) {
                        Text("👹")
                            .font(.system(size: 80))
                            .padding(.bottom, 10)

                        Text(localizationManager.localized("app.name"))
                            .font(.system(size: 36, weight: .bold))
                            .foregroundColor(.white)
                            .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 2)

                        Text(localizationManager.localized("app.subtitle"))
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))
                    }
                    .padding(.top, 100 * scaleY) // 从顶部 100 点开始

                    Spacer()
                        .frame(maxHeight: 50 * scaleY) // 限制最大间距

                    // 个人最佳记录区域（中心展示）
                    VStack(spacing: 15) {
                        Text(localizationManager.localized("home.personal_records"))
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.white)
                            .shadow(color: .black.opacity(0.3), radius: 1, x: 0, y: 1)

                        VStack(spacing: 10) {
                            HStack {
                                Text(localizationManager.localized("home.best_round"))
                                    .foregroundColor(.white.opacity(0.8))
                                    .font(.system(size: 16))
                                Spacer()
                                Text("\(viewModel.bestRound)\(localizationManager.localized("game.round"))")
                                    .foregroundColor(.yellow)
                                    .font(.system(size: 18, weight: .bold))
                            }

                            HStack {
                                Text(localizationManager.localized("home.total_coins"))
                                    .foregroundColor(.white.opacity(0.8))
                                    .font(.system(size: 16))
                                Spacer()
                                Text("\(viewModel.bestCoins)\(localizationManager.localized("game.coins"))")
                                    .foregroundColor(.yellow)
                                    .font(.system(size: 18, weight: .bold))
                            }
                        }
                        .padding(.horizontal, 30)
                        .padding(.vertical, 20)
                        .background(
                            RoundedRectangle(cornerRadius: 15)
                                .fill(Color.white.opacity(0.1))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 15)
                                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                )
                        )
                    }
                    .padding(.horizontal, 20)

                    Spacer()
                        .frame(maxHeight: 50 * scaleY) // 限制最大间距

                    // Play 按钮（主要按钮）
                    Button(action: {
                        // 检查体力是否足够
                        if viewModel.stamina < 30 {
                            // 体力不足，显示提示或跳转到付费商城体力页
                            storeTabIdentifier = StoreTabIdentifier(tab: .stamina)
                        } else {
                            showGoblinSelection = true
                        }
                    }) {
                        HStack(spacing: 15) {
                            Image(systemName: "play.fill")
                                .font(.system(size: 24))
                            Text(viewModel.stamina >= 30 ?
                                 localizationManager.localized("home.start_game") :
                                 localizationManager.localized("home.stamina_insufficient"))
                                .font(.system(size: 20, weight: .bold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: viewModel.stamina >= 30 ? 
                                    [Color.green, Color.blue] : 
                                    [Color.gray, Color.gray.opacity(0.7)]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(25)
                        .shadow(color: .black.opacity(0.3), radius: 5, x: 0, y: 3)
                    }
                    .padding(.horizontal, 40)

                    Spacer()
                        .frame(maxHeight: 30 * scaleY) // 限制最大间距

                    // 底部功能按钮组
                    VStack(spacing: 12) {
                        // 第一行：商城和签到
                        HStack(spacing: 15) {
                            // 付费商城
                            Button(action: {
                                // 默认显示哥布林页
                                storeTabIdentifier = StoreTabIdentifier(tab: .goblins)
                            }) {
                                VStack(spacing: 8) {
                                    Image(systemName: "cart.fill")
                                        .font(.system(size: 24))
                                        .foregroundColor(.orange)
                                    Text(localizationManager.localized("stores.paid_store"))
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(.white)
                                }
                                .frame(width: 80, height: 60)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.white.opacity(0.1))
                                )
                            }

                            // 七日签到
                            Button(action: {
                                showDailySignIn = true
                            }) {
                                VStack(spacing: 8) {
                                    Image(systemName: "calendar")
                                        .font(.system(size: 24))
                                        .foregroundColor(.pink)
                                    Text(localizationManager.localized("stores.daily_sign_in"))
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(.white)
                                }
                                .frame(width: 80, height: 60)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.white.opacity(0.1))
                                )
                            }
                        }

                        // 第二行：设置按钮
                        Button(action: {
                            showSettings = true
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: "gear")
                                    .font(.system(size: 16))
                                Text(localizationManager.localized("settings.title").replacingOccurrences(of: "⚙️ ", with: ""))
                                    .font(.system(size: 14, weight: .medium))
                            }
                            .foregroundColor(.white.opacity(0.7))
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(Color.white.opacity(0.1))
                            )
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40 * scaleY)
                }
            
                // 体力条和钻石条 - 固定在右上角，左右平行排列
                VStack {
                    HStack {
                        Spacer()
                        HStack(spacing: 12) {
                            // 钻石条
                            DiamondBarView(
                                viewModel: viewModel,
                                showPaidStore: Binding(
                                    get: { storeTabIdentifier != nil },
                                    set: { if !$0 { storeTabIdentifier = nil } }
                                ),
                                onShowStore: {
                                    // 创建新的标识符，强制重新创建视图
                                    storeTabIdentifier = StoreTabIdentifier(tab: .diamonds)
                                }
                            )
                            .frame(width: 140, height: 60)
                            
                            // 体力条
                            StaminaBarView(
                                viewModel: viewModel,
                                showPaidStore: Binding(
                                    get: { storeTabIdentifier != nil },
                                    set: { if !$0 { storeTabIdentifier = nil } }
                                ),
                                onShowStore: {
                                    // 创建新的标识符，强制重新创建视图
                                    storeTabIdentifier = StoreTabIdentifier(tab: .stamina)
                                }
                            )
                            .frame(width: 140, height: 60)
                        }
                        .padding(.top, 10 * scaleY + 80) // 向下移动 20 像素
                        .padding(.trailing, 20 * scaleX)
                    }
                    Spacer()
                }
                }
            }
        }
        .ignoresSafeArea(.all) // 确保整个视图忽略安全区域
        // 哥布林选择弹窗
        .sheet(isPresented: $showGoblinSelection) {
            GoblinSelectionView(
                selectedGoblin: $viewModel.selectedGoblin,
                isPresented: $showGoblinSelection,
                unlockedGoblinIds: $viewModel.unlockedGoblinIds,
                currentCoins: $viewModel.currentCoins,
                viewModel: viewModel
            )
        }
        .onChange(of: viewModel.selectedGoblin) { goblin in
            if goblin != nil {
                // 哥布林选择完成，开始游戏
                viewModel.onGoblinSelected()
            }
        }
        // 付费商城弹窗
        .sheet(item: $storeTabIdentifier) { identifier in
            PaidStoreView(
                viewModel: viewModel,
                isPresented: Binding(
                    get: { storeTabIdentifier != nil },
                    set: { if !$0 { storeTabIdentifier = nil } }
                ),
                initialTab: identifier.tab
            )
        }
        // 七日签到弹窗
        .sheet(isPresented: $showDailySignIn) {
            DailySignInView(viewModel: viewModel, isPresented: $showDailySignIn)
        }
        // 设置弹窗（首页设置）
        .overlay {
            if showSettings {
                HomeSettingsView(isPresented: $showSettings)
            }
        }
        // 新手教程（使用 overlay 确保在最上层）
        .overlay {
            if showTutorial {
                TutorialView(
                    isPresented: $showTutorial,
                    steps: createTutorialSteps()
                )
                .allowsHitTesting(true) // 允许教程接收点击事件
                .zIndex(1000) // 确保在最上层
            }
        }
        .onAppear {
            // 检查是否需要显示教程
            if shouldShowTutorial {
                // 延迟一点显示教程，确保视图已完全加载
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    showTutorial = true
                }
            }
        }
    }
    
    /// 创建教程步骤（基于 iPhone 17 规格：390×922）
    private func createTutorialSteps() -> [TutorialStep] {
        let screenWidth = UIScreen.main.bounds.width
        let screenHeight = UIScreen.main.bounds.height
        let designWidth: CGFloat = 390
        let designHeight: CGFloat = 922
        let scaleX = screenWidth / designWidth
        let scaleY = screenHeight / designHeight
        
        return [
            // 步骤1：介绍开始游戏按钮（基于设计稿位置）
            TutorialStep(
                title: "tutorial.step1.title",
                description: "tutorial.step1.description",
                highlightFrame: CGRect(
                    x: screenWidth / 2 - 150 * scaleX,
                    y: 650 * scaleY, // 基于设计稿位置
                    width: 300 * scaleX,
                    height: 60 * scaleY
                ),
                highlightCornerRadius: 25,
                arrowPosition: CGPoint(x: 0, y: -80 * scaleY),
                arrowDirection: .down,
                arrowOffset: 0
            ),
            // 步骤2：介绍资源条（钻石和体力）
            TutorialStep(
                title: "tutorial.step2.title",
                description: "tutorial.step2.description",
                highlightFrame: CGRect(
                    x: max(20 * scaleX, screenWidth - 300 * scaleX), // 确保不超出左边界
                    y: 50 * scaleY,
                    width: min(300 * scaleX, screenWidth - 40 * scaleX), // 确保不超出屏幕
                    height: 60 * scaleY
                ),
                highlightCornerRadius: 15,
                arrowPosition: CGPoint(x: -100 * scaleX, y: 0),
                arrowDirection: .right,
                arrowOffset: 0
            ),
            // 步骤3：介绍商城功能
            TutorialStep(
                title: "tutorial.step3.title",
                description: "tutorial.step3.description",
                highlightFrame: CGRect(
                    x: screenWidth / 2 - 50 * scaleX,
                    y: screenHeight - 150 * scaleY,
                    width: 100 * scaleX,
                    height: 60 * scaleY
                ),
                highlightCornerRadius: 12,
                arrowPosition: CGPoint(x: 0, y: 50 * scaleY),
                arrowDirection: .up,
                arrowOffset: 0
            )
        ]
    }
}

// MARK: - 体力条视图
struct StaminaBarView: View {
    @ObservedObject var viewModel: GameViewModel
    @Binding var showPaidStore: Bool
    let onShowStore: () -> Void
    @State private var timeRemaining: Int = 0
    @State private var timer: Timer?
    
    var body: some View {
        VStack(alignment: .trailing, spacing: 4) {
            // 第一行：图标、数值、加号按钮
            HStack(spacing: 6) {
                // 体力图标
                Image(systemName: "bolt.fill")
                    .font(.system(size: 14))
                    .foregroundColor(.yellow)
                
                // 体力数值
                Text("\(viewModel.stamina)/\(viewModel.maxStamina)")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.white)
                
                // 加号按钮（跳转到付费商城体力页）
                Button(action: onShowStore) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.white)
                }
            }
            
            // 第二行：只显示进度条
            HStack(spacing: 4) {
                // 进度条（缩短版）
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        // 背景
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color.white.opacity(0.2))
                            .frame(height: 4)
                        
                        // 进度
                        RoundedRectangle(cornerRadius: 2)
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        viewModel.stamina >= 30 ? Color.green : Color.orange,
                                        viewModel.stamina >= 30 ? Color.blue : Color.red
                                    ]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geometry.size.width * CGFloat(viewModel.stamina) / CGFloat(viewModel.maxStamina), height: 4)
                    }
                }
                .frame(width: 120, height: 4) // 固定宽度，适配整体宽度
            }
                
            // 第三行：体力倒计时（独立显示）
                if viewModel.stamina < viewModel.maxStamina && timeRemaining > 0 {
                    let minutes = timeRemaining / 60
                    let seconds = timeRemaining % 60
                HStack(spacing: 4) {
                    Text("⏱️")
                        .font(.system(size: 10))
                    Text("\(minutes):\(String(format: "%02d", seconds))")
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(.white.opacity(0.8))
                }
                .padding(.top, 2)
            }
        }
        .frame(width: 140, height: 60) // 增加高度，为更大的倒计时数字留出空间
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color.black.opacity(0.3))
                .overlay(
                    RoundedRectangle(cornerRadius: 15)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
        )
        .onAppear {
            startTimer()
        }
        .onDisappear {
            timer?.invalidate()
        }
        .onChange(of: viewModel.stamina) { _ in
            updateTimeRemaining()
        }
        .onChange(of: viewModel.nextStaminaRecoveryTime) { _ in
            updateTimeRemaining()
        }
    }
    
    private func startTimer() {
        updateTimeRemaining()
        // 每秒更新一次倒计时
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            self.updateTimeRemaining()
        }
    }
    
    private func updateTimeRemaining() {
        let remaining = viewModel.getStaminaRecoveryTimeRemaining()
        if remaining != timeRemaining {
            timeRemaining = remaining
        }
        
        // 如果倒计时为0且体力未满，触发体力恢复检查
        if remaining == 0 && viewModel.stamina < viewModel.maxStamina {
            // 延迟一点再检查，确保体力恢复逻辑已执行
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.updateTimeRemaining()
            }
        }
    }
}

// MARK: - 钻石条视图
struct DiamondBarView: View {
    @ObservedObject var viewModel: GameViewModel
    @Binding var showPaidStore: Bool
    let onShowStore: () -> Void
    
    var body: some View {
        VStack(alignment: .trailing, spacing: 4) {
            // 第一行：图标、数值、加号按钮
            HStack(spacing: 6) {
                // 钻石图标
                Text("💎")
                    .font(.system(size: 14))
                
                // 钻石数值
                Text("\(viewModel.diamonds)")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.white)
                
                // 加号按钮（跳转到付费商城钻石页）
                Button(action: onShowStore) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.white)
                }
            }
            
            // 第二行：占位（保持样式一致）
            HStack(spacing: 4) {
                // 占位空间，保持与体力条一致的高度和宽度
                Spacer()
                    .frame(width: 120, height: 4)
            }
            
            // 第三行：空占位，保持高度一致
            HStack(spacing: 4) {
                Spacer()
                    .frame(width: 120, height: 10)
            }
        }
        .frame(width: 140, height: 60) // 与体力条高度一致
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color.black.opacity(0.3))
                .overlay(
                    RoundedRectangle(cornerRadius: 15)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
        )
    }
}

#Preview {
    HomeView(viewModel: GameViewModel())
}

