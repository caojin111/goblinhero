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
    
    var initialTab: StoreTab = .goblins
    @State private var selectedTab: StoreTab = .goblins
    
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
        
        var icon: String {
            switch self {
            case .goblins: return "👹"
            case .stamina: return "⚡"
            case .diamonds: return "💎"
            }
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // 背景渐变
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.purple.opacity(0.6),
                        Color.blue.opacity(0.6),
                        Color.pink.opacity(0.4)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // 顶部钻石显示
                    HStack {
                        Spacer()
                        HStack(spacing: 8) {
                            Text("💎")
                                .font(.title2)
                            Text("\(viewModel.diamonds)")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color.black.opacity(0.3))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20)
                                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                                )
                        )
                        .padding(.trailing, 20)
                        .padding(.top, 10)
                    }
                    
                    // 标签页选择器
                    HStack(spacing: 0) {
                        ForEach(StoreTab.allCases, id: \.self) { tab in
                            Button(action: {
                                withAnimation {
                                    selectedTab = tab
                                }
                            }) {
                                VStack(spacing: 6) {
                                    Text(tab.icon)
                                        .font(.title2)
                                    Text(tab.displayName(using: localizationManager))
                                        .font(.caption)
                                        .fontWeight(.medium)
                                }
                                .foregroundColor(selectedTab == tab ? .white : .white.opacity(0.6))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(
                                    selectedTab == tab ?
                                    Color.white.opacity(0.2) :
                                    Color.clear
                                )
                            }
                        }
                    }
                    .background(
                        RoundedRectangle(cornerRadius: 15)
                            .fill(Color.black.opacity(0.2))
                    )
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                    
                    // 内容区域
                    ScrollView {
                        VStack(spacing: 20) {
                            switch selectedTab {
                            case .goblins:
                                GoblinsStoreView(viewModel: viewModel)
                            case .stamina:
                                StaminaStoreView(viewModel: viewModel)
                            case .diamonds:
                                DiamondsStoreView(viewModel: viewModel)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 20)
                    }
                }
            }
            .navigationTitle(localizationManager.localized("stores.paid_store"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        isPresented = false
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.white)
                    }
                }
            }
            .onAppear {
                // 每次视图出现时，同步 selectedTab 到 initialTab
                selectedTab = initialTab
            }
            .onChange(of: isPresented) { newValue in
                // 当 sheet 显示时，同步 selectedTab 到 initialTab
                if newValue {
                    selectedTab = initialTab
                }
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
    
    // 获取需要解锁的哥布林（国王和巫师）
    var lockedGoblins: [Goblin] {
        Goblin.allGoblins.filter { goblin in
            !goblin.isFree && !viewModel.unlockedGoblinIds.contains(goblin.id)
        }
    }
    
    var body: some View {
        Group {
            if lockedGoblins.isEmpty {
                VStack(spacing: 20) {
                    Text("✅")
                        .font(.system(size: 60))
                    Text(localizationManager.localized("store.goblins.all_unlocked"))
                        .font(.title3)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 60)
            } else {
                VStack(spacing: 20) {
                    ForEach(lockedGoblins) { goblin in
                        GoblinStoreCard(
                            goblin: goblin,
                            viewModel: viewModel,
                            onUnlock: {
                                goblinToUnlock = goblin
                                showUnlockAlert = true
                            }
                        )
                    }
                }
            }
        }
        .alert(localizationManager.localized("store.goblins.unlock_title"), isPresented: $showUnlockAlert) {
            if let goblin = goblinToUnlock {
                if viewModel.diamonds >= goblin.unlockPrice {
                    Button(localizationManager.localized("confirmations.confirm")) {
                        if viewModel.unlockGoblin(goblinId: goblin.id, cost: goblin.unlockPrice) {
                            // 解锁成功
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
    let onUnlock: () -> Void
    @ObservedObject var localizationManager = LocalizationManager.shared
    
    var body: some View {
        VStack(spacing: 15) {
            // 哥布林图标
            Text(goblin.icon)
                .font(.system(size: 80))
                .opacity(0.7)
            
            // 名称
            Text(goblin.name)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            // Buff描述
            VStack(alignment: .leading, spacing: 8) {
                Text("⭐ \(localizationManager.localized("goblin.special_ability"))")
                    .font(.headline)
                    .foregroundColor(.yellow)
                Text(goblin.buff)
                    .font(.body)
                    .foregroundColor(.white.opacity(0.9))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 15)
                    .fill(Color.black.opacity(0.3))
            )
            
            // 解锁按钮
            Button(action: onUnlock) {
                HStack(spacing: 10) {
                    Text("💎")
                        .font(.title3)
                    Text("\(localizationManager.localized("goblin.unlock")) - \(goblin.unlockPrice) 💎")
                        .font(.headline)
                        .fontWeight(.bold)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: viewModel.diamonds >= goblin.unlockPrice ?
                            [Color.blue, Color.purple] :
                            [Color.gray, Color.gray.opacity(0.7)]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(15)
            }
            .disabled(viewModel.diamonds < goblin.unlockPrice)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
        )
    }
}

// MARK: - 体力商城视图
struct StaminaStoreView: View {
    @ObservedObject var viewModel: GameViewModel
    @ObservedObject var localizationManager = LocalizationManager.shared
    @State private var showPurchaseAlert: Bool = false
    @State private var selectedStaminaPack: StaminaPack?
    
    struct StaminaPack {
        let stamina: Int
        let diamonds: Int
    }
    
    let staminaPacks: [StaminaPack] = [
        StaminaPack(stamina: 30, diamonds: 100),
        StaminaPack(stamina: 60, diamonds: 200),
        StaminaPack(stamina: 120, diamonds: 400)
    ]
    
    var body: some View {
        VStack(spacing: 20) {
            // 当前体力显示
            HStack {
                Text("⚡")
                    .font(.title)
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(viewModel.stamina)/\(viewModel.maxStamina)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    Text(localizationManager.localized("store.stamina.current"))
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                }
                Spacer()
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 15)
                    .fill(Color.black.opacity(0.3))
            )
            
            // 体力包列表
            ForEach(Array(staminaPacks.enumerated()), id: \.offset) { index, pack in
                StaminaPackCard(
                    pack: pack,
                    viewModel: viewModel,
                    onPurchase: {
                        selectedStaminaPack = pack
                        showPurchaseAlert = true
                    }
                )
            }
        }
        .alert(localizationManager.localized("store.stamina.purchase_title"), isPresented: $showPurchaseAlert) {
            if let pack = selectedStaminaPack {
                if viewModel.diamonds >= pack.diamonds {
                    Button(localizationManager.localized("confirmations.confirm")) {
                        if viewModel.purchaseStamina(amount: pack.stamina, cost: pack.diamonds) {
                            // 购买成功
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
    let onPurchase: () -> Void
    @ObservedObject var localizationManager = LocalizationManager.shared
    
    var body: some View {
        HStack(spacing: 20) {
            // 体力图标和数量
            VStack(spacing: 8) {
                Text("⚡")
                    .font(.system(size: 50))
                Text("\(pack.stamina)")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }
            
            Spacer()
            
            // 价格
            VStack(alignment: .trailing, spacing: 8) {
                HStack(spacing: 6) {
                    Text("💎")
                        .font(.title3)
                    Text("\(pack.diamonds)")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }
                
                // 购买按钮
                Button(action: onPurchase) {
                    Text(localizationManager.localized("store.stamina.buy"))
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 8)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: viewModel.diamonds >= pack.diamonds ?
                                    [Color.green, Color.blue] :
                                    [Color.gray, Color.gray.opacity(0.7)]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(10)
                }
                .disabled(viewModel.diamonds < pack.diamonds)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color.white.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 15)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
        )
    }
}

// MARK: - 钻石商城视图
struct DiamondsStoreView: View {
    @ObservedObject var viewModel: GameViewModel
    @ObservedObject var localizationManager = LocalizationManager.shared
    @State private var showPurchaseAlert: Bool = false
    @State private var selectedProduct: DiamondProduct?
    
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
        ScrollView {
            VStack(spacing: 20) {
                // 当前钻石显示
                HStack {
                    Text("💎")
                        .font(.title)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("\(viewModel.diamonds)")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        Text(localizationManager.localized("store.diamonds.current"))
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                    }
                    Spacer()
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 15)
                        .fill(Color.black.opacity(0.3))
                )
                
                // 商品列表
                ForEach(products) { product in
                    DiamondProductCard(
                        product: product,
                        viewModel: viewModel,
                        onPurchase: {
                            selectedProduct = product
                            showPurchaseAlert = true
                        }
                    )
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 20)
        }
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
    let onPurchase: () -> Void
    @ObservedObject var localizationManager = LocalizationManager.shared
    
    var body: some View {
        HStack(spacing: 20) {
            // 左侧：钻石图标和数量
            VStack(spacing: 8) {
                Text("💎")
                    .font(.system(size: 50))
                Text("\(product.diamonds)")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }
            
            Spacer()
            
            // 右侧：价格和购买按钮
            VStack(alignment: .trailing, spacing: 12) {
                if product.type == .freeDaily {
                    // 免费标签
                    HStack(spacing: 4) {
                        Text("🆓")
                            .font(.title3)
                        Text(localizationManager.localized("store.diamonds.free"))
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.green)
                    }
                    
                    // 领取按钮
                    Button(action: onPurchase) {
                        Text(canClaimFreeDaily() ? 
                             localizationManager.localized("store.diamonds.claim") : 
                             localizationManager.localized("store.diamonds.claimed"))
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 10)
                            .background(
                                LinearGradient(
                                    gradient: Gradient(colors: canClaimFreeDaily() ?
                                        [Color.green, Color.blue] :
                                        [Color.gray, Color.gray.opacity(0.7)]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(10)
                    }
                    .disabled(!canClaimFreeDaily())
                } else {
                    // 价格显示
                    HStack(spacing: 4) {
                        Text("$")
                            .font(.title3)
                            .foregroundColor(.white.opacity(0.8))
                        Text(String(format: "%.2f", product.priceUSD))
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    }
                    
                    // 购买按钮
                    Button(action: onPurchase) {
                        Text(localizationManager.localized("store.diamonds.buy"))
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 10)
                            .background(
                                LinearGradient(
                                    gradient: Gradient(colors: [Color.blue, Color.purple]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(10)
                    }
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color.white.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 15)
                        .stroke(product.type == .freeDaily ? Color.green.opacity(0.5) : Color.white.opacity(0.2), lineWidth: 1)
                )
        )
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

#Preview {
    PaidStoreView(viewModel: GameViewModel(), isPresented: .constant(true))
}

