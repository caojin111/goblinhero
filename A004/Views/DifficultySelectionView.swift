//
//  DifficultySelectionView.swift
//  A004
//
//  难度选择界面
//

import SwiftUI

struct DifficultySelectionView: View {
    @ObservedObject var configManager = GameConfigManager.shared
    @Binding var isPresented: Bool
    let onDifficultySelected: (String) -> Void
    
    var body: some View {
        ZStack {
            // 背景
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {
                    isPresented = false
                }
            
            VStack(spacing: 25) {
                // 标题
                Text("🎮 选择难度")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text("选择适合你的挑战难度")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.8))
                
                // 难度选项
                VStack(spacing: 15) {
                    DifficultyButton(
                        title: "😊 简单",
                        description: "初始房租: 30金币\n递增: 20%",
                        color: .green,
                        isSelected: configManager.currentDifficulty == "easy"
                    ) {
                        selectDifficulty("easy")
                    }
                    
                    DifficultyButton(
                        title: "😐 普通",
                        description: "初始房租: 50金币\n递增: 50%",
                        color: .blue,
                        isSelected: configManager.currentDifficulty == "normal"
                    ) {
                        selectDifficulty("normal")
                    }
                    
                    DifficultyButton(
                        title: "😤 困难",
                        description: "初始房租: 100金币\n递增: 80%",
                        color: .orange,
                        isSelected: configManager.currentDifficulty == "hard"
                    ) {
                        selectDifficulty("hard")
                    }
                    
                    DifficultyButton(
                        title: "🔥 极限",
                        description: "初始房租: 200金币\n递增: 100%",
                        color: .red,
                        isSelected: configManager.currentDifficulty == "extreme"
                    ) {
                        selectDifficulty("extreme")
                    }
                }
                
                // 关闭按钮
                Button("关闭") {
                    isPresented = false
                }
                .font(.headline)
                .foregroundColor(.white)
                .padding(.horizontal, 30)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.white.opacity(0.2))
                )
            }
            .padding(30)
            .background(
                RoundedRectangle(cornerRadius: 25)
                    .fill(Color.black.opacity(0.9))
            )
            .padding(40)
        }
        .transition(.scale)
    }
    
    private func selectDifficulty(_ difficulty: String) {
        configManager.setDifficulty(difficulty)
        onDifficultySelected(difficulty)
        isPresented = false
    }
}

struct DifficultyButton: View {
    let title: String
    let description: String
    let color: Color
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 5) {
                    Text(title)
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(color)
                        .font(.title2)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 15)
                    .fill(isSelected ? color.opacity(0.3) : Color.white.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 15)
                            .stroke(isSelected ? color : Color.clear, lineWidth: 2)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    DifficultySelectionView(isPresented: .constant(true)) { _ in }
}
