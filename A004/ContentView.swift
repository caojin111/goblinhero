//
//  ContentView.swift
//  A004
//
//  Created by Allen on 2025/9/30.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = GameViewModel()
    @State private var showLaunchScreen = true
    @State private var showStoryIntro = false
    @State private var showLoadingScreen = false
    @State private var showHomeView = false
    @State private var fadeOpacity: Double = 1.0 // 渐暗渐明转场控制
    @State private var isTransitioning: Bool = false // 是否正在转场
    @State private var allowLetterDisplay: Bool = false // 是否允许信页面渲染
    
    // 检查是否是首次启动
    private var isFirstLaunch: Bool {
        !UserDefaults.standard.bool(forKey: "hasSeenStoryIntro")
    }

    var body: some View {
        ZStack {
            // 启动页（只显示 icon，不显示 loading）
            if showLaunchScreen {
                LaunchScreenView()
                    .transition(.opacity)
            }
            
            // 故事介绍（首次启动时显示）
            if showStoryIntro {
                StoryIntroView(isPresented: $showStoryIntro)
                    .transition(.opacity)
                    .opacity(fadeOpacity)
            }
            
            // 首页（启动页结束后显示）
            // 让首页始终渲染，转场时用全黑遮罩层覆盖，避免反复出现
            if showHomeView && !viewModel.goblinSelectionCompleted {
                HomeView(viewModel: viewModel)
                    .transition(.opacity)
            }
            
            // Loading 页面（新老玩家都需要，带 loading 动画）
            if showLoadingScreen {
                LoadingScreenView {
                    // Loading 完成后的回调：渐暗渐明转场到首页
                    performFadeTransition {
                        showLoadingScreen = false
                        showHomeView = true
                    }
                }
                .transition(.opacity)
                .opacity(fadeOpacity)
            }

            // 全黑遮罩层：盖在首页和哥布林选择上层，用于转场最黑时遮住底层
            // 一直存在直到进入游戏页面（goblinSelectionCompleted为true）
            if viewModel.showLetterView && !viewModel.goblinSelectionCompleted {
                Color.black
                    .ignoresSafeArea()
                    .opacity(1.0) // 始终纯黑遮住底层
                    .zIndex(900)
            }

            // 信页面（哥布林选择后显示），放在全黑遮罩层上层
            // 仅当允许显示时才渲染，避免过早出现
            if viewModel.showLetterView && allowLetterDisplay {
                LetterView(opacity: fadeOpacity) {
                    // 点击后直接进入游戏界面，不需要转场
                    print("📜 [ContentView] 信页面点击，直接进入游戏")
                    // 直接调用onLetterDismissed，进入游戏
                    viewModel.onLetterDismissed()
                }
                .transition(.opacity)
                .zIndex(950)
            }

            // 主游戏界面（游戏进行中）
            if viewModel.goblinSelectionCompleted {
                GameView(viewModel: viewModel)
            }

            // 渐暗渐明遮罩层（转场时显示），位于最上层
            if isTransitioning {
                Color.black
                    .ignoresSafeArea()
                    .opacity(1.0 - fadeOpacity)
                    .zIndex(1000) // 转场效果层级最高
            }

        }
        .onAppear {
            // 初始化Game Center认证
            _ = GameCenterManager.shared
            print("🎮 [Game Center] 初始化Game Center管理器")
        }
        .animation(.easeInOut(duration: 0.3), value: showLaunchScreen)
        .animation(.easeInOut(duration: 0.3), value: showStoryIntro)
        .animation(.easeInOut(duration: 0.3), value: showLoadingScreen)
        .animation(.easeInOut(duration: 0.3), value: showHomeView)
        .animation(.easeInOut(duration: 0.3), value: viewModel.goblinSelectionCompleted)
        .animation(.easeInOut(duration: 0.3), value: viewModel.showGoblinSelection)
        .animation(.easeInOut(duration: 0.3), value: viewModel.showLetterView)
        .onAppear {
            // 启动页显示2秒后决定下一步
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                withAnimation {
                    showLaunchScreen = false
                    // 如果是首次启动，显示故事介绍；否则直接显示 LoadingScreen
                    if isFirstLaunch {
                        showStoryIntro = true
                    } else {
                        // 老玩家：LaunchScreen → LoadingScreen
                        showLoadingScreen = true
                    }
                }
            }
        }
        .onChange(of: showStoryIntro) { newValue in
            // 故事介绍结束后，显示 loading 页面（新玩家流程）
            if !newValue && !showLaunchScreen {
                // 渐暗渐明转场：故事介绍 → Loading
                performFadeTransition {
                    showLoadingScreen = true
                }
            }
        }
        .onChange(of: viewModel.showLetterView) { isShowing in
            // 当需要显示信页面时，执行渐暗渐明转场
            if isShowing {
                print("📜 [ContentView] 显示信页面，执行渐暗渐明转场")
                // 先开始渐暗
                isTransitioning = true
                allowLetterDisplay = false
                withAnimation(.easeInOut(duration: 0.5)) {
                    fadeOpacity = 0.0
                }
                
                // 等待渐暗完成（0.5秒后），此时最黑
                // 再延迟1秒后，信页面才允许出现并开始渐明
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5 + 1.0) {
                    allowLetterDisplay = true // 允许信页面渲染（最黑时刻后）
                    // 开始渐明，信页面慢慢显示
                    withAnimation(.easeInOut(duration: 0.5)) {
                        fadeOpacity = 1.0
                    }
                    
                    // 转场完成
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        isTransitioning = false
                    }
                }
            } else {
                // 隐藏信页面时，重置标记
                allowLetterDisplay = false
            }
        }
        .onChange(of: viewModel.goblinSelectionCompleted) { completed in
            // 当游戏退出时（goblinSelectionCompleted 变为 false），确保显示首页并播放背景音乐
            if !completed && !showLaunchScreen && !showStoryIntro && !showLoadingScreen {
                print("🔄 [ContentView] 游戏退出，显示首页并播放背景音乐")
                showHomeView = true
                // 确保首页背景音乐播放（增加延迟确保视图切换完成）
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    print("🔄 [ContentView] 开始播放首页背景音乐")
                    AudioManager.shared.playBackgroundMusic(fileName: "homepage", fileExtension: "mp3")
                }
            }
        }
    }
    
    /// 执行渐暗渐明转场效果
    private func performFadeTransition(completion: @escaping () -> Void) {
        isTransitioning = true
        
        // 渐暗（0.5秒）
        withAnimation(.easeInOut(duration: 0.5)) {
            fadeOpacity = 0.0
        }
        
        // 等待渐暗完成，然后执行回调并渐明
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            // 执行视图切换
            completion()
            
            // 短暂延迟后开始渐明，确保新视图已显示
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                // 渐明（0.5秒）
                withAnimation(.easeInOut(duration: 0.5)) {
                    fadeOpacity = 1.0
                }
                
                // 转场完成
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    isTransitioning = false
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
