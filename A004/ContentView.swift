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
            }
            
            // Loading 页面（新老玩家都需要，带 loading 动画）
            if showLoadingScreen {
                LoadingScreenView {
                    // Loading 完成后的回调
                    withAnimation {
                        showLoadingScreen = false
                        showHomeView = true
                    }
                }
                .transition(.opacity)
            }

            // 主游戏界面（游戏进行中）
            if viewModel.goblinSelectionCompleted {
                GameView(viewModel: viewModel)
            }

            // 首页（启动页结束后显示）
            if showHomeView && !viewModel.goblinSelectionCompleted {
                HomeView(viewModel: viewModel)
                    .transition(.opacity)
            }

        }
        .animation(.easeInOut(duration: 0.3), value: showLaunchScreen)
        .animation(.easeInOut(duration: 0.3), value: showStoryIntro)
        .animation(.easeInOut(duration: 0.3), value: showLoadingScreen)
        .animation(.easeInOut(duration: 0.3), value: showHomeView)
        .animation(.easeInOut(duration: 0.3), value: viewModel.goblinSelectionCompleted)
        .animation(.easeInOut(duration: 0.3), value: viewModel.showGoblinSelection)
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
                withAnimation {
                    showLoadingScreen = true
                }
                // Loading 完成后会通过回调自动跳转到首页
            }
        }
        .onChange(of: viewModel.goblinSelectionCompleted) { completed in
            // 当游戏退出时（goblinSelectionCompleted 变为 false），确保显示首页
            if !completed && !showLaunchScreen && !showStoryIntro && !showLoadingScreen {
                showHomeView = true
            }
        }
    }
}

#Preview {
    ContentView()
}
