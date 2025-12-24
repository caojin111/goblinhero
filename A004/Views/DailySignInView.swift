//
//  DailySignInView.swift
//  A004
//
//  七日签到界面
//

import SwiftUI

struct DailySignInView: View {
    @ObservedObject var viewModel: GameViewModel
    @Binding var isPresented: Bool
    @ObservedObject var localizationManager = LocalizationManager.shared
    @ObservedObject var audioManager = AudioManager.shared
    
    @State private var showRewardDetail: Bool = false
    @State private var selectedReward: SignInReward?
    @State private var pulseAnimation: Bool = false
    
    // 获取自定义字体
    private func customFont(size: CGFloat) -> Font {
        return FontManager.shared.customFont(size: size)
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
                    // 标题区域
                    VStack(spacing: 10) {
                        Text("📅")
                            .font(.system(size: 60))
                        Text(localizationManager.localized("sign_in.title"))
                            .font(customFont(size: 33)) // 从 28 增加到 33（+5）
                            .foregroundColor(.white)
                        Text(localizationManager.localized("sign_in.subtitle"))
                            .font(customFont(size: 14))
                            .foregroundColor(.white.opacity(0.8))
                    }
                    .padding(.top, 20)
                    .padding(.bottom, 30)
                    
                    // 7日连线图
                    ScrollView {
                        SignInTimelineView(
                            viewModel: viewModel,
                            onRewardTap: { reward in
                                selectedReward = reward
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                    showRewardDetail = true
                                }
                            }
                        )
                        .padding(.horizontal, 20)
                        .padding(.vertical, 20)
                    }
                    
                    // 底部签到按钮
                    VStack(spacing: 15) {
                        Button(action: {
                            if viewModel.performSignIn() {
                                // 签到成功，触发动画
                                withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                                    pulseAnimation = true
                                }
                                
                                // 延迟后重置动画
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                    pulseAnimation = false
                                }
                            }
                        }) {
                            HStack(spacing: 12) {
                                Image(systemName: viewModel.canSignInToday ? "checkmark.circle.fill" : "checkmark.circle")
                                    .font(.title2)
                                
                                Text(viewModel.canSignInToday ?
                                     localizationManager.localized("sign_in.button.sign_in") :
                                     localizationManager.localized("sign_in.button.signed"))
                                    .font(customFont(size: 20))
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                Group {
                                    if viewModel.canSignInToday {
                                        // 可签到时的高亮动效
                                        LinearGradient(
                                            gradient: Gradient(colors: [
                                                Color.green,
                                                Color.blue,
                                                Color.purple
                                            ]),
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    } else {
                                        // 已签到时置灰
                                        LinearGradient(
                                            gradient: Gradient(colors: [
                                                Color.gray,
                                                Color.gray.opacity(0.7)
                                            ]),
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    }
                                }
                            )
                            .cornerRadius(20)
                            .overlay(
                                // 脉冲动画边框（仅可签到时显示）
                                Group {
                                    if viewModel.canSignInToday {
                                        RoundedRectangle(cornerRadius: 20)
                                            .stroke(Color.white.opacity(pulseAnimation ? 0.8 : 0.3), lineWidth: pulseAnimation ? 4 : 2)
                                            .scaleEffect(pulseAnimation ? 1.05 : 1.0)
                                    }
                                }
                            )
                            .shadow(color: viewModel.canSignInToday ? Color.green.opacity(pulseAnimation ? 0.8 : 0.5) : Color.clear, radius: pulseAnimation ? 20 : 5, x: 0, y: 5)
                        }
                        .disabled(!viewModel.canSignInToday)
                        .onAppear {
                            if viewModel.canSignInToday {
                                // 启动脉冲动画
                                withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                                    pulseAnimation = true
                                }
                            }
                        }
                        .onChange(of: viewModel.canSignInToday) { canSign in
                            if canSign {
                                // 可签到时启动动画
                                withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                                    pulseAnimation = true
                                }
                            } else {
                                // 已签到时停止动画
                                pulseAnimation = false
                            }
                        }
                        
                        // 提示文字
                        Text(viewModel.canSignInToday ?
                             localizationManager.localized("sign_in.hint.can_sign") :
                             localizationManager.localized("sign_in.hint.signed"))
                            .font(customFont(size: 12))
                            .foregroundColor(.white.opacity(0.7))
                    }
                    .padding(.horizontal, 30)
                    .padding(.bottom, 30)
                }
                
                // 奖励详情小弹窗
                if showRewardDetail, let reward = selectedReward {
                    RewardDetailPopup(
                        reward: reward,
                        localizationManager: localizationManager,
                        isPresented: $showRewardDetail
                    )
                    .zIndex(1000)
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        audioManager.playSoundEffect("click", fileExtension: "wav")
                        isPresented = false
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.white)
                    }
                }
            }
        }
    }
}

// MARK: - 签到时间线视图
struct SignInTimelineView: View {
    @ObservedObject var viewModel: GameViewModel
    let onRewardTap: (SignInReward) -> Void
    
    var rewards: [SignInReward] {
        viewModel.getAllSignInRewards()
    }
    
    var body: some View {
        VStack(spacing: 0) {
            ForEach(Array(rewards.enumerated()), id: \.element.day) { index, reward in
                HStack(spacing: 0) {
                    // 左侧：奖励节点
                    VStack(spacing: 8) {
                        // 计算当前奖励的天数（index + 1）
                        let rewardDay = index + 1
                        // 已领取：天数小于当前应该签到的天数（不包括今天）
                        // 如果今天已签到，signInDay 已经更新为下一个天数，所以 rewardDay < signInDay 表示已领取
                        // 如果今天未签到，signInDay 是今天应该签的天数，所以 rewardDay < signInDay 表示已领取
                        let isClaimed = rewardDay < viewModel.signInDay
                        // 今日可签到：是今天应该签的天数且可签到
                        // 如果今天已签到，signInDay 已经更新，所以不会有 isToday
                        // 如果今天未签到，signInDay 是今天应该签的天数
                        let isToday = rewardDay == viewModel.signInDay && viewModel.canSignInToday
                        
                        RewardNodeView(
                            reward: reward,
                            isClaimed: isClaimed,
                            isToday: isToday,
                            onTap: {
                                onRewardTap(reward)
                            }
                        )
                    }
                    .frame(width: 120)
                    
                    // 右侧：连线（除了最后一个）
                    if index < rewards.count - 1 {
                        ZStack(alignment: .leading) {
                            // 连线背景
                            Rectangle()
                                .fill(Color.white.opacity(0.2))
                                .frame(height: 2)
                            
                            // 已签到的连线（高亮）：当前奖励的天数小于当前应该签到的天数
                            let rewardDay = index + 1
                            if rewardDay < viewModel.signInDay {
                                Rectangle()
                                    .fill(
                                        LinearGradient(
                                            gradient: Gradient(colors: [Color.green, Color.blue]),
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .frame(height: 2)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.leading, 20)
                    }
                }
                .padding(.vertical, 15)
            }
        }
    }
}

// MARK: - 奖励节点视图
struct RewardNodeView: View {
    let reward: SignInReward
    let isClaimed: Bool
    let isToday: Bool
    let onTap: () -> Void
    @State private var isPressed: Bool = false
    @ObservedObject var localizationManager = LocalizationManager.shared
    
    // 获取自定义字体
    private func customFont(size: CGFloat) -> Font {
        return FontManager.shared.customFont(size: size)
    }
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 6) {
                // 天数标签
                Text("\(localizationManager.localized("sign_in.day")) \(reward.day)")
                    .font(customFont(size: 12))
                    .foregroundColor(isToday ? .yellow : (isClaimed ? .green : .white.opacity(0.7)))
                
                // 奖励图标和数量
                ZStack {
                    // 背景圆圈
                    Circle()
                        .fill(
                            isToday ?
                            // 今日可签到：高亮
                            LinearGradient(
                                gradient: Gradient(colors: [Color.yellow.opacity(0.8), Color.orange.opacity(0.8)]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ) :
                            (isClaimed ?
                             // 已领取：绿色
                             LinearGradient(
                                 gradient: Gradient(colors: [Color.green.opacity(0.8), Color.blue.opacity(0.8)]),
                                 startPoint: .topLeading,
                                 endPoint: .bottomTrailing
                             ) :
                             // 未领取：灰色
                             LinearGradient(
                                 gradient: Gradient(colors: [Color.gray.opacity(0.5), Color.gray.opacity(0.3)]),
                                 startPoint: .topLeading,
                                 endPoint: .bottomTrailing
                             ))
                        )
                        .frame(width: 70, height: 70)
                        .overlay(
                            Circle()
                                .stroke(isToday ? Color.yellow : (isClaimed ? Color.green : Color.white.opacity(0.3)), lineWidth: isToday ? 3 : 2)
                        )
                        .shadow(color: isToday ? Color.yellow.opacity(0.5) : Color.clear, radius: isToday ? 10 : 0)
                    
                    // 奖励内容
                    VStack(spacing: 2) {
                        Text(reward.type.icon)
                            .font(.system(size: 28))
                        Text("\(reward.amount)")
                            .font(customFont(size: 12))
                            .foregroundColor(.white)
                    }
                }
                
                // 状态标签
                if isClaimed {
                    Text(localizationManager.localized("sign_in.status.claimed"))
                        .font(customFont(size: 10))
                        .foregroundColor(.green)
                } else if isToday {
                    Text(localizationManager.localized("sign_in.status.today"))
                        .font(customFont(size: 10))
                        .foregroundColor(.yellow)
                }
            }
        }
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
    }
}

// MARK: - 奖励详情小弹窗
struct RewardDetailPopup: View {
    let reward: SignInReward
    @ObservedObject var localizationManager: LocalizationManager
    @ObservedObject var audioManager = AudioManager.shared
    @Binding var isPresented: Bool
    
    // 获取自定义字体
    private func customFont(size: CGFloat) -> Font {
        return FontManager.shared.customFont(size: size)
    }
    
    var body: some View {
        ZStack {
            // 半透明背景
            Color.black.opacity(0.5)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        isPresented = false
                    }
                }
            
            // 弹窗内容
            VStack(spacing: 20) {
                // 关闭按钮
                HStack {
                    Spacer()
                    Button(action: {
                        audioManager.playSoundEffect("click", fileExtension: "wav")
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            isPresented = false
                        }
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
                .padding(.top, 10)
                .padding(.trailing, 10)
                
                // 奖励图标
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.yellow.opacity(0.8),
                                    Color.orange.opacity(0.8)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 100, height: 100)
                        .shadow(color: Color.yellow.opacity(0.5), radius: 15)
                    
                    VStack(spacing: 6) {
                        Text(reward.type.icon)
                            .font(.system(size: 40))
                        Text("\(reward.amount)")
                            .font(customFont(size: 20))
                            .foregroundColor(.white)
                    }
                }
                
                // 奖励信息
                VStack(spacing: 12) {
                    Text("\(localizationManager.localized("sign_in.day")) \(reward.day)")
                        .font(customFont(size: 20))
                        .foregroundColor(.white)
                    
                    Text(reward.description)
                        .font(customFont(size: 17))
                        .foregroundColor(.white.opacity(0.9))
                    
                    Text(localizationManager.localized("sign_in.reward_type.\(reward.type == .diamonds ? "diamonds" : reward.type == .coins ? "coins" : "stamina")"))
                        .font(customFont(size: 14))
                        .foregroundColor(.white.opacity(0.7))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.white.opacity(0.2))
                        )
                }
                
                Spacer()
                    .frame(height: 10)
            }
            .padding(25)
            .frame(width: 280)
            .background(
                RoundedRectangle(cornerRadius: 25)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.purple.opacity(0.95),
                                Color.blue.opacity(0.95)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(color: Color.black.opacity(0.3), radius: 20, x: 0, y: 10)
            )
        }
        .transition(.scale.combined(with: .opacity))
    }
}

#Preview {
    DailySignInView(viewModel: GameViewModel(), isPresented: .constant(true))
}

