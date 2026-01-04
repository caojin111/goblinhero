//
//  DailySignInView.swift
//  A004
//
//  七日签到界面
//

import SwiftUI
import UIKit

struct DailySignInView: View {
    @ObservedObject var viewModel: GameViewModel
    @Binding var isPresented: Bool
    @ObservedObject var localizationManager = LocalizationManager.shared
    @ObservedObject var audioManager = AudioManager.shared
    
    // Figma 设计稿尺寸：1202 x 2622
    private let figmaWidth: CGFloat = 1202
    private let figmaHeight: CGFloat = 2622
    
    // 获取自定义字体
    private func customFont(size: CGFloat) -> Font {
        return FontManager.shared.customFont(size: size)
    }
    
    var body: some View {
            ZStack {
            // 半透明背景遮罩
            Color.black.opacity(0.5)
                .ignoresSafeArea()
                .onTapGesture {
                    audioManager.playSoundEffect("click", fileExtension: "wav")
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        isPresented = false
                    }
                }
            
            // 弹窗内容
            GeometryReader { geometry in
                // 检测是否为标准iPad或Pro（需要缩放至80%）
                let isPad = UIDevice.current.userInterfaceIdiom == .pad
                let screenWidth = UIScreen.main.bounds.width
                let screenHeight = UIScreen.main.bounds.height
                // 判断是否是标准iPad或Pro（横屏时宽度>=1024，竖屏时高度>1024）
                let needsScaling = isPad && (screenHeight > 1024 || screenWidth >= 1024)
                let deviceScale: CGFloat = needsScaling ? 0.8 : 1.0 // 标准iPad/Pro缩小到80%
                
                // 打印调试信息
                let _ = print("📐 [DailySignInView缩放] isPad: \(isPad), screenWidth: \(screenWidth), screenHeight: \(screenHeight), needsScaling: \(needsScaling), deviceScale: \(deviceScale)")
                
                let scaleX = geometry.size.width / figmaWidth
                let scaleY = geometry.size.height / figmaHeight
                
                // 弹窗背景图（Figma: x: 89, y: 599, 1044 x 1854）
                // 计算弹窗相关尺寸（在外层作用域定义，避免重复声明）
                let popupWidth = geometry.size.width * (1044 / 1202)
                let popupHeight = geometry.size.height * (1854 / 2622)
                let popupX = geometry.size.width / 2
                let popupY = geometry.size.height / 2 + 100 * (geometry.size.height / figmaHeight) // 整体向下移动100像素
                let relativeScaleX = popupWidth / 1044
                let relativeScaleY = popupHeight / 1854
                
                ZStack {
                    // 背景图片
                    Image("sign_in_content_bg")
                        .resizable()
                        .scaledToFit()
                        .frame(
                            width: popupWidth,
                            height: popupHeight
                        )
                    
                    ZStack {
                        // 标题区域（Figma: x: 221, y: 400, 761 x 300，相对于弹窗背景图）
                        // 统一向上移动400像素（200+200），向左移动150像素（50+100），向上移动100像素（40+40+20）
                        let titleWidth = 761 * relativeScaleX
                        let titleHeight = 300 * relativeScaleY
                        let titleX = popupX - popupWidth / 2 + 221 * relativeScaleX + titleWidth / 2 - 150 * relativeScaleX
                        let titleY = popupY - popupHeight / 2 + (400 - 599) * relativeScaleY + titleHeight / 2 - 400 * relativeScaleY + 40 * relativeScaleY - 40 * relativeScaleY - 20 * relativeScaleY
                        
                        // 关闭按钮（使用 Blue_Buttons）
                        // 向上移动480像素，向左移动30像素
                        Button(action: {
                            audioManager.playSoundEffect("click", fileExtension: "wav")
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                isPresented = false
                                }
                        }) {
                            Image("Blue_Buttons")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 140 * relativeScaleX, height: 140 * relativeScaleY)
                        }
                        .position(
                            x: popupX + popupWidth / 2 - 70 * relativeScaleX - 30 * relativeScaleX,
                            y: popupY - popupHeight / 2 + 70 * relativeScaleY - 480 * relativeScaleY
                        )
                        
                        Image("7day_title")
                            .resizable()
                            .scaledToFit()
                            .frame(width: titleWidth, height: titleHeight)
                            .position(x: titleX, y: titleY)
                            .zIndex(1000) // 层级最高
                    
                        // 7个签到卡片
                        SignInCardsView(
                            viewModel: viewModel,
                            geometry: geometry,
                            onRewardTap: { _ in }
                        )
                        
                        // 领取按钮（Figma: x: 276, y: 2206, 671 x 179，相对于弹窗背景图）
                        // 统一向上移动400像素（200+200），向左移动150像素（50+100），再向左移动20像素，向上移动130像素（30+100）
                        let buttonWidth = 671 * relativeScaleX
                        let buttonHeight = 179 * relativeScaleY
                        let buttonX = popupX - popupWidth / 2 + 276 * relativeScaleX + buttonWidth / 2 - 150 * relativeScaleX - 20 * relativeScaleX
                        let buttonY = popupY - popupHeight / 2 + (2206 - 599) * relativeScaleY + buttonHeight / 2 - 400 * relativeScaleY - 130 * relativeScaleY
                        
                        Button(action: {
                            if viewModel.performSignIn() {
                                audioManager.playSoundEffect("click", fileExtension: "wav")
                                // 签到成功，可以添加动画效果
                            }
                        }) {
                            ZStack {
                                Image("sign_in_button_bg")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: buttonWidth, height: buttonHeight)
                                
                                Text(viewModel.canSignInToday ?
                                     localizationManager.localized("sign_in.button.sign_in") :
                                     localizationManager.localized("sign_in.button.signed"))
                                    .font(customFont(size: 128 * relativeScaleX))
                            .foregroundColor(.white)
                                    .textStroke()
                                    }
                        }
                        .disabled(!viewModel.canSignInToday)
                        .opacity(viewModel.canSignInToday ? 1.0 : 0.6)
                        .position(x: buttonX, y: buttonY)
                                }
                }
                .frame(width: popupWidth, height: popupHeight)
                .position(x: popupX, y: popupY)
                .scaleEffect(deviceScale) // 在标准iPad/Pro上应用80%缩放
                .frame(width: geometry.size.width, height: geometry.size.height) // 确保缩放后仍然居中
                }
            }
        .transition(.scale.combined(with: .opacity))
    }
}

// MARK: - 签到卡片视图
struct SignInCardsView: View {
    @ObservedObject var viewModel: GameViewModel
    let geometry: GeometryProxy
    let onRewardTap: (SignInReward) -> Void
    @ObservedObject var localizationManager = LocalizationManager.shared
    
    // Figma 设计稿尺寸：1202 x 2622
    private let figmaWidth: CGFloat = 1202
    private let figmaHeight: CGFloat = 2622
    
    // 获取自定义字体
    private func customFont(size: CGFloat) -> Font {
        return FontManager.shared.customFont(size: size)
    }
    
    var rewards: [SignInReward] {
        viewModel.getAllSignInRewards()
    }
    
    var body: some View {
        // 弹窗背景图的尺寸和位置
        let popupWidth = geometry.size.width * (1044 / figmaWidth)
        let popupHeight = geometry.size.height * (1854 / figmaHeight)
        let popupX = geometry.size.width / 2
        let popupY = geometry.size.height / 2
        
        // 相对于弹窗背景图的坐标
        let relativeScaleX = popupWidth / 1044
        let relativeScaleY = popupHeight / 1854
        
        return ZStack {
            // 7个卡片的位置（根据Figma设计，相对于弹窗背景图）
            // Day 1-6: 282 x 462
            // Day 7: 892 x 368（今天的卡片，更大）
            
            // 第一行：Day 1, 2, 3
            cardView(
                index: 0,
                day: 1,
                figmaX: 155,
                figmaY: 700,
                width: 282,
                height: 462,
                popupX: popupX,
                popupY: popupY,
                popupWidth: popupWidth,
                popupHeight: popupHeight,
                relativeScaleX: relativeScaleX,
                relativeScaleY: relativeScaleY
            )
            
            cardView(
                index: 1,
                day: 2,
                figmaX: 460,
                figmaY: 700,
                width: 282,
                height: 462,
                popupX: popupX,
                popupY: popupY,
                popupWidth: popupWidth,
                popupHeight: popupHeight,
                relativeScaleX: relativeScaleX,
                relativeScaleY: relativeScaleY
            )
            
            cardView(
                index: 2,
                day: 3,
                figmaX: 765,
                figmaY: 700,
                width: 282,
                height: 462,
                popupX: popupX,
                popupY: popupY,
                popupWidth: popupWidth,
                popupHeight: popupHeight,
                relativeScaleX: relativeScaleX,
                relativeScaleY: relativeScaleY
            )
            
            // 第二行：Day 4, 5, 6（行间距缩短到10像素，从1177改为700+462+10=1172）
            cardView(
                index: 3,
                day: 4,
                figmaX: 155,
                figmaY: 1172, // 700 + 462 + 10 = 1172
                width: 282,
                height: 462,
                popupX: popupX,
                popupY: popupY,
                popupWidth: popupWidth,
                popupHeight: popupHeight,
                relativeScaleX: relativeScaleX,
                relativeScaleY: relativeScaleY
            )
            
            cardView(
                index: 4,
                day: 5,
                figmaX: 460,
                figmaY: 1172, // 700 + 462 + 10 = 1172
                width: 282,
                height: 462,
                popupX: popupX,
                popupY: popupY,
                popupWidth: popupWidth,
                popupHeight: popupHeight,
                relativeScaleX: relativeScaleX,
                relativeScaleY: relativeScaleY
            )
            
            cardView(
                index: 5,
                day: 6,
                figmaX: 765,
                figmaY: 1172, // 700 + 462 + 10 = 1172
                width: 282,
                height: 462,
                popupX: popupX,
                popupY: popupY,
                popupWidth: popupWidth,
                popupHeight: popupHeight,
                relativeScaleX: relativeScaleX,
                relativeScaleY: relativeScaleY
            )
            
            // Day 7 - 今天的卡片（Figma: x: 172, y: 1697, 892 x 368）
            cardView(
                index: 6,
                day: 7,
                figmaX: 172,
                figmaY: 1697,
                width: 892,
                height: 368,
                popupX: popupX,
                popupY: popupY,
                popupWidth: popupWidth,
                popupHeight: popupHeight,
                relativeScaleX: relativeScaleX,
                relativeScaleY: relativeScaleY
            )
                            }
    }
    
    // 计算卡片位置
    private func calculateCardPosition(
        day: Int,
        figmaX: CGFloat,
        figmaY: CGFloat,
        width: CGFloat,
        height: CGFloat,
        popupX: CGFloat,
        popupY: CGFloat,
        popupWidth: CGFloat,
        popupHeight: CGFloat,
        relativeScaleX: CGFloat,
        relativeScaleY: CGFloat
    ) -> CGPoint {
        let cardWidth = width * relativeScaleX
        let cardHeight = height * relativeScaleY
        
        // 基础位置：统一向上移动400像素（200+200），向左移动150像素（50+100）
        var finalCardX = popupX - popupWidth / 2 + figmaX * relativeScaleX + cardWidth / 2 - 150 * relativeScaleX
        var finalCardY = popupY - popupHeight / 2 + (figmaY - 599) * relativeScaleY + cardHeight / 2 - 400 * relativeScaleY
        
        // 第 1～6 天的卡片向左移动 10 像素，向下移动20 像素
        if day >= 1 && day <= 6 {
            finalCardX -= 10 * relativeScaleX
            finalCardY += 20 * relativeScaleY
        }
        
        // 1～3 天卡片整体下移30 像素
        if day >= 1 && day <= 3 {
            finalCardY += 30 * relativeScaleY
        }
        
        // 第 7 天卡片向左移动 20 像素，向上移动 20 像素
        if day == 7 {
            finalCardX -= 20 * relativeScaleX
            finalCardY -= 20 * relativeScaleY
        }
        
        return CGPoint(x: finalCardX, y: finalCardY)
    }
    
    // 辅助函数：创建单个卡片视图
    @ViewBuilder
    private func cardView(
        index: Int,
        day: Int,
        figmaX: CGFloat,
        figmaY: CGFloat,
        width: CGFloat,
        height: CGFloat,
        popupX: CGFloat,
        popupY: CGFloat,
        popupWidth: CGFloat,
        popupHeight: CGFloat,
        relativeScaleX: CGFloat,
        relativeScaleY: CGFloat
    ) -> some View {
        if rewards.count > index {
            let cardWidth = width * relativeScaleX
            let cardHeight = height * relativeScaleY
            let cardPosition = calculateCardPosition(
                day: day,
                figmaX: figmaX,
                figmaY: figmaY,
                width: width,
                height: height,
                popupX: popupX,
                popupY: popupY,
                popupWidth: popupWidth,
                popupHeight: popupHeight,
                relativeScaleX: relativeScaleX,
                relativeScaleY: relativeScaleY
            )
            
            SignInCardView(
                reward: rewards[index],
                viewModel: viewModel,
                geometry: geometry,
                cardType: getCardType(day: day),
                position: cardPosition,
                size: CGSize(width: cardWidth, height: cardHeight),
                isToday: isTodayCard(day: day),
                onTap: { onRewardTap(rewards[index]) }
            )
        }
    }
    
    // 获取卡片类型
    private func getCardType(day: Int) -> SignInCardType {
        let rewardDay = day
        let isClaimed = rewardDay < viewModel.signInDay
        let isToday = rewardDay == viewModel.signInDay && viewModel.canSignInToday
        
        // 第7天始终使用 day_card_today 背景图
        if rewardDay == 7 {
            return .today
        }
        
        // Day 1-6的逻辑
        if isToday {
            // 今天可签到，使用 day_card_normal
            return .normal
        } else if isClaimed {
            // 已领取
            return .claimed
        } else {
            // 未领取（使用 day_card_normal）
            return .normal
                    }
                }
    
    // 判断是否是今天可签到的卡片（用于呼吸效果）
    private func isTodayCard(day: Int) -> Bool {
        let rewardDay = day
        return rewardDay == viewModel.signInDay && viewModel.canSignInToday
            }
        }

// MARK: - 卡片类型枚举
enum SignInCardType {
    case normal      // 未领取
    case claimed     // 已领取
    case today       // 今天可领取（第7天）
}

// MARK: - 单个签到卡片视图
struct SignInCardView: View {
    let reward: SignInReward
    @ObservedObject var viewModel: GameViewModel
    let geometry: GeometryProxy
    let cardType: SignInCardType
    let position: CGPoint
    let size: CGSize
    let isToday: Bool
    let onTap: () -> Void
    @ObservedObject var localizationManager = LocalizationManager.shared
    
    @State private var breathingScale: CGFloat = 1.0
    
    // Figma 设计稿尺寸：1202 x 2622
    private let figmaWidth: CGFloat = 1202
    private let figmaHeight: CGFloat = 2622
    
    // 获取自定义字体
    private func customFont(size: CGFloat) -> Font {
        return FontManager.shared.customFont(size: size)
    }
    
    var body: some View {
        let scaleX = geometry.size.width / figmaWidth
        let scaleY = geometry.size.height / figmaHeight
        
        Button(action: onTap) {
                ZStack {
                // 卡片背景图（添加呼吸效果和外发光效果）
                Image(cardImageName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: size.width, height: size.height)
                    .scaleEffect(breathingScale)
                    .shadow(
                        color: isToday && cardType == .normal ? Color.yellow.opacity(0.8) : Color.clear,
                        radius: isToday && cardType == .normal ? 15 * breathingScale : 0,
                        x: 0,
                        y: 0
                        )
                    .shadow(
                        color: isToday && cardType == .normal ? Color.yellow.opacity(0.6) : Color.clear,
                        radius: isToday && cardType == .normal ? 25 * breathingScale : 0,
                        x: 0,
                        y: 0
                    )
                    
                // 卡片内容
                // 第一天和第七天使用和第2天一样的样式
                VStack(spacing: 0) {
                    // DAY文字在数字右方
                    HStack(spacing: 10 * scaleX) {
                        Text("\(reward.day)")
                            .font(customFont(size: (200 - 10) * scaleX)) // 减小10号
                            .foregroundColor(.white)
                            .textStroke(color: Color(hex: "565BA9"), width: 1) // 描边改为1
                        
                        Text("DAY")
                            .font(customFont(size: 60 * scaleX))
                            .foregroundColor(.white)
                            .textStroke(color: Color(hex: "565BA9"), width: 1) // 描边改为1
                    }
                    .offset(x: reward.day == 7 ? -280 * scaleX : 0) // 第7天：向左移动280像素（200+80）
                    .offset(y: reward.day == 7 ? 40 * scaleY : 0) // 第7天：向下移动40像素
                
                    // 奖励图标（1～6 天卡片的奖励图片上移 30 像素）
                    if let iconImage = rewardIconImage {
                        Image(iconImage)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 140 * scaleX, height: 126 * scaleY)
                            .padding(.top, reward.day <= 6 ? 0 * scaleY : 20 * scaleY) // 1～6天：0像素（通过offset上移），第7天：20像素
                            .offset(y: reward.day <= 6 ? -30 * scaleY : 0) // 1～6天：上移30像素
                            .offset(x: reward.day == 7 ? -200 * scaleX : 0) // 第7天：向左移动200像素
                            .offset(y: reward.day == 7 ? -50 * scaleY : 0) // 第7天：向上移动50像素
}

                    // 奖励描述（上移20像素，使用多语言，数字使用黄色字体）
                    getRewardDescriptionView()
                        .padding(.horizontal, 20 * scaleX)
                        .offset(y: reward.day == 7 ? -50 * scaleY : -20 * scaleY) // 第7天：上移50像素，其他：上移20像素
                        .offset(x: reward.day == 7 ? -200 * scaleX : 0) // 第7天：向左移动200像素
                }
    }
}
        .buttonStyle(PlainButtonStyle())
        .position(x: position.x, y: position.y)
        .onAppear {
            // 如果是今天可签到的卡片，添加呼吸效果
            if isToday {
                withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                    breathingScale = 1.05
                    }
                }
        }
        .onChange(of: isToday) { newValue in
            if newValue {
                // 变成今天可签到时，启动呼吸效果
                withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                    breathingScale = 1.05
                    }
            } else {
                // 不再是今天可签到时，停止呼吸效果
                withAnimation {
                    breathingScale = 1.0
                }
            }
        }
    }
    
    // 获取卡片背景图名称
    private var cardImageName: String {
        switch cardType {
        case .normal:
            return "day_card_normal"
        case .claimed:
            return "day_card_claimed"
        case .today:
            return "day_card_today"
                    }
                }
    
    // 获取奖励图标图片名称
    private var rewardIconImage: String? {
        switch reward.type {
        case .diamonds:
            return "diamond_1" // 钻石奖励图标
        case .coins:
            return nil // 可能需要添加金币图标
        case .stamina:
            return "stamina_1" // 体力奖励图标
        }
    }
    
    // 获取奖励描述（多语言）
    private func getRewardDescription() -> String {
        let amount = reward.amount
        let typeKey: String
        switch reward.type {
        case .diamonds:
            typeKey = "sign_in.reward_type.diamonds"
        case .stamina:
            typeKey = "sign_in.reward_type.stamina"
        case .coins:
            typeKey = "sign_in.reward_type.coins"
        }
        let typeName = localizationManager.localized(typeKey)
        return "\(amount) \(typeName)"
    }
    
    // 获取奖励描述视图（数字使用黄色字体，字号大5号）
    @ViewBuilder
    private func getRewardDescriptionView() -> some View {
        let scaleX = geometry.size.width / figmaWidth
        let amount = reward.amount
        
        // 获取类型名称
        let typeKey: String = {
            switch reward.type {
            case .diamonds:
                return "sign_in.reward_type.diamonds"
            case .stamina:
                return "sign_in.reward_type.stamina"
            case .coins:
                return "sign_in.reward_type.coins"
            }
        }()
        let typeName = localizationManager.localized(typeKey)
        
        HStack(spacing: 4 * scaleX) {
            // 数字：字号比正文大5号（36+5=41），黄色字体，黑色描边（最小字重）
            Text("\(amount)")
                .font(customFont(size: (36 + 5) * scaleX))
                .foregroundColor(.yellow) // 代表金币的黄色
                .textStroke(color: .black, width: 0.5) // 黑色描边，最小字重
            
            // 文字：正常字号，黑色字体
            Text(typeName)
                .font(customFont(size: 36 * scaleX))
                .foregroundColor(.black)
        }
        .multilineTextAlignment(.center)
    }
}

#Preview {
    DailySignInView(viewModel: GameViewModel(), isPresented: .constant(true))
}
