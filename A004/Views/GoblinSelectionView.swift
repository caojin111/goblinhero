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
    
    @State private var currentIndex: Int = 0
    @State private var dragOffset: CGFloat = 0
    @State private var showUnlockAlert: Bool = false
    @State private var goblinToUnlock: Goblin?
    
    let goblins = Goblin.allGoblins
    
    // 获取自定义字体
    private func customFont(size: CGFloat) -> Font {
        return FontManager.shared.customFont(size: size)
    }
    
    var body: some View {
        ZStack {
            // 背景
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.green.opacity(0.6),
                    Color.blue.opacity(0.4)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 30) {
                // 标题
                VStack(spacing: 10) {
                    Text(localizationManager.localized("goblin.select_title"))
                        .font(customFont(size: 34))
                        .foregroundColor(.white)
                        .textStroke()

                    Text(localizationManager.localized("goblin.swipe_hint"))
                        .font(customFont(size: 14))
                        .foregroundColor(.white.opacity(0.8))
                        .textStroke()
                }
                .padding(.top, 40)
                
                // 哥布林卡片轮播
                ZStack {
                    ForEach(Array(goblins.enumerated()), id: \.element.id) { index, goblin in
                        if index == currentIndex {
                            GoblinCardView(
                                goblin: goblin,
                                isUnlocked: goblin.isFree || unlockedGoblinIds.contains(goblin.id),
                                currentCoins: currentCoins,
                                currentDiamonds: viewModel.diamonds
                            )
                            .transition(.asymmetric(
                                insertion: .move(edge: dragOffset > 0 ? .leading : .trailing).combined(with: .opacity),
                                removal: .move(edge: dragOffset > 0 ? .trailing : .leading).combined(with: .opacity)
                            ))
                            .offset(x: dragOffset)
                            .gesture(
                                DragGesture()
                                    .onChanged { value in
                                        dragOffset = value.translation.width
                                    }
                                    .onEnded { value in
                                        let threshold: CGFloat = 50
                                        if value.translation.width > threshold {
                                            // 向右滑，显示上一个（循环）
                                            withAnimation(.spring()) {
                                                currentIndex = (currentIndex - 1 + goblins.count) % goblins.count
                                                dragOffset = 0
                                            }
                                        } else if value.translation.width < -threshold {
                                            // 向左滑，显示下一个（循环）
                                            withAnimation(.spring()) {
                                                currentIndex = (currentIndex + 1) % goblins.count
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
                    }
                }
                .frame(height: 450)
                
                // 指示器
                HStack(spacing: 12) {
                    ForEach(0..<goblins.count, id: \.self) { index in
                        Circle()
                            .fill(index == currentIndex ? Color.white : Color.white.opacity(0.3))
                            .frame(width: index == currentIndex ? 12 : 8, height: index == currentIndex ? 12 : 8)
                            .animation(.spring(), value: currentIndex)
                    }
                }
                
                Spacer()
                
                // 确认按钮
                Button(action: {
                    let goblin = goblins[currentIndex]
                    print("🎭 [哥布林选择] 玩家选择了: \(goblin.name)")
                    
                    // 检查是否已解锁
                    if goblin.isFree || unlockedGoblinIds.contains(goblin.id) {
                        // 免费或已解锁，直接选择
                        selectedGoblin = goblin
                        isPresented = false
                    } else {
                        // 需要解锁
                        goblinToUnlock = goblin
                        showUnlockAlert = true
                    }
                }) {
                    let currentGoblin = goblins[currentIndex]
                    let isUnlocked = currentGoblin.isFree || unlockedGoblinIds.contains(currentGoblin.id)
                    let currencyIcon = currentGoblin.unlockCurrency == "diamonds" ? "💎" : "💰"
                    let currencyAmount = currentGoblin.unlockCurrency == "diamonds" ? viewModel.diamonds : currentCoins
                    let canUnlock = isUnlocked || (currentGoblin.unlockCurrency == "diamonds" ? viewModel.diamonds >= currentGoblin.unlockPrice : currentCoins >= currentGoblin.unlockPrice)

                    HStack(spacing: 12) {
                        Image(systemName: isUnlocked ? "checkmark.circle.fill" : "lock.fill")
                            .font(.title2)

                        Text(isUnlocked ?
                             "\(localizationManager.localized("goblin.select")) \(currentGoblin.name)" :
                             "\(localizationManager.localized("goblin.unlock")) \(currentGoblin.name) (\(currentGoblin.unlockPrice) \(currencyIcon))")
                            .font(customFont(size: 20))
                            .textStroke()
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: isUnlocked ? 
                                [Color.green, Color.blue] : 
                                (canUnlock ? [Color.orange, Color.red] : [Color.gray, Color.gray.opacity(0.7)])),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .disabled(!isUnlocked && !canUnlock)
                    .cornerRadius(20)
                    .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
                }
                .padding(.horizontal, 30)
                .padding(.bottom, 40)
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
    }
}

// MARK: - 哥布林卡片视图
struct GoblinCardView: View {
    @ObservedObject var localizationManager = LocalizationManager.shared
    let goblin: Goblin
    let isUnlocked: Bool
    let currentCoins: Int
    let currentDiamonds: Int
    
    // 获取自定义字体
    private func customFont(size: CGFloat) -> Font {
        return FontManager.shared.customFont(size: size)
    }
    
    var body: some View {
        VStack(spacing: 25) {
            // 哥布林图标
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
                    .frame(width: 160, height: 160)
                    .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
                
                if isUnlocked {
                    Text(goblin.icon)
                        .font(.system(size: 100))
                } else {
                    // 锁定状态显示锁图标
                    VStack(spacing: 10) {
                        Text("🔒")
                            .font(.system(size: 60))
                        Text(goblin.icon)
                            .font(.system(size: 50))
                            .opacity(0.3)
                    }
                }
            }
            
            // 哥布林名称
            HStack(spacing: 10) {
                Text(goblin.name)
                    .font(customFont(size: 28))
                    .foregroundColor(.white)
                    .textStroke()
                
                if !isUnlocked {
                    Text("🔒")
                        .font(.title3)
                }
            }
            
            // 免费/付费标签
            if goblin.isFree {
                Text(localizationManager.localized("goblin.free"))
                    .font(customFont(size: 12))
                    .foregroundColor(.white)
                    .textStroke()
                    .padding(.horizontal, 16)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(Color.green)
                    )
            } else {
                let currencyIcon = goblin.unlockCurrency == "diamonds" ? "💎" : "💰"
                let hasEnough = goblin.unlockCurrency == "diamonds" ? 
                    currentDiamonds >= goblin.unlockPrice : 
                    currentCoins >= goblin.unlockPrice
                
                HStack(spacing: 5) {
                    Text("\(goblin.unlockPrice)")
                        .font(customFont(size: 12))
                        .textStroke()
                    Text(currencyIcon)
                        .font(.caption)
                }
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(isUnlocked ? Color.blue : (hasEnough ? Color.orange : Color.gray))
                )
            }
            
            // buff描述（增加显示区域）
            VStack(spacing: 15) {
                HStack {
                    Text("⭐ \(localizationManager.localized("goblin.special_ability"))")
                        .font(customFont(size: 17))
                        .foregroundColor(.yellow)
                        .textStroke()
                    Spacer()
                }
                
                Text(goblin.buff)
                    .font(customFont(size: 20))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.leading)
                    .lineSpacing(6)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 5)
                    .textStroke()
            }
            .padding(20)
            .frame(maxWidth: .infinity, minHeight: 100)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.black.opacity(0.3))
            )
        }
        .padding(30)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 30)
                .fill(Color.white.opacity(0.15))
                .overlay(
                    RoundedRectangle(cornerRadius: 30)
                        .stroke(Color.white.opacity(0.3), lineWidth: 2)
                )
                .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10)
        )
        .padding(.horizontal, 40)
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

