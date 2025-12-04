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
    
    // 获取自定义字体
    private func customFont(size: CGFloat) -> Font {
        return FontManager.shared.customFont(size: size)
    }
    
    // Figma 设计稿尺寸：1202 x 2622
    private let figmaWidth: CGFloat = 1202
    private let figmaHeight: CGFloat = 2622

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
                // 使用比例定位，而不是绝对坐标
                let scaleX = geometry.size.width / figmaWidth
                let scaleY = geometry.size.height / figmaHeight
                
                ZStack {
                    // 顶部左侧：哥布林信息区域
                    // Main_menu 1 背景（Figma: x: 37, y: 76, 485.01 x 251.44）
                    ZStack(alignment: .topLeading) {
                        Image("Main_menu 1")
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 485.01 * scaleX, height: 251.44 * scaleY)
                            .clipped()
                        
                        // avatarBG（Figma: x: 37, y: 72, 191 x 191）
                        Image("avatarBG")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 191 * scaleX, height: 191 * scaleY)
                            .offset(x: 0, y: -4 * scaleY)
                        
                        // avatar1（Figma: x: 55, y: 90, 152 x 149）
                        Image("avatar1")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 152 * scaleX, height: 149 * scaleY)
                            .offset(x: 18 * scaleX, y: 14 * scaleY)
                        
                        // "[Goblin]" 文字（Figma: x: 237, y: 112）
                        Text("[Goblin]")
                            .font(customFont(size: 57 * scaleX))
                            .foregroundColor(.white)
                            .textStroke()
                            .offset(x: (237 - 37) * scaleX, y: (112 - 76) * scaleY)
                        
                        // "best level: 10" 文字（Figma: x: 242, y: 191）
                        Text("best level:\n\(viewModel.bestRound)")
                            .font(customFont(size: 42 * scaleX))
                            .foregroundColor(.white)
                            .textStroke()
                            .offset(x: (242 - 37) * scaleX, y: (191 - 76) * scaleY)
                    }
                    .frame(width: 485.01 * scaleX, height: 251.44 * scaleY)
                    .position(
                        x: (37 + 485.01/2) * scaleX,
                        y: (76 + 251.44/2) * scaleY + 60
                    )
                    
                    // 顶部右侧：资源条区域
                    // 体力条（Figma: x: 591, y: 90, 289 x 127）
                    StaminaBarView(
                        viewModel: viewModel,
                        showPaidStore: Binding(
                            get: { storeTabIdentifier != nil },
                            set: { if !$0 { storeTabIdentifier = nil } }
                        ),
                        onShowStore: {
                            storeTabIdentifier = StoreTabIdentifier(tab: .stamina)
                        }
                    )
                    .frame(width: 289 * scaleX, height: 127 * scaleY)
                    .position(
                        x: geometry.size.width - (figmaWidth - 591 - 289/2) * scaleX,
                        y: (90 + 127/2) * scaleY + 60
                    )
                    
                    // 钻石条（Figma: x: 894, y: 89, 288 x 127）
                    DiamondBarView(
                        viewModel: viewModel,
                        showPaidStore: Binding(
                            get: { storeTabIdentifier != nil },
                            set: { if !$0 { storeTabIdentifier = nil } }
                        ),
                        onShowStore: {
                            storeTabIdentifier = StoreTabIdentifier(tab: .diamonds)
                        }
                    )
                    .frame(width: 288 * scaleX, height: 127 * scaleY)
                    .position(
                        x: geometry.size.width - (figmaWidth - 894 - 288/2) * scaleX,
                        y: (89 + 127/2) * scaleY + 60
                    )
                    
                    // 中间：哥布林的家（Figma: x: 50, y: 609, 1102 x 1121）
                    Image("house")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: min(1102 * scaleX, geometry.size.width * 0.9), height: min(1121 * scaleY, geometry.size.height * 0.5))
                        .position(
                            x: geometry.size.width / 2,
                            y: (609 + 1121/2) * scaleY
                        )
                    
                    // Start 按钮（Figma: x: 344, y: 1802, 503 x 263）
                    Button(action: {
                        if viewModel.stamina < 30 {
                            storeTabIdentifier = StoreTabIdentifier(tab: .stamina)
                        } else {
                            showGoblinSelection = true
                        }
                    }) {
                        ZStack {
                            Image("start")
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: min(503 * scaleX, geometry.size.width * 0.85), height: 263 * scaleY)
                                .clipped()
                            
                            Text("Start")
                                .font(customFont(size: 78 * scaleX))
                                .foregroundColor(.white)
                                .textStroke()
                        }
                    }
                    .frame(width: min(503 * scaleX, geometry.size.width * 0.85), height: 263 * scaleY)
                    .position(
                        x: geometry.size.width / 2,
                        y: (1802 + 263/2) * scaleY - 13
                    )
                    
                    // 底部区域：蒙版背景 + 按钮 + 文本标签
                    ZStack {
                        // 底部蒙版背景（Figma: x: 0, y: 2314, 1202 x 308，向上移动 20 像素）
                        Rectangle()
                            .fill(Color(red: 0.672, green: 0.609, blue: 0.388, opacity: 0.38))
                            .frame(width: figmaWidth * scaleX, height: 308 * scaleY)
                            .position(
                                x: geometry.size.width / 2,
                                y: geometry.size.height - (figmaHeight - 2314 - 308/2) * scaleY - 40
                            )
                        
                        // settings 按钮图标（Figma: x: 194, y: 2363, 142 x 142）
                        // 注意：使用 settings 图片集（包含 gear 2.png）
                        Button(action: {
                            showSettings = true
                        }) {
                            Image("settings")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 142 * scaleX, height: 142 * scaleY)
                        }
                        .position(
                            x: (194 + 142/2) * scaleX,
                            y: geometry.size.height - (figmaHeight - 2363 - 142/2) * scaleY - 55
                        )
                        
                        // shop 按钮图标（Figma: x: 529, y: 2363, 142 x 142）
                        // 注意：使用 shop 图片集（包含 fc16 2.png）
                        Button(action: {
                            storeTabIdentifier = StoreTabIdentifier(tab: .goblins)
                        }) {
                            Image("shop")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 142 * scaleX, height: 142 * scaleY)
                        }
                        .position(
                            x: (529 + 142/2) * scaleX,
                            y: geometry.size.height - (figmaHeight - 2363 - 142/2) * scaleY - 55
                        )
                        
                        // gift 按钮图标（Figma: x: 883, y: 2363, 142 x 142）
                        // 注意：使用 gift 图片集（包含 gift_01d 1.png）
                        Button(action: {
                            showDailySignIn = true
                        }) {
                            Image("gift")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 142 * scaleX, height: 142 * scaleY)
                        }
                        .position(
                            x: (883 + 142/2) * scaleX,
                            y: geometry.size.height - (figmaHeight - 2363 - 142/2) * scaleY - 55
                        )
                        
                        // "settings" 文本标签（Figma: x: 163, y: 2522, 210 x 69）
                        Text("settings")
                            .font(customFont(size: 48 * scaleX))
                            .foregroundColor(.white)
                            .textStroke()
                            .frame(width: 210 * scaleX, height: 69 * scaleY)
                            .multilineTextAlignment(.center)
                            .position(
                                x: (163 + 210/2) * scaleX,
                                y: geometry.size.height - (figmaHeight - 2522 - 69/2) * scaleY - 55
                            )
                        
                        // "shop" 文本标签（Figma: x: 549, y: 2522, 113 x 74）
                        Text("shop")
                            .font(customFont(size: 48 * scaleX))
                            .foregroundColor(.white)
                            .textStroke()
                            .frame(width: 113 * scaleX, height: 74 * scaleY)
                            .multilineTextAlignment(.center)
                            .position(
                                x: (549 + 113/2) * scaleX,
                                y: geometry.size.height - (figmaHeight - 2522 - 74/2) * scaleY - 55
                            )
                        
                        // "sign-in" 文本标签（Figma: x: 869, y: 2525, 176 x 69）
                        Text("sign-in")
                            .font(customFont(size: 48 * scaleX))
                            .foregroundColor(.white)
                            .textStroke()
                            .frame(width: 176 * scaleX, height: 69 * scaleY)
                            .multilineTextAlignment(.center)
                            .position(
                                x: (869 + 176/2) * scaleX,
                                y: geometry.size.height - (figmaHeight - 2525 - 69/2) * scaleY - 55
                            )
                    }
                }
            }
        }
        .ignoresSafeArea(.all)
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
        // 新手教程
        .overlay {
            if showTutorial {
                TutorialView(
                    isPresented: $showTutorial,
                    steps: createTutorialSteps()
                )
                .allowsHitTesting(true)
                .zIndex(1000)
            }
        }
        .onAppear {
            if shouldShowTutorial {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    showTutorial = true
                }
            }
        }
    }
    
    /// 创建教程步骤
    private func createTutorialSteps() -> [TutorialStep] {
        let screenWidth = UIScreen.main.bounds.width
        let screenHeight = UIScreen.main.bounds.height
        let scaleX = screenWidth / figmaWidth
        let scaleY = screenHeight / figmaHeight
        
        return [
            TutorialStep(
                title: "tutorial.step1.title",
                description: "tutorial.step1.description",
                highlightFrame: CGRect(
                    x: (344 + 503/2 - 150) * scaleX,
                    y: (1802 + 263/2 - 30) * scaleY,
                    width: 300 * scaleX,
                    height: 60 * scaleY
                ),
                highlightCornerRadius: 25,
                arrowPosition: CGPoint(x: 0, y: -80 * scaleY),
                arrowDirection: .down,
                arrowOffset: 0
            ),
            TutorialStep(
                title: "tutorial.step2.title",
                description: "tutorial.step2.description",
                highlightFrame: CGRect(
                    x: screenWidth - 300 * scaleX,
                    y: 90 * scaleY,
                    width: 300 * scaleX,
                    height: 127 * scaleY
                ),
                highlightCornerRadius: 15,
                arrowPosition: CGPoint(x: -100 * scaleX, y: 0),
                arrowDirection: .right,
                arrowOffset: 0
            ),
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

// MARK: - 体力条视图（根据 Figma 设计）
struct StaminaBarView: View {
    @ObservedObject var viewModel: GameViewModel
    @Binding var showPaidStore: Bool
    let onShowStore: () -> Void
    @State private var timeRemaining: Int = 0
    @State private var timer: Timer?
    
    // 获取自定义字体
    private func customFont(size: CGFloat) -> Font {
        return FontManager.shared.customFont(size: size)
    }
    
    var body: some View {
        GeometryReader { geometry in
            let scaleX = geometry.size.width / 289
            let scaleY = geometry.size.height / 127
            
            ZStack(alignment: .topLeading) {
                // 资源条背景（PBP-V2 2）
                Image("resource_bar")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .clipped()
                
                // fruit 图标（Figma: x: 577, y: 112，相对于资源条 x: 591, y: 90）
                Image("fruit")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 87 * scaleX, height: 87 * scaleY)
                    .offset(x: (577 - 591) * scaleX, y: (112 - 90) * scaleY)
                
                // add 2 按钮（Figma: x: 644, y: 151，应该在fruit图标的右下角）
                Button(action: onShowStore) {
                    Image("add 2")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 40 * scaleX, height: 40 * scaleY)
                }
                .offset(x: (644 - 591) * scaleX, y: (151 - 90) * scaleY)
                
                // 体力数值（Figma: x: 677, y: 124）- 横向排列，不换行
                Text("\(viewModel.stamina)/\(viewModel.maxStamina)")
                    .font(customFont(size: 50 * scaleX))
                    .foregroundColor(.white)
                    .textStroke()
                    .lineLimit(1)
                    .frame(width: 165 * scaleX, alignment: .leading)
                    .offset(x: (677 - 591) * scaleX, y: (124 - 90) * scaleY)
                
                // 体力倒计时（Figma: x: 684, y: 216）
                if viewModel.stamina < viewModel.maxStamina && timeRemaining > 0 {
                    let minutes = timeRemaining / 60
                    let seconds = timeRemaining % 60
                    Text("\(minutes):\(String(format: "%02d", seconds))")
                        .font(customFont(size: 40 * scaleX))
                        .foregroundColor(.white)
                        .textStroke()
                        .offset(x: (684 - 591) * scaleX, y: (216 - 90) * scaleY)
                }
            }
        }
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
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            self.updateTimeRemaining()
        }
    }
    
    private func updateTimeRemaining() {
        let remaining = viewModel.getStaminaRecoveryTimeRemaining()
        if remaining != timeRemaining {
            timeRemaining = remaining
        }
        
        if remaining == 0 && viewModel.stamina < viewModel.maxStamina {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.updateTimeRemaining()
            }
        }
    }
}

// MARK: - 钻石条视图（根据 Figma 设计）
struct DiamondBarView: View {
    @ObservedObject var viewModel: GameViewModel
    @Binding var showPaidStore: Bool
    let onShowStore: () -> Void
    
    // 获取自定义字体
    private func customFont(size: CGFloat) -> Font {
        return FontManager.shared.customFont(size: size)
    }
    
    var body: some View {
        GeometryReader { geometry in
            let scaleX = geometry.size.width / 288
            let scaleY = geometry.size.height / 127
            
            ZStack(alignment: .topLeading) {
                // 资源条背景（PBP-V2 3）
                Image("resource_bar")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .clipped()
                
                // crystal 图标（Figma: x: 885, y: 99，相对于资源条 x: 894, y: 89）
                Image("crystal")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 95 * scaleX, height: 95 * scaleY)
                    .offset(x: (885 - 894) * scaleX, y: (99 - 89) * scaleY)
                
                // add 2 按钮（Figma: x: 939, y: 155，应该在crystal图标的右下角）
                Button(action: onShowStore) {
                    Image("add 2")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 40 * scaleX, height: 40 * scaleY)
                }
                .offset(x: (939 - 894) * scaleX, y: (155 - 89) * scaleY)
                
                // 钻石数值（Figma: x: 980, y: 122）- 横向排列，不换行
                Text("\(viewModel.diamonds)")
                    .font(customFont(size: 50 * scaleX))
                    .foregroundColor(.white)
                    .textStroke()
                    .lineLimit(1)
                    .frame(width: 164 * scaleX, alignment: .leading)
                    .offset(x: (980 - 894) * scaleX, y: (122 - 89) * scaleY)
            }
        }
    }
}

#Preview {
    HomeView(viewModel: GameViewModel())
}
