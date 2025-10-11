//
//  ContentView.swift
//  A004
//
//  Created by Allen on 2025/9/30.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = GameViewModel()
    
    var body: some View {
        ZStack {
            // 主游戏界面
            if viewModel.goblinSelectionCompleted {
                GameView(viewModel: viewModel)
            }
            
            // 哥布林选择界面（首次进入游戏或重新选择）
            if viewModel.showGoblinSelection || !viewModel.goblinSelectionCompleted {
                GoblinSelectionView(
                    selectedGoblin: $viewModel.selectedGoblin,
                    isPresented: $viewModel.showGoblinSelection,
                    unlockedGoblinIds: $viewModel.unlockedGoblinIds,
                    currentCoins: $viewModel.currentCoins
                )
                .transition(.opacity)
                .onChange(of: viewModel.selectedGoblin) { goblin in
                    if goblin != nil && !viewModel.showGoblinSelection {
                        // 哥布林选择完成
                        viewModel.onGoblinSelected()
                    }
                }
                .onAppear {
                    if !viewModel.goblinSelectionCompleted && !viewModel.showGoblinSelection {
                        // 首次显示哥布林选择
                        viewModel.showGoblinSelectionView()
                    }
                }
            }
        }
        .animation(.easeInOut(duration: 0.3), value: viewModel.goblinSelectionCompleted)
        .animation(.easeInOut(duration: 0.3), value: viewModel.showGoblinSelection)
    }
}

#Preview {
    ContentView()
}
