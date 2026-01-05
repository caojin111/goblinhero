//
//  HomeView.swift
//  A004
//
//  游戏首页
//

import SwiftUI
import UIKit
import CoreMotion

// 用于标识要打开的商城标签页
struct StoreTabIdentifier: Identifiable {
    let id = UUID()
    let tab: PaidStoreView.StoreTab
}

struct HomeView: View {
    @ObservedObject var viewModel: GameViewModel
    @ObservedObject var localizationManager = LocalizationManager.shared
    @ObservedObject var audioManager = AudioManager.shared
    @State private var showGoblinSelection = false
    @State private var storeTabIdentifier: StoreTabIdentifier? = nil
    @State private var showDailySignIn = false
    @State private var showSettings = false
    @State private var showTutorial = false
    @State private var showGoblinRecord = false
    @State private var shakeOffset: CGFloat = 0 // 抖动偏移量
    @State private var shakeTimer: Timer? // 抖动定时器
    @State private var triggerEmoji1: Bool = false // 触发哥布林显示emoji1
    @State private var motionManager: CMMotionManager? // 运动管理器
    @State private var lastShakeTime: Date = Date() // 上次抖动时间，防止频繁触发
    
    // 检测是否为iPad（每次访问时重新计算，确保在所有iOS版本上都能正确工作）
    private var isPad: Bool {
        let detected = UIDevice.current.userInterfaceIdiom == .pad
        return detected
    }
    
    // 检查是否需要显示教程
    private var shouldShowTutorial: Bool {
        // iPad 上不显示新手引导
        if isPad {
            print("📱 [HomeView] 检测到 iPad 设备，跳过新手引导")
            return false
        }
        return !UserDefaults.standard.bool(forKey: "hasCompletedTutorial")
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
                .overlay {
                    // 云朵（作为背景图的overlay，独立层级，可以点击）
                    CloudView()
                        .allowsHitTesting(true) // 允许点击事件
                }
            
            GeometryReader { geometry in
                // 检测是否为标准iPad或Pro（需要缩放至70%）
                let isPad = UIDevice.current.userInterfaceIdiom == .pad
                let screenWidth = UIScreen.main.bounds.width
                let screenHeight = UIScreen.main.bounds.height
                // 判断是否是标准iPad或Pro（横屏时宽度>=1024，竖屏时高度>1024）
                // iPad Air/Mini: 1024点（竖屏）或768点（横屏）
                // iPad Pro/标准iPad: 屏幕更大
                let needsScaling = isPad && (screenHeight > 1024 || screenWidth >= 1024)
                let deviceScale: CGFloat = needsScaling ? 0.7 : 1.0 // 标准iPad/Pro缩小到70%
                
                // 打印调试信息
                // 计算缩放比例
                
                // 使用比例定位，而不是绝对坐标
                let scaleX = geometry.size.width / figmaWidth
                let scaleY = geometry.size.height / figmaHeight
                
                // 在GeometryReader中直接计算isPad，确保在iOS 26.0.1上也能正确工作
                let currentIsPad = UIDevice.current.userInterfaceIdiom == .pad
                
                // 打印字体大小用于调试
                let _ = print("🔤 [首页字体] scaleX: \(scaleX), settings/shop/sign-in 字体大小: \(53 * scaleX)")
                
                ZStack {
                    // 顶部左侧：哥布林信息区域
                    // Main_menu 1 背景（Figma: x: 37, y: 76, 485.01 x 251.44）- 已移除，用透明占位保持布局
                    Button(action: {
                        print("👤 [首页] 点击头像区域")
                        audioManager.playSoundEffect("click", fileExtension: "wav")
                        showGoblinRecord = true
                    }) {
                        ZStack(alignment: .topLeading) {
                            // 透明占位，保持原有布局结构
                            Color.clear
                                .frame(width: 485.01 * scaleX, height: 251.44 * scaleY)
                            
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
                            VStack(alignment: .leading, spacing: 4 * scaleY) {
                                Text(localizationManager.localized("home.goblin"))
                                    .font(customFont(size: 62 * scaleX)) // 从 57 增加到 62（+5）
                                    .foregroundColor(.white)
                                    .textStroke()
                                
                                // 玩家昵称（如果有）
                                if !viewModel.playerName.isEmpty {
                                    Text(viewModel.playerName)
                                        .font(customFont(size: 40 * scaleX))
                                        .foregroundColor(.white.opacity(0.9))
                                        .textStroke()
                                }
                            }
                            .offset(x: (237 - 37) * scaleX, y: (112 - 76 - 30) * scaleY) // 上移30像素
                        }
                    }
                    .buttonStyle(PlainButtonStyle()) // 使用PlainButtonStyle避免默认样式
                    .frame(width: 485.01 * scaleX, height: 251.44 * scaleY)
                    .position(
                        x: (37 + 485.01/2) * scaleX,
                        y: (76 + 251.44/2) * scaleY + 60 + (currentIsPad ? 100 : 0) // iPad向下移动100像素
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
                        y: (90 + 127/2) * scaleY + 60 + (currentIsPad ? 100 : 0) // iPad向下移动100像素
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
                        y: (89 + 127/2) * scaleY + 60 + (currentIsPad ? 100 : 0) // iPad向下移动100像素
                    )
                    
                    // Achievement 按钮
                    AchievementButtonView()
                        .frame(width: 140 * scaleX, height: 100 * scaleY)
                        .offset(x: -10 * scaleX) // Achievement按钮单独左移30像素
                        .position(
                            x: geometry.size.width - (figmaWidth - 894 - 288/2) * scaleX - 40 * scaleX - 20 * scaleX + 80 * scaleX, // 统一右移80像素（50+30）
                            y: (89 + 127 + 50) * scaleY + 60 + 10 * scaleY + (currentIsPad ? 100 : 0) // iPad向下移动100像素
                        )
                    
                    // Rank 按钮（放在 Achievement 按钮正下方）
                    RankButtonView()
                        .frame(width: 140 * scaleX, height: 100 * scaleY)
                        .offset(x: -40 * scaleX, y: 4 * scaleY) // Rank按钮单独左移40像素，下移4像素
                        .position(
                            x: geometry.size.width - (figmaWidth - 894 - 288/2) * scaleX - 40 * scaleX - 20 * scaleX + 118 * scaleX, // 统一右移118像素（88+30）
                            y: (89 + 127 + 50) * scaleY + 60 + 10 * scaleY + 100 * scaleY + 20 * scaleY + 60 * scaleY + (currentIsPad ? 100 : 0) // iPad向下移动100像素
                    )
                    
                    // 中间：哥布林的家（Figma: x: 50, y: 609, 1102 x 1121）
                    Image("house")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: min(1102 * scaleX, geometry.size.width * 0.9), height: min(1121 * scaleY, geometry.size.height * 0.5))
                        .offset(x: shakeOffset) // 抖动效果
                        .position(
                            x: geometry.size.width / 2,
                            y: (609 + 1121/2) * scaleY
                        )
                        .onTapGesture {
                            print("🏠 [首页] 点击房子")
                            triggerHouseShake()
                        }
                    
                    // Start 按钮（Figma: x: 344, y: 1802, 503 x 263）
                    Button(action: {
                        // 播放 start 按钮音效
                        audioManager.playSoundEffect("start", fileExtension: "wav")
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
                            
                            Text(localizationManager.localized("home.start"))
                                .font(customFont(size: 95 * scaleX)) // 从83增加到88（+5）
                                .foregroundColor(.white)
                                .textStroke()
                                .offset(y: -25 * scaleY) // 文本向上移动25像素（20+5）
                        }
                    }
                    .buttonStyle(ScaleButtonStyle())
                    .frame(width: min(503 * scaleX, geometry.size.width * 0.85), height: 263 * scaleY)
                    .position(
                        x: geometry.size.width / 2,
                        y: (1802 + 263/2) * scaleY - 43 // 从-13向上移动10像素到-23
                    )
                    
                    // 底部区域：蒙版背景 + 按钮 + 文本标签
                    ZStack {
                        // 底部菜单背景图（Figma: x: 0, y: 2314, 1202 x 308，向上移动 50 像素）
                        Image("menu")
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: figmaWidth * scaleX, height: 308 * scaleY)
                            .ignoresSafeArea(.container, edges: .bottom) // 确保不被安全区域裁剪顶部
                            .position(
                                x: geometry.size.width / 2,
                                y: geometry.size.height - (figmaHeight - 2314 - 308/2) * scaleY - 50 - (currentIsPad ? 130 : 0) // iPad向上移动130像素
                            )
                            .clipped() // 将 clipped 移到 position 之后，避免裁剪顶部
                        
                        // settings 按钮图标（Figma: x: 194, y: 2363, 142 x 142）
                        // 注意：使用 settings 图片集（包含 gear 2.png）
                        Button(action: {
                            audioManager.playSoundEffect("click", fileExtension: "wav")
                            showSettings = true
                        }) {
                            Image("settings")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 142 * scaleX, height: 142 * scaleY)
                        }
                        .buttonStyle(ScaleButtonStyle())
                        .position(
                            x: (194 + 142/2) * scaleX,
                            y: geometry.size.height - (figmaHeight - 2363 - 142/2) * scaleY - 55 - (currentIsPad ? 130 : 0) // iPad向上移动130像素
                        )
                        
                        // shop 按钮图标（Figma: x: 529, y: 2363, 142 x 142）
                        // 注意：使用 shop 图片集（包含 fc16 2.png）
                        Button(action: {
                            audioManager.playSoundEffect("click", fileExtension: "wav")
                            storeTabIdentifier = StoreTabIdentifier(tab: .goblins)
                        }) {
                            ZStack(alignment: .topTrailing) {
                                Image("shop")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 142 * scaleX, height: 142 * scaleY)
                                
                                // 小红点提示（如果钻石宝箱未领取）
                                if viewModel.canClaimFreeDiamonds {
                                    Image("reddot")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 60 * scaleX, height: 60 * scaleY)
                                        .offset(x: 5 * scaleX, y: -5 * scaleY)
                                }
                            }
                        }
                        .buttonStyle(ScaleButtonStyle())
                        .position(
                            x: (529 + 142/2) * scaleX,
                            y: geometry.size.height - (figmaHeight - 2363 - 142/2) * scaleY - 55 - (currentIsPad ? 130 : 0) // iPad向上移动130像素
                        )
                        
                        // gift 按钮图标（Figma: x: 883, y: 2363, 142 x 142）
                        // 注意：使用 gift 图片集（包含 gift_01d 1.png）
                        Button(action: {
                            audioManager.playSoundEffect("click", fileExtension: "wav")
                            showDailySignIn = true
                        }) {
                            Image("gift")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 142 * scaleX, height: 142 * scaleY)
                        }
                        .buttonStyle(ScaleButtonStyle())
                        .position(
                            x: (883 + 142/2) * scaleX,
                            y: geometry.size.height - (figmaHeight - 2363 - 142/2) * scaleY - 55 - (currentIsPad ? 130 : 0) // iPad向上移动130像素
                        )
                        
                        // "settings" 文本标签（Figma: x: 163, y: 2522, 210 x 69）
                        Text(localizationManager.localized("home.settings"))
                            .font(customFont(size: (localizationManager.currentLanguage == "zh" ? 66 : 63) * scaleX)) // 中文66号，英文63号（66-3）
                            .foregroundColor(.white)
                            .textStroke()
                            .lineLimit(1)
                            .multilineTextAlignment(.center)
                            .position(
                                x: (163 + 210/2) * scaleX,
                                y: geometry.size.height - (figmaHeight - 2522 - 69/2) * scaleY - 55 - (currentIsPad ? 130 : 0) // iPad向上移动130像素
                            )
                        
                        // "shop" 文本标签（Figma: x: 549, y: 2522, 113 x 74）
                        Text(localizationManager.localized("home.shop"))
                            .font(customFont(size: (localizationManager.currentLanguage == "zh" ? 66 : 63) * scaleX)) // 中文66号，英文63号（66-3）
                            .foregroundColor(.white)
                            .textStroke()
                            .lineLimit(1)
                            .multilineTextAlignment(.center)
                            .position(
                                x: (549 + 113/2) * scaleX,
                                y: geometry.size.height - (figmaHeight - 2522 - 74/2) * scaleY - 55 - (currentIsPad ? 130 : 0) // iPad向上移动130像素
                            )
                        
                        // "sign-in" 文本标签（Figma: x: 869, y: 2525, 176 x 69）
                        Text(localizationManager.localized("home.sign_in"))
                            .font(customFont(size: (localizationManager.currentLanguage == "zh" ? 66 : 63) * scaleX)) // 中文66号，英文63号（66-3）
                            .foregroundColor(.white)
                            .textStroke()
                            .lineLimit(1)
                            .multilineTextAlignment(.center)
                            .position(
                                x: (869 + 176/2) * scaleX,
                                y: geometry.size.height - (figmaHeight - 2525 - 69/2) * scaleY - 55 - (currentIsPad ? 130 : 0) // iPad向上移动130像素
                            )
                    }
                    
                    // 哥布林待机动画（放在 ZStack 最后，确保层级最高）
                    // 位置待根据 Figma 调整，暂时放在房子前方
                    GoblinIdleAnimationView(triggerEmoji1: $triggerEmoji1)
                        .frame(width: 200 * scaleX * 5 / 3, height: 200 * scaleY * 5 / 3) // 缩小3倍（原来是5倍，现在除以3）
                        .offset(x: shakeOffset) // 跟随房子一起抖动
                        .position(
                            x: geometry.size.width / 2 - 80 * scaleX, // 向左移动 30 像素
                            y: (609 + 1121/2) * scaleY - 100 * scaleY + 300 * scaleY // 向下移动 50 像素
                        )
                        .zIndex(1000) // 确保层级最高
                }
                .scaleEffect(deviceScale) // 在标准iPad/Pro上应用50%缩放
                .frame(width: geometry.size.width, height: geometry.size.height) // 确保缩放后仍然居中
            }
        }
        .ignoresSafeArea(.all)
        // 哥布林选择弹窗（窗口式）
        .overlay {
            if showGoblinSelection {
                GoblinSelectionView(
                    selectedGoblin: $viewModel.selectedGoblin,
                    isPresented: $showGoblinSelection,
                    unlockedGoblinIds: $viewModel.unlockedGoblinIds,
                    currentCoins: $viewModel.currentCoins,
                    viewModel: viewModel,
                    onNavigateToStore: {
                        // 跳转到商店-哥布林分页
                        print("🏪 [首页] 收到跳转到商店-哥布林分页的回调")
                        storeTabIdentifier = StoreTabIdentifier(tab: .goblins)
                        print("🏪 [首页] storeTabIdentifier已设置: \(storeTabIdentifier?.tab.rawValue ?? "nil")")
                    }
                )
                .transition(.scale.combined(with: .opacity))
                .zIndex(1000)
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: showGoblinSelection)
        .onChange(of: viewModel.selectedGoblin) { goblin in
            if goblin != nil {
                viewModel.onGoblinSelected()
            }
        }
        // 付费商城弹窗
        .sheet(item: $storeTabIdentifier) { identifier in
            let isPad = UIDevice.current.userInterfaceIdiom == .pad
            let screenWidth = UIScreen.main.bounds.width
            let screenHeight = UIScreen.main.bounds.height
            let needsScaling = isPad && (screenHeight > 1024 || screenWidth >= 1024)
            
            PaidStoreView(
                viewModel: viewModel,
                isPresented: Binding(
                    get: { storeTabIdentifier != nil },
                    set: { if !$0 { storeTabIdentifier = nil } }
                ),
                initialTab: identifier.tab
            )
            .presentationCornerRadius(10) // 设置顶部圆角，可根据需要调整数值
            .presentationDetents([.large]) // 所有设备都使用全屏（下拉抽屉式）
        }
        // 七日签到弹窗（普通弹窗，非抽屉式）
        .overlay {
            if showDailySignIn {
                DailySignInView(viewModel: viewModel, isPresented: $showDailySignIn)
                    .zIndex(1000)
            }
        }
        // 设置弹窗（首页设置）
        .onAppear {
            // 更新钻石宝箱状态，确保红点正确显示
            viewModel.updateFreeDiamondsClaimStatus()
        }
        .overlay {
            if showSettings {
                HomeSettingsView(isPresented: $showSettings, viewModel: viewModel)
            }
        }
        // 哥布林记录弹窗
        .overlay {
            if showGoblinRecord {
                GoblinRecordView(
                    viewModel: viewModel,
                    isPresented: $showGoblinRecord
                )
                .zIndex(1000)
            }
        }
        // 新手教程
        .overlay {
            if showTutorial {
                TutorialView(
                    viewModel: viewModel,
                    isPresented: $showTutorial,
                    steps: createTutorialSteps()
                )
                .allowsHitTesting(true)
                .zIndex(1000)
            }
        }
        // 玩家昵称输入弹窗
        .overlay {
            if viewModel.showPlayerNameInput {
                PlayerNameInputView(
                    viewModel: viewModel,
                    isPresented: $viewModel.showPlayerNameInput
                )
                .zIndex(1000)
            }
        }
        .onAppear {
            // 打印设备类型用于调试
            let detectedIsPad = UIDevice.current.userInterfaceIdiom == .pad
            print("📱 [HomeView] 视图出现，检测到设备类型: \(detectedIsPad ? "iPad" : "iPhone"), isPad计算属性值: \(isPad)")
            
            print("🏠 [HomeView] 视图出现，准备播放首页背景音乐")
            // 播放首页背景音乐
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                audioManager.playBackgroundMusic(fileName: "homepage", fileExtension: "mp3")
            }
            if shouldShowTutorial {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    showTutorial = true
                }
            } else {
                // iPad上不显示教程，但需要检查是否需要显示昵称输入
                // 如果教程已完成（或iPad跳过教程）且玩家名字为空，显示昵称输入
                let hasCompletedTutorial = UserDefaults.standard.bool(forKey: "hasCompletedTutorial")
                if (hasCompletedTutorial || isPad) && viewModel.playerName.isEmpty {
                    print("👤 [名字输入] iPad或教程已完成，名字为空，显示名字输入弹窗")
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        viewModel.showPlayerNameInput = true
                    }
                }
            }
        }
        .onDisappear {
            print("🏠 [HomeView] 视图消失，停止首页背景音乐")
            // 停止首页背景音乐
            audioManager.stopMusic()
        }
        .onChange(of: viewModel.goblinSelectionCompleted) { completed in
            // 当退出游戏返回首页时，播放首页背景音乐
            if !completed {
                print("🏠 [HomeView] 游戏退出（onChange），播放首页背景音乐")
                // 延迟播放首页背景音乐，确保视图切换完成
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    print("🏠 [HomeView] 开始播放首页背景音乐")
                    audioManager.playBackgroundMusic(fileName: "homepage", fileExtension: "mp3")
                }
            }
        }
        .onChange(of: showSettings) { isShowing in
            // 当设置弹窗关闭时，如果已返回首页，确保播放背景音乐
            if !isShowing && !viewModel.goblinSelectionCompleted {
                print("🏠 [HomeView] 设置弹窗关闭，确保播放首页背景音乐")
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    audioManager.playBackgroundMusic(fileName: "homepage", fileExtension: "mp3")
                }
            }
        }
    }
    
    /// 触发房子抖动效果
    private func triggerHouseShake() {
        print("🏠 [首页] 触发房子抖动效果")
        // 停止之前的抖动定时器
        shakeTimer?.invalidate()
        
        // 播放音效
        audioManager.playSoundEffect("earth", fileExtension: "wav")
        audioManager.playSoundEffect("shake", fileExtension: "wav")
        
        // 触发哥布林显示emoji1
        triggerEmoji1 = true
        
        // 抖动参数
        let shakeDuration: TimeInterval = 0.5 // 抖动持续时间
        let shakeIntensity: CGFloat = 10 // 抖动强度
        let shakeCount: Int = 6 // 抖动次数
        
        var currentShake = 0
        shakeTimer = Timer.scheduledTimer(withTimeInterval: shakeDuration / Double(shakeCount), repeats: true) { timer in
            currentShake += 1
            
            // 交替抖动方向
            let direction: CGFloat = currentShake % 2 == 0 ? 1 : -1
            self.shakeOffset = direction * shakeIntensity
            
            // 抖动完成后重置
            if currentShake >= shakeCount {
                timer.invalidate()
                self.shakeTimer = nil
                withAnimation(.easeOut(duration: 0.1)) {
                    self.shakeOffset = 0
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
        
        // Start按钮位置（Figma: x: 344, y: 1802, width: 503, height: 263）
        // 实际位置：x: screenWidth / 2, y: (1802 + 263/2) * scaleY - 43
        let startButtonWidth = min(503 * scaleX, screenWidth * 0.85)
        let startButtonHeight = 263 * scaleY
        let startButtonCenterX = screenWidth / 2
        let startButtonCenterY = (1802 + 263/2) * scaleY - 43
        
        // Shop按钮位置（Figma: x: 529, y: 2363, width: 142, height: 142）
        // 实际位置：x: (529 + 142/2) * scaleX, y: screenHeight - (figmaHeight - 2363 - 142/2) * scaleY - 55
        let shopButtonWidth = 142 * scaleX
        let shopButtonHeight = 142 * scaleY
        let shopButtonCenterX = (529 + 142/2) * scaleX
        let shopButtonCenterY = screenHeight - (figmaHeight - 2363 - 142/2) * scaleY - 55
        
        // Sign-in按钮位置（7日签到，Figma: x: 883, y: 2363, width: 142, height: 142）
        // 实际位置：x: (883 + 142/2) * scaleX, y: screenHeight - (figmaHeight - 2363 - 142/2) * scaleY - 55
        let signInButtonWidth = 142 * scaleX
        let signInButtonHeight = 142 * scaleY
        let signInButtonCenterX = (883 + 142/2) * scaleX
        let signInButtonCenterY = screenHeight - (figmaHeight - 2363 - 142/2) * scaleY - 55
        
        // 统一的圆角半径
        let cornerRadius: CGFloat = 25
        
        // 打印调试信息
        print("📚 [新手引导] Start按钮: center(\(startButtonCenterX), \(startButtonCenterY)), size(\(startButtonWidth), \(startButtonHeight))")
        print("📚 [新手引导] Shop按钮: center(\(shopButtonCenterX), \(shopButtonCenterY)), size(\(shopButtonWidth), \(shopButtonHeight))")
        print("📚 [新手引导] Sign-in按钮: center(\(signInButtonCenterX), \(signInButtonCenterY)), size(\(signInButtonWidth), \(signInButtonHeight))")
        
        // 创建高亮区域（使用中心点和尺寸）
        // 第一步：向下移动 50 + 100 = 150 像素
        let startHighlightFrame = CGRect(
            x: startButtonCenterX - startButtonWidth / 2,
            y: startButtonCenterY - startButtonHeight / 2 + 150 * scaleY, // 向下移动 150 像素（50 + 100）
            width: startButtonWidth,
            height: startButtonHeight
        )
        // 第二步：扩大两倍，向下移动 150 + 100 = 250 像素
        let shopHighlightFrame = CGRect(
            x: shopButtonCenterX - shopButtonWidth, // 扩大两倍：宽度从 shopButtonWidth/2 改为 shopButtonWidth
            y: shopButtonCenterY - shopButtonHeight + 250 * scaleY, // 扩大两倍：高度从 shopButtonHeight/2 改为 shopButtonHeight，向下移动 250 像素（150 + 100）
            width: shopButtonWidth * 2, // 扩大两倍
            height: shopButtonHeight * 2 // 扩大两倍
        )
        // 第三步：扩大两倍，向下移动 150 + 100 = 250 像素
        let signInHighlightFrame = CGRect(
            x: signInButtonCenterX - signInButtonWidth, // 扩大两倍：宽度从 signInButtonWidth/2 改为 signInButtonWidth
            y: signInButtonCenterY - signInButtonHeight + 250 * scaleY, // 扩大两倍：高度从 signInButtonHeight/2 改为 signInButtonHeight，向下移动 250 像素（150 + 100）
            width: signInButtonWidth * 2, // 扩大两倍
            height: signInButtonHeight * 2 // 扩大两倍
        )
        
        print("📚 [新手引导] Start高亮区域: \(startHighlightFrame)")
        print("📚 [新手引导] Shop高亮区域: \(shopHighlightFrame)")
        print("📚 [新手引导] Sign-in高亮区域: \(signInHighlightFrame)")
        
        return [
            // 第一步：聚焦Start按钮
            TutorialStep(
                title: "tutorial.step1.title",
                description: "tutorial.step1.description",
                highlightFrame: startHighlightFrame,
                highlightCornerRadius: cornerRadius,
                arrowPosition: CGPoint(x: 0, y: -80 * scaleY),
                arrowDirection: .down,
                arrowOffset: 0
            ),
            // 第二步：聚焦Shop按钮
            TutorialStep(
                title: "tutorial.step2.title",
                description: "tutorial.step2.description",
                highlightFrame: shopHighlightFrame,
                highlightCornerRadius: cornerRadius,
                arrowPosition: CGPoint(x: 0, y: 50 * scaleY),
                arrowDirection: .up,
                arrowOffset: 0
            ),
            // 第三步：聚焦7日签到按钮
            TutorialStep(
                title: "tutorial.step3.title",
                description: "tutorial.step3.description",
                highlightFrame: signInHighlightFrame,
                highlightCornerRadius: cornerRadius,
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
    @ObservedObject var localizationManager = LocalizationManager.shared
    
    // 获取自定义字体
    private func customFont(size: CGFloat) -> Font {
        return FontManager.shared.customFont(size: size)
    }
    
    var body: some View {
        GeometryReader { geometry in
            let scaleX = geometry.size.width / 289
            let scaleY = geometry.size.height / 127
            
            Button(action: onShowStore) {
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
                    Image("add 2")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 40 * scaleX, height: 40 * scaleY)
                        .offset(x: (644 - 591) * scaleX, y: (151 - 90) * scaleY)
                    
                    // 体力数值（Figma: x: 677, y: 124）- 横向排列，不换行
                    Text("\(viewModel.stamina)/\(viewModel.maxStamina)")
                        .font(customFont(size: (localizationManager.currentLanguage == "zh" ? 42 : 47) * scaleX)) // 中文42号，英文47号（50-3）
                        .foregroundColor(.white)
                        .textStroke()
                        .lineLimit(1)
                        .fixedSize(horizontal: true, vertical: false) // 防止省略号，水平方向自适应
                        .frame(minWidth: 175 * scaleX, alignment: .leading) // 向右扩展10像素（165+10=175）
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
            .buttonStyle(PlainButtonStyle())
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
            
            Button(action: onShowStore) {
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
                    Image("add 2")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 40 * scaleX, height: 40 * scaleY)
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
            .buttonStyle(PlainButtonStyle())
        }
    }
}

// MARK: - Rank 按钮视图
struct RankButtonView: View {
    @ObservedObject var localizationManager = LocalizationManager.shared
    
    // 获取自定义字体
    private func customFont(size: CGFloat) -> Font {
        return FontManager.shared.customFont(size: size)
    }
    
    var body: some View {
        GeometryReader { geometry in
            let scaleX = geometry.size.width / 288
            let scaleY = geometry.size.height / 100
            
            Button(action: {
                audioManager.playSoundEffect("click", fileExtension: "wav")
                // 直接显示 Game Center 界面，不使用 sheet
                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                   let rootViewController = windowScene.windows.first?.rootViewController {
                    GameCenterManager.shared.showLeaderboard(from: rootViewController)
                }
            }) {
                VStack(spacing: 8 * scaleY) {
                    // Rank 图标（放大 2 倍）
                    Image("rank")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 300 * min(scaleX, scaleY), height: 300 * min(scaleX, scaleY))
                    
                    // Rank 文字标题（放大 2 倍，使用多语言）
                    Text(localizationManager.localized("home.rank"))
                        .font(customFont(size: (localizationManager.currentLanguage == "zh" ? 95 : 97) * scaleX)) // 中文95号（100-5），英文97号（100-3）
                        .foregroundColor(.white)
                        .textStroke()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .buttonStyle(ScaleButtonStyle())
        }
    }
    
    @ObservedObject private var audioManager = AudioManager.shared
}

// MARK: - Achievement 按钮视图
struct AchievementButtonView: View {
    @ObservedObject var localizationManager = LocalizationManager.shared
    
    // 获取自定义字体
    private func customFont(size: CGFloat) -> Font {
        return FontManager.shared.customFont(size: size)
    }
    
    var body: some View {
        GeometryReader { geometry in
            let scaleX = geometry.size.width / 140
            let scaleY = geometry.size.height / 100
            
            Button(action: {
                audioManager.playSoundEffect("click", fileExtension: "wav")
                // 直接显示 Game Center 成就界面
                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                   let rootViewController = windowScene.windows.first?.rootViewController {
                    GameCenterManager.shared.showAchievements(from: rootViewController)
                }
            }) {
                VStack(spacing: 8 * scaleY) {
                    // Achievement 图标
                    Image("achievement")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 150 * min(scaleX, scaleY), height: 150 * min(scaleX, scaleY))
                    
                    // Achievement 文字标题（使用多语言，向右扩展 10 像素）
                    Text(localizationManager.localized("home.achievement"))
                        .font(customFont(size: (localizationManager.currentLanguage == "zh" ? 48 : 45) * scaleX)) // 中文48号，英文45号（48-3）
                        .foregroundColor(.white)
                        .textStroke()
                        .lineLimit(1)
                        .fixedSize(horizontal: true, vertical: false) // 防止省略号，水平方向自适应
                        .frame(minWidth: (geometry.size.width + 10 * scaleX), alignment: .center) // 向右扩展 10 像素
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .buttonStyle(ScaleButtonStyle())
        }
    }
    
    @ObservedObject private var audioManager = AudioManager.shared
}

// MARK: - 云朵视图
struct CloudView: View {
    @State private var offsetX: CGFloat = 0
    @State private var breathingScale: CGFloat = 1.0
    @State private var tapScale: CGFloat = 1.0 // 点击缩放效果
    @State private var animationTimer: Timer?
    
    // Figma 设计稿尺寸：1202 x 2622
    private let figmaWidth: CGFloat = 1202
    private let figmaHeight: CGFloat = 2622
    
    var body: some View {
        GeometryReader { geometry in
            let scaleX = geometry.size.width / figmaWidth
            let scaleY = geometry.size.height / figmaHeight
            
            // 成就按钮的位置（用于确定云朵的Y坐标）
            let achievementY = (89 + 127 + 50) * scaleY + 60 + 10 * scaleY
            let cloudWidth = 400 * scaleX // 变大一倍：从 200 改为 400
            let cloudHeight = 240 * scaleY // 变大一倍：从 120 改为 240
            
            // 云朵从屏幕右侧外开始，移动到左侧外
            // 使用ZStack包装，确保点击区域正确
            ZStack {
                Image("cloud")
                    .resizable()
                    .scaledToFit()
                    .frame(width: cloudWidth, height: cloudHeight)
                    .scaleEffect(breathingScale * tapScale) // 呼吸效果 + 点击缩放效果
            }
            .frame(width: cloudWidth * 1.5, height: cloudHeight * 1.5) // 扩大点击区域
            .contentShape(Rectangle()) // 确保整个区域可点击
            .offset(x: offsetX) // 移动偏移
            .position(
                x: geometry.size.width + cloudWidth / 2, // 初始位置：屏幕右侧外
                y: achievementY // 与成就按钮相同的Y坐标
            )
            .onTapGesture {
                print("☁️ [首页] 点击云朵")
                let audioManager = AudioManager.shared
                audioManager.playSoundEffect("talk", fileExtension: "mp3")
                
                // 1.5x缩放效果
                withAnimation(.spring(response: 0.2, dampingFraction: 0.6)) {
                    tapScale = 1.5
                }
                
                // 恢复缩放
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    withAnimation(.spring(response: 0.2, dampingFraction: 0.6)) {
                        tapScale = 1.0
                    }
                }
            }
                .onAppear {
                    startAnimations(screenWidth: geometry.size.width, scaleX: scaleX)
                }
                .onDisappear {
                    stopAnimations()
                }
        }
        .ignoresSafeArea(.all)
    }
    
    private func startAnimations(screenWidth: CGFloat, scaleX: CGFloat) {
        // 呼吸效果：1.0 到 1.15，周期 4 秒（增强呼吸动效）
        withAnimation(.easeInOut(duration: 4.0).repeatForever(autoreverses: true)) {
            breathingScale = 1.15
        }
        
        // 移动动画：从右侧外移动到左侧外，速度缓慢（120秒完成一次循环，速度再慢一倍）
        let cloudWidth = 400 * scaleX // 变大一倍：从 200 改为 400
        let totalDistance = screenWidth + cloudWidth + 200 // 屏幕宽度 + 云朵宽度 + 边距
        
        // 使用 Timer 实现平滑的循环移动
        var currentOffset: CGFloat = 0
        let stepInterval: TimeInterval = 0.05 // 每0.05秒更新一次，更流畅
        let stepDistance = totalDistance / (120.0 / stepInterval) // 120秒内完成移动（速度再慢一倍：从60秒改为120秒）
        
        animationTimer = Timer.scheduledTimer(withTimeInterval: stepInterval, repeats: true) { timer in
            currentOffset -= stepDistance
            DispatchQueue.main.async {
                withAnimation(.linear(duration: stepInterval)) {
                    self.offsetX = currentOffset
                }
            }
            
            // 当云朵完全移出屏幕左侧时，重置到右侧（无动画，瞬间重置）
            if currentOffset <= -totalDistance {
                currentOffset = 0
                DispatchQueue.main.async {
                    self.offsetX = 0
                }
            }
        }
        
        // 将定时器添加到 common mode，确保在滚动等操作时也能正常运行
        if let timer = animationTimer {
            RunLoop.current.add(timer, forMode: .common)
        }
    }
    
    private func stopAnimations() {
        animationTimer?.invalidate()
        animationTimer = nil
    }
}

#Preview {
    HomeView(viewModel: GameViewModel())
}
