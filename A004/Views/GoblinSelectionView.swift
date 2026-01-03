//
//  GoblinSelectionView.swift
//  A004
//
//  哥布林选择界面
//

import SwiftUI

struct GoblinSelectionView: View {
    @Binding var selectedGoblin: Goblin?
    @Binding var isPresented: Bool
    @Binding var unlockedGoblinIds: Set<Int> // 已解锁的哥布林ID
    @Binding var currentCoins: Int // 当前金币用于解锁
    @ObservedObject var viewModel: GameViewModel // 用于访问钻石
    @ObservedObject var localizationManager = LocalizationManager.shared
    @ObservedObject var audioManager = AudioManager.shared
    
    var onNavigateToStore: (() -> Void)? = nil // 跳转到商店的回调
    
    @State private var currentIndex: Int = 0
    @State private var dragOffset: CGFloat = 0
    @State private var showUnlockAlert: Bool = false
    @State private var goblinToUnlock: Goblin?
    @State private var backgroundOpacity: Double = 0 // 背景遮罩透明度，用于渐现/渐隐效果
    
    // Figma设计尺寸：1203x1369
    private let designWidth: CGFloat = 1204
    private let designHeight: CGFloat = 1204
    
    // 获取自定义字体
    private func customFont(size: CGFloat) -> Font {
        return FontManager.shared.customFont(size: size)
    }
    
    // 根据设计尺寸计算实际尺寸（窗口内尺寸）
    private func scaleSize(_ size: CGFloat, windowWidth: CGFloat) -> CGFloat {
        return size * (windowWidth / designWidth)
    }
    
    // 根据设计尺寸计算实际高度（窗口内尺寸）
    private func scaleHeight(_ height: CGFloat, windowHeight: CGFloat) -> CGFloat {
        return height * (windowHeight / designHeight)
    }
    
    // 获取哥布林对应的图片名称（全身像，如果没有图片，返回nil，UI会使用emoji）
    private func getGoblinImageName(for goblin: Goblin) -> String? {
        switch goblin.nameKey {
        case "warrior_goblin":
            return "brave_goblin"
        case "craftsman_goblin":
            return "artisan_goblin"
        case "gambler_goblin":
            return "gambler_goblin"
        case "king_goblin":
            return "king_goblin"
        case "wizard_goblin":
            return "wazard_goblin" // 注意拼写
        case "athlete_goblin":
            return "athlete_goblin"
        default:
            return nil
        }
    }
    
    // 显示所有哥布林（不再过滤）
    private var displayGoblins: [Goblin] {
        return Goblin.allGoblins
    }
    
    var body: some View {
        GeometryReader { geometry in
            let screenWidth = geometry.size.width
            let screenHeight = geometry.size.height
            let windowWidth = min(screenWidth * 0.9, screenHeight * 0.9 * (designWidth / designHeight))
            let windowHeight = windowWidth * (designHeight / designWidth)
            
            ZStack {
                // 半透明背景遮罩（带渐现/渐隐效果）
                Color.black.opacity(backgroundOpacity)
                    .ignoresSafeArea()
                    .onTapGesture {
                        print("🎭 [哥布林选择] 点击背景关闭界面")
                        withAnimation(.easeOut(duration: 0.3)) {
                            backgroundOpacity = 0
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                isPresented = false
                            }
                        }
                    }
                
                // 窗口内容（居中显示，占屏幕一半大小）
                VStack(spacing: 0) {
                    Spacer()
                    
                    // 窗口
                    HStack {
                        Spacer()
                        ZStack {
                            // 背景图（尽量还原原尺寸）
                            Image("goblin_select_bg")
                                .resizable()
                                .scaledToFill()
                                .frame(width: windowWidth, height: windowHeight)
                                .clipped()
                            
                            VStack(spacing: 0) {
                            Spacer()
                            
                            // 哥布林显示区域
                            ZStack {
                                // 当前显示的哥布林
                                if currentIndex < displayGoblins.count {
                                    let goblin = displayGoblins[currentIndex]
                                    // 检查哥布林是否已解锁
                                    let isUnlocked = goblin.isFree || viewModel.unlockedGoblinIds.contains(goblin.id)
                                    
                                    VStack(spacing: scaleHeight(40, windowHeight: windowHeight)) {
                                        // 哥布林图片或emoji
                ZStack {
                                            // 锁定遮罩
                                                if !isUnlocked {
                                                    Color.black.opacity(0.5)
                                                        .frame(width: scaleSize(400, windowWidth: windowWidth), height: scaleSize(600, windowWidth: windowWidth))
                                                        .cornerRadius(scaleSize(20, windowWidth: windowWidth))
                                                }
                                                
                                            if let imageName = getGoblinImageName(for: goblin) {
                                                // 有图片的哥布林，显示图片
                                                Image(imageName)
                                                    .resizable()
                                                    .scaledToFit()
                                                    .frame(width: scaleSize(400, windowWidth: windowWidth), height: scaleSize(600, windowWidth: windowWidth))
                                                    .opacity(isUnlocked ? 1.0 : 0.5)
                                            } else {
                                                // 没有图片的哥布林，显示emoji图标
                                                Text(goblin.icon)
                                                    .font(.system(size: scaleSize(200, windowWidth: windowWidth)))
                                                    .frame(width: scaleSize(400, windowWidth: windowWidth), height: scaleSize(600, windowWidth: windowWidth))
                                                    .opacity(isUnlocked ? 1.0 : 0.5)
                                            }
                                                
                                                // 锁定图标（只保留系统图标锁）
                                                if !isUnlocked {
                                                    Image(systemName: "lock.fill")
                                                        .font(.system(size: scaleSize(60, windowWidth: windowWidth)))
                                                        .foregroundColor(.white)
                                            }
                                        }
                                        
                                        // 哥布林名称（字号增加5）
                                        Text(goblin.name)
                                            .font(customFont(size: scaleSize(48, windowWidth: windowWidth) + 5))
                                            .foregroundColor(.white)
                                            .textStroke() // 添加黑色描边
                                        
                                        // 详细描述（扩大1.5倍，去掉标题和星星，字号增加5，扩展上下各一行，使用RichTextView支持颜色标记）
                                        // 使用 localizationManager 确保多语言更新时视图会刷新
                                        VStack(alignment: .leading, spacing: scaleHeight(15, windowHeight: windowHeight) * 1.5) {
                                            RichTextView(localizationManager.localized("goblins.\(goblin.nameKey).description"), defaultColor: .white, font: customFont(size: scaleSize(24, windowWidth: windowWidth) * 1.5 + 5), multilineTextAlignment: .leading)
                                                .lineSpacing(scaleHeight(8, windowHeight: windowHeight) * 1.5)
                                                .lineLimit(nil)
                                                .fixedSize(horizontal: false, vertical: true)
                                        }
                                        .padding(.top, scaleSize(30, windowWidth: windowWidth) * 1.5 + (scaleSize(24, windowWidth: windowWidth) * 1.5 + 5) * 1.2) // 向上扩展一行
                                        .padding(.bottom, scaleSize(30, windowWidth: windowWidth) * 1.5 + (scaleSize(24, windowWidth: windowWidth) * 1.5 + 5) * 1.2) // 向下扩展一行
                                        .padding(.horizontal, scaleSize(30, windowWidth: windowWidth) * 1.5 + 5) // 左右各拓展5像素
                                        .frame(maxWidth: scaleSize(600, windowWidth: windowWidth) * 1.5)
                                        .frame(minHeight: (scaleSize(24, windowWidth: windowWidth) * 1.5 + 5) * 1.2 * 3 + 20) // 至少能展示三行文本，扩大20像素高度
                                        .background(
                                            RoundedRectangle(cornerRadius: scaleSize(20, windowWidth: windowWidth) * 1.5)
                                                .fill(Color.black.opacity(0.3))
                                        )
                                    }
                            .offset(x: dragOffset)
                            .gesture(
                                DragGesture()
                                    .onChanged { value in
                                        dragOffset = value.translation.width
                                    }
                                    .onEnded { value in
                                                let threshold: CGFloat = scaleSize(50, windowWidth: windowWidth)
                                        if value.translation.width > threshold {
                                            // 向右滑，显示上一个（循环）
                                            withAnimation(.spring()) {
                                                        currentIndex = (currentIndex - 1 + displayGoblins.count) % displayGoblins.count
                                                dragOffset = 0
                                            }
                                        } else if value.translation.width < -threshold {
                                            // 向左滑，显示下一个（循环）
                                            withAnimation(.spring()) {
                                                        currentIndex = (currentIndex + 1) % displayGoblins.count
                                                dragOffset = 0
                                            }
                                        } else {
                                            // 回弹
                                            withAnimation(.spring()) {
                                                dragOffset = 0
                                            }
                                        }
                                    }
                            )
                        }
                                
                                // 左箭头按钮
                                if displayGoblins.count > 1 {
                                    HStack {
                                        Button(action: {
                                            print("🎭 [哥布林选择] 向左翻页")
                                            audioManager.playSoundEffect("click", fileExtension: "wav")
                                            withAnimation(.spring()) {
                                                currentIndex = (currentIndex - 1 + displayGoblins.count) % displayGoblins.count
                                            }
                                        }) {
                                            Image("arrow")
                                                .resizable()
                                                .scaledToFit()
                                                .frame(width: scaleSize(60, windowWidth: windowWidth) * 3, height: scaleSize(60, windowWidth: windowWidth) * 3)
                                                .rotationEffect(.degrees(180))
                                        }
                                        .padding(.leading, scaleSize(40, windowWidth: windowWidth))
                                        
                                        Spacer()
                    }
                }
                
                                // 右箭头按钮
                                if displayGoblins.count > 1 {
                                    HStack {
                Spacer()
                
                Button(action: {
                                            print("🎭 [哥布林选择] 向右翻页")
                                            audioManager.playSoundEffect("click", fileExtension: "wav")
                                            withAnimation(.spring()) {
                                                currentIndex = (currentIndex + 1) % displayGoblins.count
                                            }
                                        }) {
                                            Image("arrow")
                                                .resizable()
                                                .scaledToFit()
                                                .frame(width: scaleSize(60, windowWidth: windowWidth) * 3, height: scaleSize(60, windowWidth: windowWidth) * 3)
                                        }
                                        .padding(.trailing, scaleSize(40, windowWidth: windowWidth))
                                    }
                                }
                            }
                            .frame(height: scaleHeight(800, windowHeight: windowHeight))
                            
                            Spacer()
                            }
                        }
                        .frame(width: windowWidth, height: windowHeight)
                        .cornerRadius(scaleSize(20, windowWidth: windowWidth))
                        .shadow(color: .black.opacity(0.5), radius: 20, x: 0, y: 10)
                        .transition(.scale.combined(with: .opacity))
                        Spacer()
                    }
                    
                    // 底部确认按钮（移到弹窗之外，下移50像素，使用confirm图片）
                    if currentIndex < displayGoblins.count {
                        let currentGoblin = displayGoblins[currentIndex]
                        // 检查哥布林是否已解锁
                        let isUnlocked = currentGoblin.isFree || viewModel.unlockedGoblinIds.contains(currentGoblin.id)
                        
                        HStack {
                            Spacer()
                            Button(action: {
                                let goblin = displayGoblins[currentIndex]
                    print("🎭 [哥布林选择] 玩家选择了: \(goblin.name)")
                    
                    // 检查哥布林是否已解锁
                    if goblin.isFree || viewModel.unlockedGoblinIds.contains(goblin.id) {
                        // 免费或已解锁，播放开始音效并选择
                        audioManager.playSoundEffect("start", fileExtension: "wav")
                        selectedGoblin = goblin
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        isPresented = false
                                    }
                    } else {
                                    // 未拥有状态，跳转到商店-哥布林分页
                                    print("🎭 [哥布林选择] 哥布林未拥有，跳转到商店")
                                    print("🎭 [哥布林选择] onNavigateToStore回调是否存在: \(onNavigateToStore != nil)")
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                        isPresented = false
                                    }
                                    // 延迟一点执行，确保弹窗关闭动画完成
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                        print("🎭 [哥布林选择] 执行跳转到商店回调")
                                        onNavigateToStore?()
                                    }
                                }
                            }) {
                                ZStack {
                                    // 使用confirm图片作为背景（扩大2倍）
                                    Image("confirm")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: scaleSize(600, windowWidth: windowWidth) * 2, height: scaleSize(120, windowWidth: windowWidth) * 2)
                                    
                                    // 文本内容：start + 30 体力 + fruit图标（扩大2倍）
                                    HStack(spacing: scaleSize(15, windowWidth: windowWidth) * 2) {
                                        Text(localizationManager.localized("game.start"))
                                            .font(customFont(size: scaleSize(32, windowWidth: windowWidth) * 2))
                                            .foregroundColor(.white)
                                        
                                        Text("30")
                                            .font(customFont(size: scaleSize(28, windowWidth: windowWidth) * 2))
                    .foregroundColor(.white)
                                        
                                        Image("fruit")
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: scaleSize(30, windowWidth: windowWidth) * 2, height: scaleSize(30, windowWidth: windowWidth) * 2)
                                    }
                                }
                }
                            .padding(.top, -40) // 向上移动40像素
                            Spacer()
                        }
                    }
                    
                    Spacer()
                }
            }
        }
        .alert(localizationManager.localized("goblin.unlock_goblin"), isPresented: $showUnlockAlert) {
            if let goblin = goblinToUnlock {
                let currencyIcon = goblin.unlockCurrency == "diamonds" ? "💎" : "💰"
                let hasEnough = goblin.unlockCurrency == "diamonds" ? 
                    viewModel.diamonds >= goblin.unlockPrice : 
                    currentCoins >= goblin.unlockPrice
                
                if hasEnough {
                    Button("\(localizationManager.localized("goblin.confirm_unlock")) (\(goblin.unlockPrice) \(currencyIcon))") {
                        // 扣除货币并解锁
                        if goblin.unlockCurrency == "diamonds" {
                            if viewModel.unlockGoblin(goblinId: goblin.id, cost: goblin.unlockPrice) {
                                selectedGoblin = goblin
                                isPresented = false
                                print("🎭 [哥布林解锁] 成功解锁: \(goblin.name)")
                            }
                        } else {
                        currentCoins -= goblin.unlockPrice
                        unlockedGoblinIds.insert(goblin.id)
                        selectedGoblin = goblin
                        isPresented = false
                        print("🎭 [哥布林解锁] 成功解锁: \(goblin.name)")
                        }
                    }
                    Button(localizationManager.localized("confirmations.cancel"), role: .cancel) { }
                } else {
                    Button(localizationManager.localized("confirmations.confirm"), role: .cancel) { }
                }
            }
        } message: {
            if let goblin = goblinToUnlock {
                let currencyIcon = goblin.unlockCurrency == "diamonds" ? "💎" : "💰"
                let currencyName = goblin.unlockCurrency == "diamonds" ? localizationManager.localized("store.tabs.diamonds") : localizationManager.localized("goblin.price_suffix")
                let hasEnough = goblin.unlockCurrency == "diamonds" ? 
                    viewModel.diamonds >= goblin.unlockPrice : 
                    currentCoins >= goblin.unlockPrice
                let currentAmount = goblin.unlockCurrency == "diamonds" ? viewModel.diamonds : currentCoins
                
                if hasEnough {
                    Text("\(localizationManager.localized("goblin.unlock_confirm")) \(goblin.unlockPrice) \(currencyIcon) \(localizationManager.localized("goblin.unlock")) \(goblin.name)？")
                } else {
                    Text("\(localizationManager.localized("goblin.insufficient_coins"))！\(localizationManager.localized("goblin.need")) \(goblin.unlockPrice) \(currencyIcon)，\(localizationManager.localized("goblin.current")) \(currentAmount) \(currencyIcon)。")
                }
            }
        }
        .onAppear {
            // 初始化时设置为0（第一个）
            currentIndex = 0
            print("🎭 [哥布林选择] 界面显示，当前索引: \(currentIndex)，共 \(displayGoblins.count) 个哥布林")
            if !displayGoblins.isEmpty {
                print("🎭 [哥布林选择] 当前显示: \(displayGoblins[currentIndex].name)")
            }
            // 背景遮罩渐现效果
            withAnimation(.easeIn(duration: 0.3)) {
                backgroundOpacity = 0.5
            }
        }
        .onChange(of: isPresented) { newValue in
            if !newValue {
                // 界面关闭时，背景遮罩渐隐效果
                withAnimation(.easeOut(duration: 0.3)) {
                    backgroundOpacity = 0
                }
            }
        }
    }
}

#Preview {
    GoblinSelectionView(
        selectedGoblin: .constant(nil),
        isPresented: .constant(true),
        unlockedGoblinIds: .constant([1, 2, 3]),
        currentCoins: .constant(50),
        viewModel: GameViewModel()
    )
}

