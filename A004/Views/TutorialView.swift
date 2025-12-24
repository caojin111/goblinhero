//
//  TutorialView.swift
//  A004
//
//  新手教程视图
//

import SwiftUI

struct TutorialView: View {
    @ObservedObject var localizationManager = LocalizationManager.shared
    @Binding var isPresented: Bool
    @State private var currentStep: Int = 0
    
    // 教程步骤数据
    let steps: [TutorialStep]
    
    // 获取自定义字体
    private func customFont(size: CGFloat) -> Font {
        return FontManager.shared.customFont(size: size)
    }
    
    var body: some View {
        ZStack {
            // 高亮区域（通过遮罩挖洞实现）- 包含遮罩层
            if !steps.isEmpty && currentStep < steps.count {
                let step = steps[currentStep]
                TutorialHighlightView(
                    highlightFrame: step.highlightFrame,
                    highlightCornerRadius: step.highlightCornerRadius
                )
            } else if steps.isEmpty {
                // 如果没有步骤，显示完整遮罩
                Color.black.opacity(0.7)
                    .ignoresSafeArea()
            }
            
            // 阻止点击穿透到底层（除了按钮区域）
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture {
                    // 点击遮罩区域不关闭教程，阻止事件穿透
                }
            
            // 提示内容区域（固定在聚焦区域上方，三个步骤统一位置）
            GeometryReader { geometry in
                if !steps.isEmpty && currentStep < steps.count {
                    let step = steps[currentStep]
                    
                    // 计算文字介绍框的位置（固定在聚焦区域上方150像素）
                    let tipCardY = step.highlightFrame.minY - 150
                    
                    VStack(spacing: 0) {
                        // 头像图片（固定在文本框正上方0像素处）
                        Image("tutorial_avatar")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 120, height: 120) // 扩大1.5倍（80 * 1.5 = 120）
                            .padding(.bottom, 0) // 文本框上方0像素
                        
                        // 提示卡片（固定在聚焦区域上方）
                    TutorialTipCard(
                        title: step.title,
                        description: step.description,
                        localizationManager: localizationManager
                    )
                    .padding(.horizontal, 30)
                        .frame(maxWidth: .infinity)
                    
                        // 下一步/完成按钮（固定在文字介绍框下方20像素）
                    Button(action: {
                        if !steps.isEmpty && currentStep < steps.count - 1 {
                            withAnimation {
                                currentStep += 1
                            }
                        } else {
                            // 最后一步，完成教程
                            completeTutorial()
                        }
                    }) {
                        HStack(spacing: 8) {
                            Text((!steps.isEmpty && currentStep < steps.count - 1) ?
                                 localizationManager.localized("tutorial.next") :
                                 localizationManager.localized("tutorial.complete"))
                            if !steps.isEmpty && currentStep < steps.count - 1 {
                                Image(systemName: "chevron.right")
                            }
                        }
                        .font(customFont(size: 16))
                        .foregroundColor(.white)
                        .textStroke()
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.blue, Color.purple]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(25)
                        .shadow(color: .black.opacity(0.3), radius: 5, x: 0, y: 3)
                    }
                        .padding(.top, 20) // 文字介绍框下方20像素
                    }
                    .frame(width: geometry.size.width)
                    .position(
                        x: geometry.size.width / 2,
                        y: tipCardY // 使用计算出的位置
                    )
                }
            }
            
            // 顶部 Skip 按钮
            VStack {
                HStack {
                    Spacer()
                    Button(action: {
                        skipTutorial()
                    }) {
                        Text(localizationManager.localized("tutorial.skip"))
                            .font(customFont(size: 16))
                            .foregroundColor(.white.opacity(0.8))
                            .textStroke()
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(Color.black.opacity(0.5))
                            )
                    }
                    .padding(.top, 20)
                    .padding(.trailing, 20)
                }
                Spacer()
            }
        }
    }
    
    /// 跳过教程
    private func skipTutorial() {
        print("📚 [新手教程] 用户跳过教程")
        markTutorialCompleted()
        isPresented = false
    }
    
    /// 完成教程
    private func completeTutorial() {
        print("📚 [新手教程] 用户完成教程")
        markTutorialCompleted()
        isPresented = false
    }
    
    /// 标记教程已完成
    private func markTutorialCompleted() {
        UserDefaults.standard.set(true, forKey: "hasCompletedTutorial")
    }
}

// MARK: - 教程步骤数据模型
struct TutorialStep {
    let title: String // 本地化键
    let description: String // 本地化键
    let highlightFrame: CGRect // 高亮区域的位置和大小
    let highlightCornerRadius: CGFloat // 高亮区域的圆角
    let arrowPosition: CGPoint? // 箭头位置（相对于屏幕中心）
    let arrowDirection: ArrowDirection // 箭头方向
    let arrowOffset: CGFloat // 箭头垂直偏移
    
    enum ArrowDirection {
        case up
        case down
        case left
        case right
    }
}

// MARK: - 高亮区域视图（遮罩挖洞）
struct TutorialHighlightView: View {
    let highlightFrame: CGRect
    let highlightCornerRadius: CGFloat
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // 半透明黑色遮罩（全屏）
                Color.black.opacity(0.7)
                    .ignoresSafeArea()
                
                // 挖洞（高亮区域）- 使用 blendMode 实现挖洞效果
                RoundedRectangle(cornerRadius: highlightCornerRadius)
                    .fill(Color.white)
                    .frame(
                        width: highlightFrame.width,
                        height: highlightFrame.height
                    )
                    .position(
                        x: highlightFrame.midX,
                        y: highlightFrame.midY
                    )
                    .blendMode(.destinationOut)
            }
            .compositingGroup()
        }
    }
}

// MARK: - 箭头视图
struct TutorialArrowView: View {
    let position: CGPoint
    let direction: TutorialStep.ArrowDirection
    
    var body: some View {
        Image(systemName: arrowIconName)
            .font(.system(size: 40, weight: .bold))
            .foregroundColor(.yellow)
            .shadow(color: .black.opacity(0.5), radius: 3, x: 0, y: 2)
            .rotationEffect(.degrees(rotationAngle))
            .offset(x: position.x, y: position.y)
    }
    
    private var arrowIconName: String {
        switch direction {
        case .up: return "arrow.down"
        case .down: return "arrow.up"
        case .left: return "arrow.right"
        case .right: return "arrow.left"
        }
    }
    
    private var rotationAngle: Double {
        switch direction {
        case .up: return 0
        case .down: return 180
        case .left: return 90
        case .right: return -90
        }
    }
}

// MARK: - 提示卡片视图
struct TutorialTipCard: View {
    let title: String
    let description: String
    @ObservedObject var localizationManager: LocalizationManager
    
    // 获取自定义字体
    private func customFont(size: CGFloat) -> Font {
        return FontManager.shared.customFont(size: size)
    }
    
    var body: some View {
        VStack(spacing: 15) {
            // 标题
            Text(localizationManager.localized(title))
                .font(customFont(size: 24))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .textStroke()
            
            // 描述
            Text(localizationManager.localized(description))
                .font(customFont(size: 16))
                .foregroundColor(.white.opacity(0.9))
                .multilineTextAlignment(.center)
                .lineSpacing(6)
                .textStroke()
        }
        .padding(25)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.black.opacity(0.8))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.3), lineWidth: 2)
                )
        )
        .shadow(color: .black.opacity(0.5), radius: 10, x: 0, y: 5)
    }
}

#Preview {
    TutorialView(
        isPresented: .constant(true),
        steps: [
            TutorialStep(
                title: "tutorial.step1.title",
                description: "tutorial.step1.description",
                highlightFrame: CGRect(x: 100, y: 100, width: 200, height: 100),
                highlightCornerRadius: 15,
                arrowPosition: CGPoint(x: 0, y: -50),
                arrowDirection: .down,
                arrowOffset: 0
            )
        ]
    )
}

