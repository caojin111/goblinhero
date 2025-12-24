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
                                    GoblinsStoreView(viewModel: viewModel, scaleX: scaleX, scaleY: scaleY)
                                        .transition(.opacity)
                                case .stamina:
                                    StaminaStoreView(viewModel: viewModel, scaleX: scaleX, scaleY: scaleY)
                                        .transition(.opacity)
                                case .diamonds:
                                    DiamondsStoreView(viewModel: viewModel, scaleX: scaleX, scaleY: scaleY)
                                        .transition(.opacity)
                                }
                            }
                            .id(selectedTab.rawValue) // 使用id确保视图正确更新
                        }
                        .padding(.bottom, 200 * scaleY) // 为底部页签留出更多空间，避免穿帮
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
    @ObservedObject var localizationManager = LocalizationManager.shared
    @State private var showUnlockAlert: Bool = false
    @State private var goblinToUnlock: Goblin?
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
                        }
                    )
                    .offset(y: goblin.nameKey == "wizard_goblin" ? -30 * scaleY : 0) // wizard卡片额外向上移动30像素（总共向上移动30像素）
                }
            }
        }
        .padding(.horizontal, 40 * scaleX) // 还原原始布局
        .padding(.top, 40 * scaleY + 0) // 再向上移动30像素（从30改为0）
        .alert(localizationManager.localized("store.goblins.unlock_title"), isPresented: $showUnlockAlert) {
            if let goblin = goblinToUnlock {
                if viewModel.diamonds >= goblin.unlockPrice {
                    Button(localizationManager.localized("confirmations.confirm")) {
                        if viewModel.unlockGoblin(goblinId: goblin.id, cost: goblin.unlockPrice) {
                            print("🛒 [商店] 成功解锁哥布林: \(goblin.name)")
                        }
                    }
                    Button(localizationManager.localized("confirmations.cancel"), role: .cancel) { }
                } else {
                    Button(localizationManager.localized("confirmations.confirm"), role: .cancel) { }
                }
            }
        } message: {
            if let goblin = goblinToUnlock {
                if viewModel.diamonds >= goblin.unlockPrice {
                    Text(localizationManager.localized("store.goblins.unlock_message").replacingOccurrences(of: "{name}", with: goblin.name).replacingOccurrences(of: "{price}", with: "\(goblin.unlockPrice)"))
                } else {
                    Text(localizationManager.localized("store.goblins.insufficient_diamonds").replacingOccurrences(of: "{price}", with: "\(goblin.unlockPrice)").replacingOccurrences(of: "{current}", with: "\(viewModel.diamonds)"))
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
    @ObservedObject var localizationManager = LocalizationManager.shared
    
    // 获取自定义字体
    private func customFont(size: CGFloat) -> Font {
        return FontManager.shared.customFont(size: size)
    }
    
    var body: some View {
        // 计算卡片宽度和高度（在 VStack 外部定义，确保作用域正确）
        // 巫师和国王使用相同的宽度（1109），保持一致
        let cardWidth = 1109 * scaleX
        // 根据新图片的宽高比（1094:729）计算高度
        let imageAspectRatio: CGFloat = 1094.0 / 729.0
        let cardHeight = cardWidth / imageAspectRatio
        let cornerRadius = 30 * scaleX
        
        return VStack(spacing: 0) {
            // 标题栏 (Figma: x: 134, y: 168, width: 966, height: 114) - 已隐藏
            ZStack {
                RoundedRectangle(cornerRadius: 20 * scaleX)
                    .fill(Color(hex: "E5D6A1"))
                    .frame(height: 114 * scaleY)
                
                Text(goblin.name)
                    .font(customFont(size: 100 * scaleX))
                    .foregroundColor(.white)
                    .textStroke()
            }
            .hidden() // 隐藏标题栏
            
            // 哥布林图片区域 - 新的一体化图片（分辨率：1094*729）
            // 图片宽度与购买按钮一致（即 cardWidth）
            
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
                }
            }
            .frame(width: cardWidth, height: cardHeight)
            .padding(.top, 20 * scaleY)
            
            // 价格栏 (Figma: height: 156) - 改为Button，始终可点击，宽度与哥布林图片一致
            Button(action: {
                print("🛒 [商店] 点击购买哥布林: \(goblin.name), 价格: \(goblin.unlockPrice), 当前钻石: \(viewModel.diamonds)")
                onUnlock() // 始终调用，让alert来处理钻石不足的情况
            }) {
                ZStack {
                    RoundedRectangle(cornerRadius: 0)
                        .fill(Color(hex: "FDE827"))
                        .frame(width: cardWidth, height: 156 * scaleY)
                    
                    HStack(spacing: 20 * scaleX) {
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
            .buttonStyle(PlainButtonStyle())
            .frame(width: cardWidth) // 确保按钮宽度与图片一致
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
        StaminaPack(stamina: 30, diamonds: 2000, titleKey: "a_little_bit"),
        StaminaPack(stamina: 90, diamonds: 2000, titleKey: "a_lot"),
        StaminaPack(stamina: 300, diamonds: 2000, titleKey: "super_many")
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
        switch pack.titleKey {
        case "a_little_bit":
            return "a little bit of\nstamina"
        case "a_lot":
            return "a lot of\nstamina"
        case "super_many":
            return "super many of\nstamina"
        default:
            return "stamina"
        }
    }
    
    // 获取食物图片名称
    private func getFoodImageName() -> String {
        // 根据设计图，第一个和第二个卡片有食物图片
        if pack.titleKey == "a_little_bit" {
            return "FOOD_21"
        } else if pack.titleKey == "a_lot" {
            return "FOOD_22"
        }
        return "fruit" // 默认使用fruit图标
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
                
                Text(getTitle())
                    .font(customFont(size: 64 * scaleX))
                    .foregroundColor(Color(hex: "81331B")) // 标题字体色 #81331B
                    .multilineTextAlignment(.center)
            }
            
            // 内容区域 (Figma: height: 653, 背景色 #FDE9B4)
            ZStack {
                // 背景色
                Color(hex: "FDE9B4")
                    .frame(height: cardContentHeight)
                
                // 食物图片（如果有）- 根据设计图位置显示
                if pack.titleKey == "a_little_bit" || pack.titleKey == "a_lot" {
                    VStack {
                        Spacer()
                        Image(getFoodImageName())
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth: 207 * scaleX, maxHeight: 137 * scaleY)
                            .padding(.bottom, 100 * scaleY) // 距离底部一定距离
                    }
                }
            }
            .frame(height: cardContentHeight)
            
            // 数量显示区域 (背景色与卡片统一 #FDE9B4)
            ZStack {
                RoundedRectangle(cornerRadius: 0)
                    .fill(Color(hex: "FDE9B4"))
                    .frame(height: 125 * scaleY)
                
                Text("x\(pack.stamina)")
                    .font(customFont(size: 100 * scaleX))
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
                            .font(customFont(size: 100 * scaleX))
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
    @State private var showPurchaseAlert: Bool = false
    @State private var selectedProduct: DiamondProduct?
    let scaleX: CGFloat
    let scaleY: CGFloat
    
    // 获取自定义字体
    private func customFont(size: CGFloat) -> Font {
        return FontManager.shared.customFont(size: size)
    }
    
    struct DiamondProduct: Identifiable {
        let id: String
        let type: ProductType
        let priceUSD: Double
        let diamonds: Int
        
        enum ProductType {
            case freeDaily
            case paid
        }
    }
    
    let products: [DiamondProduct] = [
        DiamondProduct(id: "free_daily", type: .freeDaily, priceUSD: 0.00, diamonds: 10),
        DiamondProduct(id: "pack_100", type: .paid, priceUSD: 5.99, diamonds: 100),
        DiamondProduct(id: "pack_150", type: .paid, priceUSD: 9.99, diamonds: 150),
        DiamondProduct(id: "pack_350", type: .paid, priceUSD: 19.99, diamonds: 350),
        DiamondProduct(id: "pack_600", type: .paid, priceUSD: 29.99, diamonds: 600)
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
                        onPurchase: {
                            print("🛒 [商店] 点击购买钻石商品: \(products[0].diamonds)钻石")
                            selectedProduct = products[0]
                            showPurchaseAlert = true
                        }
                    )
                }
                
                if products.count > 1 {
                    DiamondProductCard(
                        product: products[1],
                        viewModel: viewModel,
                        scaleX: scaleX,
                        scaleY: scaleY,
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
                    Button(localizationManager.localized("confirmations.confirm")) {
                        claimFreeDailyDiamonds()
                    }
                    Button(localizationManager.localized("confirmations.cancel"), role: .cancel) { }
                } else {
                    Button(localizationManager.localized("store.diamonds.purchase")) {
                        purchaseDiamonds(product: product)
                    }
                    Button(localizationManager.localized("confirmations.cancel"), role: .cancel) { }
                }
            }
        } message: {
            if let product = selectedProduct {
                if product.type == .freeDaily {
                    Text(localizationManager.localized("store.diamonds.free_daily_message").replacingOccurrences(of: "{diamonds}", with: "\(product.diamonds)"))
                } else {
                    Text(localizationManager.localized("store.diamonds.purchase_message").replacingOccurrences(of: "{diamonds}", with: "\(product.diamonds)").replacingOccurrences(of: "{price}", with: String(format: "%.2f", product.priceUSD)))
                }
            }
        }
    }
    
    /// 领取每日免费钻石
    private func claimFreeDailyDiamonds() {
        let lastClaimDate = UserDefaults.standard.object(forKey: "lastFreeDiamondsClaimDate") as? Date
        let calendar = Calendar.current
        
        // 检查今天是否已经领取过
        if let lastDate = lastClaimDate, calendar.isDateInToday(lastDate) {
            print("💎 [每日免费] 今天已经领取过了")
            return
        }
        
        // 领取钻石
        viewModel.addDiamonds(10)
        UserDefaults.standard.set(Date(), forKey: "lastFreeDiamondsClaimDate")
        print("💎 [每日免费] 成功领取10钻石")
    }
    
    /// 购买钻石（模拟，实际需要集成 StoreKit）
    private func purchaseDiamonds(product: DiamondProduct) {
        // TODO: 这里应该集成 StoreKit 进行实际支付
        // 目前先模拟购买，直接添加钻石
        viewModel.addDiamonds(product.diamonds)
        print("💎 [购买钻石] 购买\(product.diamonds)钻石，价格$\(product.priceUSD)")
    }
    
    /// 检查每日免费是否可领取
    func canClaimFreeDaily() -> Bool {
        let lastClaimDate = UserDefaults.standard.object(forKey: "lastFreeDiamondsClaimDate") as? Date
        let calendar = Calendar.current
        
        if let lastDate = lastClaimDate {
            return !calendar.isDateInToday(lastDate)
        }
        return true
    }
}

// MARK: - 钻石商品卡片
struct DiamondProductCard: View {
    let product: DiamondsStoreView.DiamondProduct
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
        if product.type == .freeDaily {
            return "free\ndiamonds"
        } else {
            return "diamonds\npack"
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
                
                Text(getTitle())
                    .font(customFont(size: 64 * scaleX))
                    .foregroundColor(Color(hex: "81331B")) // 标题字体色 #81331B
                    .multilineTextAlignment(.center)
            }
            
            // 内容区域 (Figma: height: 653, 背景色 #FDE9B4)
            ZStack {
                // 背景色
                Color(hex: "FDE9B4")
                    .frame(height: cardContentHeight)
                
                // 钻石图标（移除下方的数量显示）
                    Image("crystal")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 150 * scaleX, height: 150 * scaleY)
            }
            .frame(height: cardContentHeight)
            
            // 数量显示区域 (背景色与卡片统一 #FDE9B4)
            ZStack {
                RoundedRectangle(cornerRadius: 0)
                    .fill(Color(hex: "FDE9B4"))
                    .frame(height: 125 * scaleY)
                
                Text("x\(product.diamonds)")
                    .font(customFont(size: 100 * scaleX))
                    .foregroundColor(.white)
                    .textStroke()
            }
            
            // 价格栏 (Figma: height: 128, 购买按钮背景色 #FFC400)
            Button(action: {
                print("🛒 [商店] 点击购买钻石商品: \(product.diamonds)钻石")
                onPurchase()
            }) {
                ZStack {
                    RoundedRectangle(cornerRadius: 0)
                        .fill(Color(hex: "FFC400"))
                        .frame(height: priceHeight)
                        .mask(
                            BottomRoundedRectangle(cornerRadius: cornerRadius)
                        )
                    
                    HStack(spacing: 20 * scaleX) {
                        if product.type == .freeDaily {
                            // 免费显示特殊图标或文字
                            Text("FREE")
                                .font(customFont(size: 80 * scaleX))
                                .foregroundColor(.white)
                                .textStroke()
                        } else {
                            Image("crystal")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 95 * scaleX, height: 95 * scaleY)
                            
                            Text("\(product.diamonds)")
                                .font(customFont(size: 100 * scaleX))
                                .foregroundColor(.white)
                                .textStroke()
                        }
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
    
    /// 检查每日免费是否可领取
    private func canClaimFreeDaily() -> Bool {
        let lastClaimDate = UserDefaults.standard.object(forKey: "lastFreeDiamondsClaimDate") as? Date
        let calendar = Calendar.current
        
        if let lastDate = lastClaimDate {
            return !calendar.isDateInToday(lastDate)
        }
        return true
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
