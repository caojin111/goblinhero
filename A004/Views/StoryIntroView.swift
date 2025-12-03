//
//  StoryIntroView.swift
//  A004
//
//  故事介绍幻灯片视图
//

import SwiftUI

struct StoryIntroView: View {
    @ObservedObject var localizationManager = LocalizationManager.shared
    @Binding var isPresented: Bool
    @State private var currentPage: Int = 0
    
    // 故事页面数据
    let storyPages: [StoryPage] = [
        StoryPage(
            title: "story.page1.title",
            content: "story.page1.content",
            icon: "👹"
        ),
        StoryPage(
            title: "story.page2.title",
            content: "story.page2.content",
            icon: "⛏️"
        ),
        StoryPage(
            title: "story.page3.title",
            content: "story.page3.content",
            icon: "💎"
        )
    ]
    
    var body: some View {
        ZStack {
            // 背景渐变
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.blue.opacity(0.8),
                    Color.purple.opacity(0.8),
                    Color.pink.opacity(0.6)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // 顶部 Skip 按钮
                HStack {
                    Spacer()
                    Button(action: {
                        skipStory()
                    }) {
                        Text(localizationManager.localized("story.skip"))
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(Color.black.opacity(0.3))
                            )
                    }
                    .padding(.top, 20)
                    .padding(.trailing, 20)
                }
                
                // 故事内容区域
                TabView(selection: $currentPage) {
                    ForEach(0..<storyPages.count, id: \.self) { index in
                        StoryPageView(
                            page: storyPages[index],
                            localizationManager: localizationManager
                        )
                        .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .indexViewStyle(.page(backgroundDisplayMode: .always))
                
                // 底部按钮区域
                HStack(spacing: 20) {
                    // 上一步按钮（第一页不显示）
                    if currentPage > 0 {
                        Button(action: {
                            withAnimation {
                                currentPage -= 1
                            }
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: "chevron.left")
                                Text(localizationManager.localized("story.previous"))
                            }
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 25)
                                    .fill(Color.white.opacity(0.2))
                            )
                        }
                    } else {
                        Spacer()
                            .frame(width: 100)
                    }
                    
                    Spacer()
                    
                    // 下一步/开始按钮
                    Button(action: {
                        if currentPage < storyPages.count - 1 {
                            withAnimation {
                                currentPage += 1
                            }
                        } else {
                            // 最后一页，完成故事介绍
                            completeStory()
                        }
                    }) {
                        HStack(spacing: 8) {
                            Text(currentPage < storyPages.count - 1 ?
                                 localizationManager.localized("story.next") :
                                 localizationManager.localized("story.start"))
                            if currentPage < storyPages.count - 1 {
                                Image(systemName: "chevron.right")
                            }
                        }
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
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
                }
                .padding(.horizontal, 30)
                .padding(.bottom, 40)
            }
        }
    }
    
    /// 跳过故事介绍
    private func skipStory() {
        print("📖 [故事介绍] 用户跳过故事介绍")
        markStoryCompleted()
        isPresented = false
    }
    
    /// 完成故事介绍
    private func completeStory() {
        print("📖 [故事介绍] 用户完成故事介绍")
        markStoryCompleted()
        isPresented = false
    }
    
    /// 标记故事介绍已完成
    private func markStoryCompleted() {
        UserDefaults.standard.set(true, forKey: "hasSeenStoryIntro")
    }
}

// MARK: - 故事页面数据模型
struct StoryPage {
    let title: String // 本地化键
    let content: String // 本地化键
    let icon: String
}

// MARK: - 单个故事页面视图
struct StoryPageView: View {
    let page: StoryPage
    @ObservedObject var localizationManager: LocalizationManager
    
    var body: some View {
        VStack(spacing: 40) {
            Spacer()
            
            // 图标
            StoryIconView(icon: page.icon)
            
            // 标题
            Text(localizationManager.localized(page.title))
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 2)
                .padding(.horizontal, 30)
            
            // 内容
            Text(localizationManager.localized(page.content))
                .font(.system(size: 18, weight: .regular))
                .foregroundColor(.white.opacity(0.9))
                .multilineTextAlignment(.center)
                .lineSpacing(8)
                .padding(.horizontal, 40)
            
            Spacer()
        }
    }
}

// MARK: - 故事图标视图（带动画）
struct StoryIconView: View {
    let icon: String
    @State private var isAnimating = false
    
    var body: some View {
        Text(icon)
            .font(.system(size: 120))
            .scaleEffect(isAnimating ? 1.1 : 1.0)
            .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: isAnimating)
            .onAppear {
                isAnimating = true
            }
    }
}

#Preview {
    StoryIntroView(isPresented: .constant(true))
}

