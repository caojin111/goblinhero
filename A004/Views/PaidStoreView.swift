//
//  PaidStoreView.swift
//  A004
//
//  付费商城界面
//

import SwiftUI

struct PaidStoreView: View {
    @ObservedObject var viewModel: GameViewModel
    @Binding var isPresented: Bool
    @ObservedObject var localizationManager = LocalizationManager.shared
    @ObservedObject var audioManager = AudioManager.shared
    
    var initialTab: StoreTab = .goblins
    @State private var selectedTab: StoreTab = .goblins
    @State private var showGoblinDetail: Bool = false
    @State private var selectedGoblinForDetail: Goblin?
    @State private var refreshTrigger: UUID = UUID() // 用于触发红点更新
    
    // 获取自定义字体
    private func customFont(size: CGFloat) -> Font {
        return FontManager.shared.customFont(size: size)
    }
    
    // Figma 设计稿尺寸：1202 x 2622
    private let figmaWidth: CGFloat = 1202
    private let figmaHeight: CGFloat = 2622
    
    init(viewModel: GameViewModel, isPresented: Binding<Bool>, initialTab: StoreTab = .goblins) {
        self.viewModel = viewModel
        self._isPresented = isPresented
        self.initialTab = initialTab
        self._selectedTab = State(initialValue: initialTab)
    }
    
    enum StoreTab: String, CaseIterable {
        case goblins = "goblins"
        case stamina = "stamina"
        case diamonds = "diamonds"
        
        func displayName(using manager: LocalizationManager) -> String {
            switch self {
            case .goblins:
                return manager.localized("store.tabs.goblins")
            case .stamina:
                return manager.localized("store.tabs.stamina")
            case .diamonds:
                return manager.localized("store.tabs.diamonds")
            }
        }
    }
    
    var body: some View {
        GeometryReader { geometry in
            let scaleX = geometry.size.width / figmaWidth
            let scaleY = geometry.size.height / figmaHeight
            
            ZStack {
                // 背景颜色（纯色8DBDB3）
                Color(hex: "8DBDB3")
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // 内容区域 - 优化切换性能
                    ScrollView {
                        VStack(spacing: 0) {
                            Group {
                                switch selectedTab {
                                case .goblins:
                                    GoblinsStoreView(
                                        viewModel: viewModel,
                                        localizationManager: localizationManager,
                                        showGoblinDetail: $showGoblinDetail,
                                        selectedGoblinForDetail: $selectedGoblinForDetail,
                                        scaleX: scaleX,
                                        scaleY: scaleY
                                    )
                                        .transition(.opacity)
                                case .stamina:
                                    StaminaStoreView(viewModel: viewModel, scaleX: scaleX, scaleY: scaleY)
                                        .transition(.opacity)
                                case .diamonds:
                                    DiamondsStoreView(viewModel: viewModel, refreshTrigger: refreshTrigger, scaleX: scaleX, scaleY: scaleY)
                                        .transition(.opacity)
                                }
                            }
                            .id(selectedTab.rawValue) // 使用id确保视图正确更新
                        }
                        .padding(.bottom, 270 * scaleY) // 为底部页签留出更多空间，避免穿帮（再增加50像素）
                    }
                    .animation(.easeInOut(duration: 0.15), value: selectedTab) // 快速切换动画
                }
                
                // 关闭按钮 - 放在最上层，不被遮挡
                VStack {
                    HStack {
                        Spacer()
                        
                        Button(action: {
                            print("🛒 [商店] 关闭商店")
                            audioManager.playSoundEffect("click", fileExtension: "wav")
                            isPresented = false
                        }) {
                            Image("Blue_Buttons")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 140 * scaleX, height: 140 * scaleY)
                        }
                        .padding(.trailing, selectedTab == .goblins ? (20 + 5) * scaleX : 20 * scaleX) // 哥布林分页向左移动5像素
                        .padding(.top, 20 * scaleY)
                    }
                    
                    Spacer()
                }
                
                // 底部区域：菜单背景图 + 页签按钮
                ZStack {
                    // 底部菜单背景图（Figma: x: 0, y: 2314, 1202 x 308，向上移动 50 像素，再下移 300 像素）
                    // 使用和首页完全一样的实现方式，确保背景图完全显示直至屏幕底部
                    Image("menu")
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: figmaWidth * scaleX, height: 308 * scaleY)
                        .ignoresSafeArea(.container, edges: .bottom) // 确保不被安全区域裁剪，延伸至屏幕底部
                        .position(
                            x: geometry.size.width / 2,
                            y: geometry.size.height - (figmaHeight - 2314 - 308/2) * scaleY - 50 + 300 * scaleY
                        )
                        // 不添加 clipped，确保背景图完全显示直至屏幕底部
                    
                    // 页签内容 - 显示在背景图上方，居中显示
                        HStack(spacing: 0) {
                            ForEach(StoreTab.allCases, id: \.self) { tab in
                                Button(action: {
                                    print("🛒 [商店] 切换到页签: \(tab.rawValue)")
                                    audioManager.playSoundEffect("click", fileExtension: "wav")
                                    // 立即更新状态，不使用动画避免延迟
                                    selectedTab = tab
                                }) {
                                    ZStack {
                                        // 背景图片 - 使用id确保正确更新，统一尺寸并裁剪
                                        Image(selectedTab == tab ? "selected" : "unselected")
                                            .resizable()
                                        .aspectRatio(contentMode: .fill) // 填充整个 frame
                                            .frame(maxWidth: .infinity) // 明确设置宽度
                                            .frame(height: 200 * scaleY) // 明确设置高度
                                            .clipped() // 裁剪超出部分，确保尺寸一致
                                        .scaleEffect(selectedTab == tab ? 1.0 / 1.1 : 1.0) // selected 按钮缩小 1.1 倍
                                            .id("tab_bg_\(tab.rawValue)_\(selectedTab == tab)") // 确保图片正确切换
                                        
                                        // 文字 (Figma: 字体大小 60) - 不使用描边以提升性能
                                        Text(tab.displayName(using: localizationManager))
                                            .font(customFont(size: 65 * scaleX)) // 从 60 增加到 65（+5）
                                            .foregroundColor(.white)
                                            .id("tab_text_\(tab.rawValue)_\(selectedTab == tab)") // 确保文字正确更新
                                    }
                                    .overlay(alignment: .topTrailing) {
                                        // 小红点提示（diamonds 页签，如果钻石宝箱未领取）- 使用overlay避免影响文本位置
                                        if tab == .diamonds && viewModel.canClaimFreeDiamonds {
                                            Image("reddot")
                                                .resizable()
                                                .scaledToFit()
                                                .frame(width: 60 * scaleX, height: 60 * scaleY)
                                                .offset(x: -10 * scaleX, y: 10 * scaleY)
                                        }
                                    }
                                    .id(refreshTrigger) // 使用 refreshTrigger 触发更新
                                    .frame(maxWidth: .infinity) // 确保所有页签宽度一致
                                    .frame(height: 200 * scaleY) // 确保所有页签高度一致
                                .clipped() // 在 ZStack 外层也添加 clipped，确保整体尺寸一致，防止图片溢出
                                    .contentShape(Rectangle())
                                    // 在选中哥布林分页时，钻石和体力页签向左移动20像素
                                    .offset(x: (selectedTab == .goblins && (tab == .diamonds || tab == .stamina)) ? -20 * scaleX : 0)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .frame(maxWidth: .infinity) // 确保页签填满宽度
                        .frame(height: 200 * scaleY) // 确保底部页签有足够高度
                    .scaleEffect(1.0 / 1.2) // 统一缩小 1.2 倍
                    .position(
                        x: geometry.size.width / 2,
                        y: geometry.size.height - (figmaHeight - 2314 - 308/2) * scaleY - 50 + 300 * scaleY - 30 * scaleY
                    )
                }
                .allowsHitTesting(true) // 确保页签可以点击，不参与滑动
                
                // 哥布林详情弹窗 - 在屏幕正中心显示（提升到PaidStoreView层级）
                if showGoblinDetail, let goblin = selectedGoblinForDetail {
                    ZStack {
                        // 背景遮罩，点击后关闭弹窗
                        Color.black.opacity(0.3)
                            .ignoresSafeArea()
                            .onTapGesture {
                                withAnimation {
                                    showGoblinDetail = false
                                }
                            }
                        
                        // 哥布林详情弹窗（使用和局内一样的样式）- 在屏幕正中心显示
                        GoblinBuffTipView(goblin: goblin, isDismissing: false)
                            .transition(.scale.combined(with: .opacity))
                            .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
                    }
                }
            }
        }
        .onAppear {
            print("🛒 [商店] 商店界面显示，初始页签: \(initialTab.rawValue)")
            selectedTab = initialTab
        }
        .onChange(of: isPresented) { newValue in
            if newValue {
                selectedTab = initialTab
            }
        }
    }
}

// MARK: - 哥布林商城视图
struct GoblinsStoreView: View {
    @ObservedObject var viewModel: GameViewModel
    @ObservedObject var localizationManager: LocalizationManager
    @ObservedObject var storeKitManager = StoreKitManager.shared
    @State private var showUnlockAlert: Bool = false
    @State private var goblinToUnlock: Goblin?
    @State private var showPurchaseSuccessAlert: Bool = false
    @State private var showPurchaseError: Bool = false
    @State private var purchaseErrorMessage: String = ""
    @State private var isPurchasing: Bool = false
    @Binding var showGoblinDetail: Bool
    @Binding var selectedGoblinForDetail: Goblin?
    let scaleX: CGFloat
    let scaleY: CGFloat
    
    // 获取自定义字体
    private func customFont(size: CGFloat) -> Font {
        return FontManager.shared.customFont(size: size)
    }
    
    // 获取需要解锁的哥布林（国王和巫师）
    var lockedGoblins: [Goblin] {
        Goblin.allGoblins.filter { goblin in
            !goblin.isFree && !viewModel.unlockedGoblinIds.contains(goblin.id)
        }
    }
    
    var body: some View {
        VStack(spacing: 40 * scaleY) {
            if lockedGoblins.isEmpty {
                VStack(spacing: 20 * scaleY) {
                    Text("✅")
                        .font(.system(size: 60 * scaleX))
                    Text(localizationManager.localized("store.goblins.all_unlocked"))
                        .font(customFont(size: 20 * scaleX))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 60 * scaleY)
            } else {
                ForEach(lockedGoblins) { goblin in
                    GoblinStoreCard(
                        goblin: goblin,
                        viewModel: viewModel,
                        scaleX: scaleX,
                        scaleY: scaleY,
                        onUnlock: {
                            print("🛒 [商店] 点击解锁哥布林: \(goblin.name)")
                            goblinToUnlock = goblin
                            showUnlockAlert = true
                        },
                        onShowDetail: {
                            print("🛒 [商店] 点击查看哥布林详情: \(goblin.name)")
                            selectedGoblinForDetail = goblin
                            showGoblinDetail = true
                        }
                    )
                }
            }
        }
        .padding(.horizontal, 40 * scaleX) // 还原原始布局
        .padding(.top, 40 * scaleY + 0) // 再向上移动30像素（从30改为0）
        .alert(localizationManager.localized("store.goblins.unlock_title"), isPresented: $showUnlockAlert) {
            if let goblin = goblinToUnlock {
                if goblin.unlockCurrency == "usd" {
                    // USD购买：显示确认按钮，实际购买通过StoreKit处理
                    Button(localizationManager.localized("confirmations.confirm")) {
                        guard let productId = goblin.productId else {
                            print("❌ [商店] 哥布林没有 productId: \(goblin.name)")
                            purchaseErrorMessage = localizationManager.localized("store.product_config_error")
                            showPurchaseError = true
                            return
                        }
                        
                        isPurchasing = true
                        Task {
                            let success = await storeKitManager.purchase(productId: productId)
                            isPurchasing = false
                            
                            if success {
                                // 购买成功，解锁哥布林
                                // 检查是否已经解锁（防止重复购买）
                                if !viewModel.unlockedGoblinIds.contains(goblin.id) {
                        if viewModel.unlockGoblin(goblinId: goblin.id, cost: 0) {
                            showPurchaseSuccessAlert = true
                                        print("✅ [商店] 成功购买并解锁哥布林: \(goblin.name)")
                                    } else {
                                        purchaseErrorMessage = localizationManager.localized("store.unlock_failed")
                                        showPurchaseError = true
                                    }
                                } else {
                                    // 已经解锁，显示成功提示
                                    showPurchaseSuccessAlert = true
                                    print("✅ [商店] 哥布林已解锁: \(goblin.name)")
                                }
                            } else {
                                // 购买失败
                                if let error = storeKitManager.purchaseError {
                                    purchaseErrorMessage = error
                                } else {
                                    purchaseErrorMessage = localizationManager.localized("store.purchase_failed")
                                }
                                showPurchaseError = true
                            }
                        }
                    }
                    .disabled(isPurchasing)
                    Button(localizationManager.localized("confirmations.cancel"), role: .cancel) { }
                } else {
                    // 钻石购买：检查钻石数量
                    if viewModel.diamonds >= goblin.unlockPrice {
                        Button(localizationManager.localized("confirmations.confirm")) {
                            if viewModel.unlockGoblin(goblinId: goblin.id, cost: goblin.unlockPrice) {
                                print("🛒 [商店] 成功解锁哥布林: \(goblin.name)")
                                showPurchaseSuccessAlert = true
                            }
                        }
                        Button(localizationManager.localized("confirmations.cancel"), role: .cancel) { }
                    } else {
                        Button(localizationManager.localized("confirmations.confirm"), role: .cancel) { }
                    }
                }
            }
        } message: {
            if let goblin = goblinToUnlock {
                if goblin.unlockCurrency == "usd" {
                    // USD购买：显示USD价格，去掉钻石emoji
                    let priceText = String(format: "$%.2f", Double(goblin.unlockPrice) / 100.0)
                    Text(localizationManager.localized("store.goblins.unlock_confirm_usd")
                        .replacingOccurrences(of: "{price}", with: priceText)
                        .replacingOccurrences(of: "{name}", with: goblin.name))
                } else {
                    // 钻石购买：检查钻石数量
                    if viewModel.diamonds >= goblin.unlockPrice {
                        Text(localizationManager.localized("store.goblins.unlock_message").replacingOccurrences(of: "{name}", with: goblin.name).replacingOccurrences(of: "{price}", with: "\(goblin.unlockPrice)"))
                    } else {
                        Text(localizationManager.localized("store.goblins.insufficient_diamonds").replacingOccurrences(of: "{price}", with: "\(goblin.unlockPrice)").replacingOccurrences(of: "{current}", with: "\(viewModel.diamonds)"))
                    }
                }
            }
        }
        .alert(localizationManager.localized("store.goblins.purchase_success"), isPresented: $showPurchaseSuccessAlert) {
            Button(localizationManager.localized("confirmations.confirm"), role: .cancel) { }
        }
        .alert(localizationManager.localized("store.purchase_failed"), isPresented: $showPurchaseError) {
            Button(localizationManager.localized("confirmations.confirm"), role: .cancel) { }
        } message: {
            Text(purchaseErrorMessage)
        }
        .overlay {
            if isPurchasing {
                ZStack {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                    VStack(spacing: 20) {
                        ProgressView()
                            .scaleEffect(1.5)
                        Text(localizationManager.localized("store.processing_purchase"))
                            .foregroundColor(.white)
                            .font(.headline)
                    }
                    .padding(30)
                    .background(Color.black.opacity(0.8))
                    .cornerRadius(15)
                }
            }
        }
    }
}

// MARK: - 哥布林商城卡片
struct GoblinStoreCard: View {
    let goblin: Goblin
    @ObservedObject var viewModel: GameViewModel
    let scaleX: CGFloat
    let scaleY: CGFloat
    let onUnlock: () -> Void
    let onShowDetail: () -> Void
    @ObservedObject var localizationManager = LocalizationManager.shared
    
    // 获取自定义字体
    private func customFont(size: CGFloat) -> Font {
        return FontManager.shared.customFont(size: size)
    }
    
    // 格式化哥布林价格显示
    private func formatGoblinPrice(_ price: Int, currency: String) -> String {
        if currency == "usd" {
            // USD价格：999 表示 9.99 美元（以分为单位）
            let dollars = Double(price) / 100.0
            return String(format: "$%.2f", dollars)
        } else {
            // 钻石或金币：直接显示数字
            return "\(price)"
        }
    }
    
    var body: some View {
        // 计算卡片宽度和高度（在 VStack 外部定义，确保作用域正确）
        // 巫师和国王使用相同的宽度（1109），保持一致
        let cardWidth = 1109 * scaleX
        // 根据新图片的宽高比（1094:729）计算高度
        let imageAspectRatio: CGFloat = 1094.0 / 729.0
        let cardHeight = cardWidth / imageAspectRatio
        let cornerRadius = 30 * scaleX
        
        return ZStack {
            VStack(spacing: 0) {
                // 标题栏 (Figma: x: 134, y: 168, width: 966, height: 114)
                // 名字条再往下移动 10 像素（更贴近商品卡片），整体再往下移动 8 像素（盖住价格条）
                Button(action: {
                    onShowDetail()
                }) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 20 * scaleX)
                            .fill(Color(hex: "E5D6A1"))
                            .frame(height: 114 * scaleY)
                        
                        Text(goblin.name)
                            .font(customFont(size: (localizationManager.currentLanguage == "zh" ? 85 : 100) * scaleX)) // 中文时减少15号（原95再减10）
                            .foregroundColor(.white)
                            .textStroke()
                    }
                }
                .buttonStyle(PlainButtonStyle())
                .zIndex(3) // 标题栏在最上层，优先响应点击
                .offset(y: (13 + 10 + 8) * scaleY) // 之前13 + 再往下10 + 整体再往下8 = 31 像素
                
                // 哥布林图片区域 - 新的一体化图片（分辨率：1094*729）
                // 图片宽度与购买按钮一致（即 cardWidth）
                // 整个图片区域可点击，显示详情（优先于购买按钮）
                // 商品卡片整体再往下移动 8 像素（盖住价格条）
                ZStack {
                    Button(action: {
                        onShowDetail()
                    }) {
                        ZStack {
                            // 哥布林一体化图片（包含角色、背景和文字）
                            if goblin.nameKey == "king_goblin" {
                                Image("king")
                                .resizable()
                                .scaledToFill()
                                .frame(width: cardWidth, height: cardHeight)
                                .clipShape(
                                    TopRoundedRectangle(cornerRadius: cornerRadius)
                                )
                            } else if goblin.nameKey == "wizard_goblin" {
                                Image("wizard")
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: cardWidth, height: cardHeight)
                                    .clipShape(
                                        TopRoundedRectangle(cornerRadius: cornerRadius)
                                    )
                            } else if goblin.nameKey == "athlete_goblin" {
                                Image("athlete")
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: cardWidth, height: cardHeight)
                                    .clipShape(
                                        TopRoundedRectangle(cornerRadius: cornerRadius)
                                    )
                            } else if goblin.nameKey == "craftsman_goblin" {
                                Image("craftsman")
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: cardWidth, height: cardHeight)
                                    .clipShape(
                                        TopRoundedRectangle(cornerRadius: cornerRadius)
                                    )
                            } else if goblin.nameKey == "gambler_goblin" {
                                Image("gambler")
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: cardWidth, height: cardHeight)
                                    .clipShape(
                                        TopRoundedRectangle(cornerRadius: cornerRadius)
                                    )
                            }
                        }
                        .frame(width: cardWidth, height: cardHeight)
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                }
                .zIndex(3) // 哥布林图片在最上层，优先响应点击
                .offset(y: (8 + 8) * scaleY) // 之前8 + 整体再往下8 = 16 像素，盖住价格条
                // 移除标题栏和图片之间的间距，让名字条和卡片紧贴
                
                // 价格栏 (Figma: height: 156) - 显示价格信息
                ZStack {
                    Image("goblin_card_button")
                        .resizable()
                        .scaledToFill()
                        .frame(width: cardWidth, height: 156 * scaleY)
                        .clipped()
                    
                    HStack(spacing: 20 * scaleX) {
                        if goblin.unlockCurrency == "usd" {
                            // USD价格：显示美元符号和格式化的价格
                            Text(formatGoblinPrice(goblin.unlockPrice, currency: goblin.unlockCurrency))
                                .font(customFont(size: 100 * scaleX))
                                .foregroundColor(.white)
                                .textStroke()
                        } else {
                            // 钻石价格：显示钻石图标和数量
                            Image("crystal")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 95 * scaleX, height: 95 * scaleY)
                            
                            Text("\(goblin.unlockPrice)")
                                .font(customFont(size: 100 * scaleX))
                                .foregroundColor(.white)
                                .textStroke()
                        }
                    }
                }
                .frame(width: cardWidth, height: 156 * scaleY)
                .zIndex(2) // 价格栏在上层，但低于标题和图片按钮
            }
            
            // 购买按钮 - 触摸区域包含整个卡片（包括商品卡片图标区域），但排除info按钮区域
            Button(action: {
                print("🛒 [商店] 点击购买哥布林: \(goblin.name), 价格: \(goblin.unlockPrice), 当前钻石: \(viewModel.diamonds)")
                onUnlock() // 始终调用，让alert来处理钻石不足的情况
            }) {
                Color.clear
                    .frame(width: cardWidth, height: cardHeight + 156 * scaleY)
                    .contentShape(Rectangle()) // 确保整个区域可点击
            }
            .buttonStyle(PlainButtonStyle())
            .zIndex(1) // 购买按钮在底层
            
            // Info 按钮 - 哥布林卡片右上角，独立处理，不被购买按钮遮挡
            VStack {
                HStack {
                    Spacer()
                    Button(action: {
                        print("🛒 [商店] 点击info按钮查看哥布林详情: \(goblin.name)")
                        onShowDetail()
                    }) {
                        Image("info")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 125 * scaleX, height: 125 * scaleY) // 再缩小1.2倍：150/1.2=125
                    }
                    .buttonStyle(PlainButtonStyle())
                    .padding(.top, 30 * scaleY) // 向下移动10像素：20+10=30
                    .padding(.trailing, 75 * scaleX) // 向左移动10像素：40-10=30
                }
                Spacer()
            }
            .zIndex(10) // Info按钮在最上层，确保可点击
            .allowsHitTesting(true) // 确保info按钮可以接收点击事件
        }
        .frame(width: cardWidth) // 确保整个卡片宽度一致
        .cornerRadius(20 * scaleX)
        .overlay(
            RoundedRectangle(cornerRadius: 20 * scaleX)
                .stroke(Color.clear, lineWidth: 0)
        )
        .shadow(color: .black.opacity(0.3), radius: 5, x: 0, y: 5) // 5像素外部投影
    }
}

// MARK: - 体力商城视图
struct StaminaStoreView: View {
    @ObservedObject var viewModel: GameViewModel
    @ObservedObject var localizationManager = LocalizationManager.shared
    @State private var showPurchaseAlert: Bool = false
    @State private var selectedStaminaPack: StaminaPack?
    @State private var showPurchaseSuccessAlert: Bool = false
    let scaleX: CGFloat
    let scaleY: CGFloat
    
    // 获取自定义字体
    private func customFont(size: CGFloat) -> Font {
        return FontManager.shared.customFont(size: size)
    }
    
    struct StaminaPack {
        let stamina: Int
        let diamonds: Int
        let titleKey: String // 标题键名
    }
    
    let staminaPacks: [StaminaPack] = [
        StaminaPack(stamina: 30, diamonds: 5, titleKey: "a_little_bit"),
        StaminaPack(stamina: 90, diamonds: 15, titleKey: "a_lot"),
        StaminaPack(stamina: 300, diamonds: 50, titleKey: "super_many")
    ]
    
    var body: some View {
        // 两列布局 - 根据Figma设计图
        VStack(spacing: 40 * scaleY) {
            // 第一行：前两个卡片
            HStack(spacing: 129 * scaleX) { // Figma间距：660 - 55 - 476 = 129
                if staminaPacks.count > 0 {
                    StaminaPackCard(
                        pack: staminaPacks[0],
                        viewModel: viewModel,
                        scaleX: scaleX,
                        scaleY: scaleY,
                        onPurchase: {
                            print("🛒 [商店] 点击购买体力包: \(staminaPacks[0].stamina)体力")
                            selectedStaminaPack = staminaPacks[0]
                            showPurchaseAlert = true
                        }
                    )
                }
                
                if staminaPacks.count > 1 {
                    StaminaPackCard(
                        pack: staminaPacks[1],
                        viewModel: viewModel,
                        scaleX: scaleX,
                        scaleY: scaleY,
                        onPurchase: {
                            print("🛒 [商店] 点击购买体力包: \(staminaPacks[1].stamina)体力")
                            selectedStaminaPack = staminaPacks[1]
                            showPurchaseAlert = true
                        }
                    )
                }
            }
            
            // 第二行：第三个卡片（如果有）
            if staminaPacks.count > 2 {
                HStack {
                    StaminaPackCard(
                        pack: staminaPacks[2],
                        viewModel: viewModel,
                        scaleX: scaleX,
                        scaleY: scaleY,
                        onPurchase: {
                            print("🛒 [商店] 点击购买体力包: \(staminaPacks[2].stamina)体力")
                            selectedStaminaPack = staminaPacks[2]
                            showPurchaseAlert = true
                        }
                    )
                    Spacer() // 让第三个卡片靠左对齐
                }
            }
        }
        .padding(.horizontal, 55 * scaleX) // Figma起始位置：x: 55
        .padding(.top, 40 * scaleY + 50) // 向下移动50像素，与哥布林分页一致
        .alert(localizationManager.localized("store.stamina.purchase_title"), isPresented: $showPurchaseAlert) {
            if let pack = selectedStaminaPack {
                if viewModel.diamonds >= pack.diamonds {
                    Button(localizationManager.localized("confirmations.confirm")) {
                        if viewModel.purchaseStamina(amount: pack.stamina, cost: pack.diamonds) {
                            print("🛒 [商店] 成功购买体力: \(pack.stamina)")
                            showPurchaseSuccessAlert = true
                        }
                    }
                    Button(localizationManager.localized("confirmations.cancel"), role: .cancel) { }
                } else {
                    Button(localizationManager.localized("confirmations.confirm"), role: .cancel) { }
                }
            }
        } message: {
            if let pack = selectedStaminaPack {
                if viewModel.diamonds >= pack.diamonds {
                    Text(localizationManager.localized("store.stamina.purchase_message").replacingOccurrences(of: "{stamina}", with: "\(pack.stamina)").replacingOccurrences(of: "{diamonds}", with: "\(pack.diamonds)"))
                } else {
                    Text(localizationManager.localized("store.stamina.insufficient_diamonds").replacingOccurrences(of: "{diamonds}", with: "\(pack.diamonds)").replacingOccurrences(of: "{current}", with: "\(viewModel.diamonds)"))
                }
            }
        }
        .alert(localizationManager.localized("store.goblins.purchase_success"), isPresented: $showPurchaseSuccessAlert) {
            Button(localizationManager.localized("confirmations.confirm"), role: .cancel) { }
        }
    }
}

// MARK: - 体力包卡片
struct StaminaPackCard: View {
    let pack: StaminaStoreView.StaminaPack
    @ObservedObject var viewModel: GameViewModel
    let scaleX: CGFloat
    let scaleY: CGFloat
    let onPurchase: () -> Void
    @ObservedObject var localizationManager = LocalizationManager.shared
    
    // 获取自定义字体
    private func customFont(size: CGFloat) -> Font {
        return FontManager.shared.customFont(size: size)
    }
    
    // 获取标题文本
    private func getTitle() -> String {
        if localizationManager.currentLanguage == "zh" {
            switch pack.titleKey {
            case "a_little_bit":
                return "少量\n体力"
            case "a_lot":
                return "大量\n体力"
            case "super_many":
                return "超级多\n体力"
            default:
                return "体力"
            }
        } else {
            switch pack.titleKey {
            case "a_little_bit":
                return "a little\nstamina"
            case "a_lot":
                return "a lot of\nstamina"
            case "super_many":
                return "many of\nstamina"
            default:
                return "stamina"
            }
        }
    }
    
    // 根据体力数量获取对应的图标
    private func getStaminaImageName() -> String {
        switch pack.stamina {
        case 30:
            return "stamina_1"
        case 90:
            return "stamina_2"
        case 300:
            return "stamina_3"
        default:
            return "fruit" // 默认图标
        }
    }
    
    var body: some View {
        // 卡片尺寸 (Figma: width: 476, height: 653+143+128=924)
        let cardWidth = 476 * scaleX
        let cardContentHeight = 653 * scaleY
        let titleHeight = 143 * scaleY
        let priceHeight = 128 * scaleY
        let cornerRadius = 30 * scaleX
        
        VStack(spacing: 0) {
            // 标题栏 (Figma: height: 143, 背景色 #E7A757)
            ZStack {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(Color(hex: "E7A757"))
                    .frame(height: titleHeight)
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .stroke(Color.clear, lineWidth: 0)
                    )
                    .mask(
                        TopRoundedRectangle(cornerRadius: cornerRadius)
                    )
                
                Text({
                    let title = getTitle().replacingOccurrences(of: "\n", with: " ")
                    // 如果是中文，移除空格；英文保留空格
                    return localizationManager.currentLanguage == "zh" ? title.replacingOccurrences(of: " ", with: "") : title
                }())
                    .font(customFont(size: (localizationManager.currentLanguage == "zh" ? 64 : 54) * scaleX))
                    .foregroundColor(Color(hex: "81331B")) // 标题字体色 #81331B
                    .multilineTextAlignment(.center)
                    .lineLimit(1) // 不换行
                    .minimumScaleFactor(0.5) // 自动缩小字体以适应宽度，避免省略号
                    .frame(width: localizationManager.currentLanguage == "zh" ? (cardWidth + 90 * scaleX) : (cardWidth + 100 * scaleX), height: titleHeight, alignment: .center) // 横向扩张（向右再扩张50像素）
            }
            
            // 内容区域 (Figma: height: 653, 背景色 #FDE9B4)
            ZStack {
                // 背景色
                Color(hex: "FDE9B4")
                    .frame(height: cardContentHeight)
                
                // 花纹蒙层（mask.png）- 覆盖在背景之上，文字与图片之下
                Image("mask")
                    .resizable()
                    .scaledToFill()
                    .frame(width: cardWidth, height: cardContentHeight)
                    .clipped()
                
                // 体力图标 - 根据体力数量显示对应的图标（放大3倍：2 * 1.5）
                VStack {
                    Spacer()
                    Image(getStaminaImageName())
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: 207 * 3 * scaleX, maxHeight: 137 * 3 * scaleY)
                        .padding(.bottom, 100 * scaleY) // 距离底部一定距离
                }
            }
            .frame(height: cardContentHeight)
            
            // 数量显示区域 (背景色与卡片统一 #FDE9B4)
            ZStack {
                RoundedRectangle(cornerRadius: 0)
                    .fill(Color(hex: "FDE9B4"))
                    .frame(height: 125 * scaleY)
                
                Text("x\(pack.stamina)")
                    .font(customFont(size: (localizationManager.currentLanguage == "zh" ? 100 : 77) * scaleX))
                    .foregroundColor(.white)
                    .textStroke()
            }
            
            // 价格栏 (Figma: height: 128, 购买按钮背景色 #FFC400)
            Button(action: {
                print("🛒 [商店] 点击购买体力包: \(pack.stamina)体力, 价格: \(pack.diamonds), 当前钻石: \(viewModel.diamonds)")
                onPurchase()
            }) {
                ZStack {
                    RoundedRectangle(cornerRadius: 0)
                        .fill(Color(hex: "FFC400"))
                        .frame(height: priceHeight)
                        .overlay(
                            RoundedRectangle(cornerRadius: cornerRadius)
                                .stroke(Color.clear, lineWidth: 0)
                        )
                        .mask(
                            BottomRoundedRectangle(cornerRadius: cornerRadius)
                        )
                    
                    HStack(spacing: 20 * scaleX) {
                        Image("crystal")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 95 * scaleX, height: 95 * scaleY)
                        
                        Text("\(pack.diamonds)")
                            .font(customFont(size: (localizationManager.currentLanguage == "zh" ? 100 : 75) * scaleX))
                            .foregroundColor(.white)
                            .textStroke()
                    }
                }
            }
            .buttonStyle(PlainButtonStyle())
        }
        .frame(width: cardWidth)
        .cornerRadius(cornerRadius)
        .overlay(
            RoundedRectangle(cornerRadius: cornerRadius)
                .stroke(Color(hex: "88520F"), lineWidth: 2 * scaleX) // 卡片描边 #88520F
        )
        .shadow(color: .black.opacity(0.3), radius: 5, x: 0, y: 5) // 5像素外部投影
        .offset(y: 10 * scaleY) // 整个卡片（包括标题区域和描边）下移 10 像素
    }
}

// MARK: - 底部圆角矩形形状
struct BottomRoundedRectangle: Shape {
    var cornerRadius: CGFloat
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        // 左上角
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        
        // 顶部直线
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        
        // 右上角
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - cornerRadius))
        
        // 右下角圆角
        path.addArc(center: CGPoint(x: rect.maxX - cornerRadius, y: rect.maxY - cornerRadius),
                   radius: cornerRadius,
                   startAngle: .degrees(0),
                   endAngle: .degrees(90),
                   clockwise: false)
        
        // 底部直线
        path.addLine(to: CGPoint(x: rect.minX + cornerRadius, y: rect.maxY))
        
        // 左下角圆角
        path.addArc(center: CGPoint(x: rect.minX + cornerRadius, y: rect.maxY - cornerRadius),
                   radius: cornerRadius,
                   startAngle: .degrees(90),
                   endAngle: .degrees(180),
                   clockwise: false)
        
        // 左侧直线
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        
        path.closeSubpath()
        return path
    }
}

// MARK: - 钻石商城视图
struct DiamondsStoreView: View {
    @ObservedObject var viewModel: GameViewModel
    @ObservedObject var localizationManager = LocalizationManager.shared
    @ObservedObject var storeKitManager = StoreKitManager.shared
    @State private var showPurchaseAlert: Bool = false
    @State private var selectedProduct: DiamondProduct?
    @State private var showRewardAlert: Bool = false
    @State private var rewardDiamonds: Int = 0
    @State private var showPurchaseSuccessAlert: Bool = false
    @State private var showPurchaseError: Bool = false
    @State private var purchaseErrorMessage: String = ""
    @State private var isPurchasing: Bool = false
    let refreshTrigger: UUID // 用于触发子视图刷新（从父视图传入）
    let scaleX: CGFloat
    let scaleY: CGFloat
    
    // 获取自定义字体
    private func customFont(size: CGFloat) -> Font {
        return FontManager.shared.customFont(size: size)
    }
    
    struct DiamondProduct: Identifiable {
        let id: String
        let productId: String? // StoreKit product identifier (nil for free daily)
        let type: ProductType
        let priceUSD: Double
        let diamonds: Int
        
        enum ProductType {
            case freeDaily
            case paid
        }
    }
    
    let products: [DiamondProduct] = [
        DiamondProduct(id: "free_daily", productId: nil, type: .freeDaily, priceUSD: 0.00, diamonds: 10),
        DiamondProduct(id: "pack_100", productId: "diamond_5.99", type: .paid, priceUSD: 5.99, diamonds: 100),
        DiamondProduct(id: "pack_150", productId: "diamond_9.99", type: .paid, priceUSD: 9.99, diamonds: 150),
        DiamondProduct(id: "pack_350", productId: "diamond_19.99", type: .paid, priceUSD: 19.99, diamonds: 350),
        DiamondProduct(id: "pack_600", productId: "diamond_29.99", type: .paid, priceUSD: 29.99, diamonds: 600)
    ]
    
    var body: some View {
        // 两列布局 - 参考体力分页样式
        VStack(spacing: 40 * scaleY) {
            // 第一行：前两个商品
            HStack(spacing: 129 * scaleX) { // 与体力分页相同的间距
                if products.count > 0 {
                    DiamondProductCard(
                        product: products[0],
                        viewModel: viewModel,
                        scaleX: scaleX,
                        scaleY: scaleY,
                        refreshTrigger: refreshTrigger,
                        onPurchase: {
                            if products[0].type == .freeDaily {
                                if canClaimFreeDaily() {
                                    selectedProduct = products[0]
                                    showPurchaseAlert = true
                                }
                            } else {
                                print("🛒 [商店] 点击购买钻石商品: \(products[0].diamonds)钻石")
                                selectedProduct = products[0]
                                showPurchaseAlert = true
                            }
                        }
                    )
                }
                
                if products.count > 1 {
                    DiamondProductCard(
                        product: products[1],
                        viewModel: viewModel,
                        scaleX: scaleX,
                        scaleY: scaleY,
                        refreshTrigger: refreshTrigger,
                        onPurchase: {
                            print("🛒 [商店] 点击购买钻石商品: \(products[1].diamonds)钻石")
                            selectedProduct = products[1]
                            showPurchaseAlert = true
                        }
                    )
                }
            }
            
            // 第二行：第三和第四个商品
            if products.count > 2 {
                HStack(spacing: 129 * scaleX) {
                    DiamondProductCard(
                        product: products[2],
                        viewModel: viewModel,
                        scaleX: scaleX,
                        scaleY: scaleY,
                        refreshTrigger: refreshTrigger,
                        onPurchase: {
                            print("🛒 [商店] 点击购买钻石商品: \(products[2].diamonds)钻石")
                            selectedProduct = products[2]
                            showPurchaseAlert = true
                        }
                    )
                    
                    if products.count > 3 {
                        DiamondProductCard(
                            product: products[3],
                            viewModel: viewModel,
                            scaleX: scaleX,
                            scaleY: scaleY,
                            refreshTrigger: refreshTrigger,
                            onPurchase: {
                                print("🛒 [商店] 点击购买钻石商品: \(products[3].diamonds)钻石")
                                selectedProduct = products[3]
                                showPurchaseAlert = true
                            }
                        )
                    } else {
                        Spacer() // 如果只有3个商品，第二个位置留空
                    }
                }
            }
            
            // 第三行：第五个商品（如果有）
            if products.count > 4 {
                HStack {
                    DiamondProductCard(
                        product: products[4],
                        viewModel: viewModel,
                        scaleX: scaleX,
                        scaleY: scaleY,
                        refreshTrigger: refreshTrigger,
                        onPurchase: {
                            print("🛒 [商店] 点击购买钻石商品: \(products[4].diamonds)钻石")
                            selectedProduct = products[4]
                            showPurchaseAlert = true
                        }
                    )
                    Spacer() // 靠左对齐
                }
            }
        }
        .padding(.horizontal, 55 * scaleX) // 与体力分页相同的起始位置
        .padding(.top, 40 * scaleY + 50) // 向下移动50像素，与哥布林分页一致
        .alert(localizationManager.localized("store.diamonds.purchase_title"), isPresented: $showPurchaseAlert) {
            if let product = selectedProduct {
                if product.type == .freeDaily {
                    // 检查是否已领取
                    if canClaimFreeDaily() {
                        Button(localizationManager.localized("confirmations.confirm")) {
                            claimFreeDailyDiamonds()
                        }
                        Button(localizationManager.localized("confirmations.cancel"), role: .cancel) { }
                    } else {
                        Button(localizationManager.localized("confirmations.confirm"), role: .cancel) { }
                    }
                } else {
                    Button(localizationManager.localized("store.diamonds.purchase")) {
                        guard let productId = product.productId else {
                            print("❌ [商店] 钻石商品没有 productId: \(product.id)")
                            purchaseErrorMessage = localizationManager.localized("store.product_config_error")
                            showPurchaseError = true
                            return
                        }
                        
                        isPurchasing = true
                        Task {
                            let success = await storeKitManager.purchase(productId: productId)
                            isPurchasing = false
                            
                            if success {
                                // 购买成功，添加钻石
                                viewModel.addDiamonds(product.diamonds)
                        showPurchaseSuccessAlert = true
                                print("✅ [商店] 成功购买钻石: \(product.diamonds)钻石")
                            } else {
                                // 购买失败
                                if let error = storeKitManager.purchaseError {
                                    purchaseErrorMessage = error
                                } else {
                                    purchaseErrorMessage = localizationManager.localized("store.purchase_failed")
                                }
                                showPurchaseError = true
                            }
                        }
                    }
                    .disabled(isPurchasing)
                    Button(localizationManager.localized("confirmations.cancel"), role: .cancel) { }
                }
            }
        } message: {
            if let product = selectedProduct {
                if product.type == .freeDaily {
                    if canClaimFreeDaily() {
                        Text(localizationManager.localized("store.diamonds.free_daily_message").replacingOccurrences(of: "{diamonds}", with: "10-50"))
                    } else {
                        Text(localizationManager.localized("store.diamonds.claimed"))
                    }
                } else {
                    Text(localizationManager.localized("store.diamonds.purchase_message").replacingOccurrences(of: "{diamonds}", with: "\(product.diamonds)").replacingOccurrences(of: "{price}", with: String(format: "%.2f", product.priceUSD)))
                }
            }
        }
        .alert(localizationManager.localized("store.purchase_failed"), isPresented: $showPurchaseError) {
            Button(localizationManager.localized("confirmations.confirm"), role: .cancel) { }
        } message: {
            Text(purchaseErrorMessage)
        }
        .overlay {
            if isPurchasing {
                ZStack {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                    VStack(spacing: 20) {
                        ProgressView()
                            .scaleEffect(1.5)
                        Text(localizationManager.localized("store.processing_purchase"))
                            .foregroundColor(.white)
                            .font(.headline)
                    }
                    .padding(30)
                    .background(Color.black.opacity(0.8))
                    .cornerRadius(15)
                }
            }
        }
        .alert(localizationManager.localized("store.diamonds.reward_title"), isPresented: $showRewardAlert) {
            Button(localizationManager.localized("confirmations.confirm")) {
                showRewardAlert = false
            }
        } message: {
            Text(localizationManager.localized("store.diamonds.reward_message").replacingOccurrences(of: "{diamonds}", with: "\(rewardDiamonds)"))
        }
        .alert(localizationManager.localized("store.goblins.purchase_success"), isPresented: $showPurchaseSuccessAlert) {
            Button(localizationManager.localized("confirmations.confirm"), role: .cancel) { }
        }
    }
    
    /// 领取每日免费钻石随机宝箱
    private func claimFreeDailyDiamonds() {
        let lastClaimDate = UserDefaults.standard.object(forKey: "lastFreeDiamondsClaimDate") as? Date
        let calendar = Calendar.current
        
        // 检查今天是否已经领取过
        if let lastDate = lastClaimDate, calendar.isDateInToday(lastDate) {
            print("💎 [每日免费] 今天已经领取过了")
            return
        }
        
        // 随机抽取钻石数量（根据概率）
        let diamonds = getRandomDiamondsFromBox()
        
        // 领取钻石
        viewModel.addDiamonds(diamonds)
        let claimDate = Date()
        UserDefaults.standard.set(claimDate, forKey: "lastFreeDiamondsClaimDate")
        print("💎 [每日免费] 成功领取\(diamonds)钻石（随机宝箱）")
        
        // 更新 viewModel 的状态，触发红点立即消失
        DispatchQueue.main.async {
            self.viewModel.freeDiamondsClaimDate = claimDate
        }
        
        // 显示领取成功弹窗
        rewardDiamonds = diamonds
        showRewardAlert = true
    }
    
    /// 根据概率随机获取钻石数量
    private func getRandomDiamondsFromBox() -> Int {
        let random = Double.random(in: 0...100)
        
        // 10钻：50% (0-50)
        if random <= 50 {
            return 10
        }
        // 20钻：20% (50-70)
        else if random <= 70 {
            return 20
        }
        // 30钻：15% (70-85)
        else if random <= 85 {
            return 30
        }
        // 40钻：10% (85-95)
        else if random <= 95 {
            return 40
        }
        // 50钻：5% (95-100)
        else {
            return 50
        }
    }
    
    
    /// 检查每日免费是否可领取
    func canClaimFreeDaily() -> Bool {
        let lastClaimDate = UserDefaults.standard.object(forKey: "lastFreeDiamondsClaimDate") as? Date
        let calendar = Calendar.current
        
        // 检查是否已经领取过（需要检查是否是今天）
        if let lastDate = lastClaimDate {
            // 如果最后领取日期是今天，则已领取
            if calendar.isDateInToday(lastDate) {
                return false
            }
            // 如果最后领取日期不是今天，检查是否需要刷新（跨天）
            let today = calendar.startOfDay(for: Date())
            let lastDay = calendar.startOfDay(for: lastDate)
            if today > lastDay {
                // 跨天了，可以领取
                return true
            }
        }
        return true
    }
    
    /// 检查是否需要刷新宝箱状态（每天00:00）
    func shouldRefreshBox() -> Bool {
        let lastClaimDate = UserDefaults.standard.object(forKey: "lastFreeDiamondsClaimDate") as? Date
        let calendar = Calendar.current
        
        guard let lastDate = lastClaimDate else {
            return false
        }
        
        // 检查是否跨天了
        let today = calendar.startOfDay(for: Date())
        let lastDay = calendar.startOfDay(for: lastDate)
        return today > lastDay
    }
}

// MARK: - 钻石商品卡片
struct DiamondProductCard: View {
    let product: DiamondsStoreView.DiamondProduct
    @ObservedObject var viewModel: GameViewModel
    let scaleX: CGFloat
    let scaleY: CGFloat
    let refreshTrigger: UUID // 用于接收刷新触发
    let onPurchase: () -> Void
    @ObservedObject var localizationManager = LocalizationManager.shared
    @State private var canClaim: Bool = true
    
    // 获取自定义字体
    private func customFont(size: CGFloat) -> Font {
        return FontManager.shared.customFont(size: size)
    }
    
    // 获取标题文本
    private func getTitle() -> String {
        if product.type == .freeDaily {
            return localizationManager.currentLanguage == "zh" ? "免费\n钻石" : "daily\nrewards"
        } else {
            return localizationManager.currentLanguage == "zh" ? "钻石\n包" : "diamonds\npack"
        }
    }
    
    // 格式化价格显示
    private func formatPrice(_ price: Double) -> String {
        return String(format: "$%.2f", price)
    }
    
    // 根据钻石数量获取对应的图标
    private func getDiamondImageName(for diamonds: Int) -> String {
        switch diamonds {
        case 100:
            return "diamond_1"
        case 150:
            return "diamond_2"
        case 350:
            return "diamond_3"
        case 600:
            return "diamond_4"
        default:
            return "crystal" // 默认图标
        }
    }
    
    var body: some View {
        // 卡片尺寸 (Figma: width: 476, 参考体力卡片尺寸)
        let cardWidth = 476 * scaleX
        let cardContentHeight = 653 * scaleY
        let titleHeight = 143 * scaleY
        let priceHeight = 128 * scaleY
        let cornerRadius = 30 * scaleX
        
        VStack(spacing: 0) {
            // 标题栏 (Figma: height: 143, 背景色 #E7A757)
            ZStack {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(Color(hex: "E7A757"))
                    .frame(height: titleHeight)
                    .mask(
                        TopRoundedRectangle(cornerRadius: cornerRadius)
                    )
                
                Text({
                    let title = getTitle().replacingOccurrences(of: "\n", with: " ")
                    // 如果是中文，移除空格；英文保留空格
                    return localizationManager.currentLanguage == "zh" ? title.replacingOccurrences(of: " ", with: "") : title
                }())
                    .font(customFont(size: (localizationManager.currentLanguage == "zh" ? 64 : 54) * scaleX))
                    .foregroundColor(Color(hex: "81331B")) // 标题字体色 #81331B
                    .multilineTextAlignment(.center)
                    .lineLimit(1) // 不换行
                    .minimumScaleFactor(0.5) // 自动缩小字体以适应宽度，避免省略号
                    .frame(width: localizationManager.currentLanguage == "zh" ? (cardWidth + 90 * scaleX) : (cardWidth + 100 * scaleX), height: titleHeight, alignment: .center) // 横向扩张（向右再扩张50像素）
            }
            
            // 内容区域 (Figma: height: 653, 背景色 #FDE9B4)
            ZStack {
                // 背景色
                Color(hex: "FDE9B4")
                    .frame(height: cardContentHeight)
                
                // 花纹蒙层（mask.png）- 覆盖在背景之上，文字与图片之下
                Image("mask")
                    .resizable()
                    .scaledToFill()
                    .frame(width: cardWidth, height: cardContentHeight)
                    .clipped()
                
                if product.type == .freeDaily {
                    // 免费每日：显示宝箱图片（放大1.3倍）
                    Image(canClaim ? "diamonds_box_full" : "diamonds_box_none")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 300 * 1.3 * scaleX, height: 300 * 1.3 * scaleY)
                } else {
                    // 付费商品：根据钻石数量显示对应的图标（放大3倍：2 * 1.5）
                    Image(getDiamondImageName(for: product.diamonds))
                        .resizable()
                        .scaledToFit()
                        .frame(width: 150 * 3 * scaleX, height: 150 * 3 * scaleY)
                }
            }
            .frame(height: cardContentHeight)
            
            // 数量显示区域 (背景色与卡片统一 #FDE9B4)
            ZStack {
                RoundedRectangle(cornerRadius: 0)
                    .fill(Color(hex: "FDE9B4"))
                    .frame(height: 125 * scaleY)
                
                if product.type == .freeDaily {
                    // 免费每日：显示随机宝箱提示（10~50 + crystal图标）
                    HStack(spacing: 8 * scaleX) {
                        Text("10~50")
                            .font(customFont(size: 80 * scaleX))
                            .foregroundColor(.white)
                            .textStroke()
                        Image("crystal")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 60 * scaleX, height: 60 * scaleY)
                    }
                } else {
                    // 付费商品：显示钻石数量
                    Text("x\(product.diamonds)")
                        .font(customFont(size: (localizationManager.currentLanguage == "zh" ? 100 : 77) * scaleX))
                        .foregroundColor(.white)
                        .textStroke()
                }
            }
            
            // 价格栏 (Figma: height: 128, 购买按钮背景色 #FFC400)
            Button(action: {
                if product.type == .freeDaily {
                    print("🛒 [商店] 点击领取每日免费钻石宝箱")
                } else {
                    print("🛒 [商店] 点击购买钻石商品: \(product.diamonds)钻石")
                }
                onPurchase()
            }) {
                ZStack {
                    RoundedRectangle(cornerRadius: 0)
                        .fill((canClaim && product.type == .freeDaily) ? Color(hex: "FFC400") : (product.type == .freeDaily ? Color(hex: "CCCCCC") : Color(hex: "FFC400")))
                        .frame(height: priceHeight)
                        .mask(
                            BottomRoundedRectangle(cornerRadius: cornerRadius)
                        )
                    
                    HStack(spacing: 20 * scaleX) {
                        if product.type == .freeDaily {
                            // 免费显示特殊图标或文字
                            Text(canClaim ? "FREE" : localizationManager.localized("store.diamonds.claimed"))
                                .font(customFont(size: 80 * scaleX))
                                .foregroundColor(.white)
                                .textStroke()
                        } else {
                            // 显示价格
                            Text(formatPrice(product.priceUSD))
                                .font(customFont(size: (localizationManager.currentLanguage == "zh" ? 80 : 75) * scaleX))
                                .foregroundColor(.white)
                                .textStroke()
                        }
                    }
                }
            }
            .buttonStyle(PlainButtonStyle())
            .disabled(!canClaim && product.type == .freeDaily)
            .onAppear {
                // 检查是否可以领取（每天00:00刷新）
                updateClaimStatus()
                // 设置定时器检查每天00:00刷新
                setupDailyRefreshTimer()
            }
            .onChange(of: refreshTrigger) { _ in
                // 当收到刷新触发时，更新状态
                updateClaimStatus()
            }
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.significantTimeChangeNotification)) { _ in
                // 监听系统时间变化（包括跨天）
                updateClaimStatus()
            }
        }
        .frame(width: cardWidth)
        .cornerRadius(cornerRadius)
        .overlay(
            RoundedRectangle(cornerRadius: cornerRadius)
                .stroke(Color(hex: "88520F"), lineWidth: 2 * scaleX) // 卡片描边 #88520F
        )
        .shadow(color: .black.opacity(0.3), radius: 5, x: 0, y: 5) // 5像素外部投影
        .offset(y: 10 * scaleY) // 整个卡片（包括标题区域和描边）下移 10 像素
    }
    
    /// 更新领取状态
    private func updateClaimStatus() {
        if product.type == .freeDaily {
            let lastClaimDate = UserDefaults.standard.object(forKey: "lastFreeDiamondsClaimDate") as? Date
            let calendar = Calendar.current
            
            if let lastDate = lastClaimDate {
                // 检查是否是今天
                canClaim = !calendar.isDateInToday(lastDate)
            } else {
                canClaim = true
            }
        }
    }
    
    /// 设置每天00:00刷新定时器
    private func setupDailyRefreshTimer() {
        guard product.type == .freeDaily else { return }
        
        let calendar = Calendar.current
        let now = Date()
        
        // 计算下一个00:00的时间
        var components = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: now)
        components.hour = 0
        components.minute = 0
        components.second = 0
        
        var nextMidnight = calendar.date(from: components)!
        
        // 如果当前时间已经过了今天的00:00，则设置为明天的00:00
        if nextMidnight <= now {
            nextMidnight = calendar.date(byAdding: .day, value: 1, to: nextMidnight)!
        }
        
        // 计算距离下一个00:00的秒数
        let timeInterval = nextMidnight.timeIntervalSince(now)
        
        // 设置定时器
        DispatchQueue.main.asyncAfter(deadline: .now() + timeInterval) {
            self.updateClaimStatus()
            // 递归设置下一个00:00的定时器
            self.setupDailyRefreshTimer()
        }
    }
}

// MARK: - 顶部圆角矩形形状
struct TopRoundedRectangle: Shape {
    var cornerRadius: CGFloat
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        let topLeft = CGPoint(x: rect.minX, y: rect.minY + cornerRadius)
        let topRight = CGPoint(x: rect.maxX, y: rect.minY + cornerRadius)
        let bottomLeft = CGPoint(x: rect.minX, y: rect.maxY)
        let bottomRight = CGPoint(x: rect.maxX, y: rect.maxY)
        
        // 左上角圆角
        path.move(to: CGPoint(x: rect.minX, y: rect.minY + cornerRadius))
        path.addArc(center: CGPoint(x: rect.minX + cornerRadius, y: rect.minY + cornerRadius),
                   radius: cornerRadius,
                   startAngle: .degrees(180),
                   endAngle: .degrees(270),
                   clockwise: false)
        
        // 顶部直线
        path.addLine(to: CGPoint(x: rect.maxX - cornerRadius, y: rect.minY))
        
        // 右上角圆角
        path.addArc(center: CGPoint(x: rect.maxX - cornerRadius, y: rect.minY + cornerRadius),
                   radius: cornerRadius,
                   startAngle: .degrees(270),
                   endAngle: .degrees(0),
                   clockwise: false)
        
        // 右侧、底部、左侧直线
        path.addLine(to: bottomRight)
        path.addLine(to: bottomLeft)
        path.addLine(to: topLeft)
        
        path.closeSubpath()
        return path
    }
}

#Preview {
    PaidStoreView(viewModel: GameViewModel(), isPresented: .constant(true))
}
