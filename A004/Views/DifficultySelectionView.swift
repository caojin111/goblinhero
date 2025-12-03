//
//  DifficultySelectionView.swift
//  A004
//
//  难度选择界面
//

import SwiftUI

struct DifficultySelectionView: View {
    @ObservedObject var configManager = GameConfigManager.shared
    @ObservedObject var localizationManager = LocalizationManager.shared
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
                Text(localizationManager.localized("difficulty.select_title"))
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text(localizationManager.localized("difficulty.select_hint"))
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.8))
                
                // 难度选项
                VStack(spacing: 15) {
                    DifficultyButton(
                        title: "😊 \(localizationManager.getDifficultyName("easy"))",
                        description: "\(localizationManager.localized("difficulty.initial_rent")): 30\(localizationManager.localized("game.coins"))\n\(localizationManager.localized("difficulty.increase")): 20%",
                        color: .green,
                        isSelected: configManager.currentDifficulty == "easy"
                    ) {
                        selectDifficulty("easy")
                    }
                    
                    DifficultyButton(
                        title: "😐 \(localizationManager.getDifficultyName("normal"))",
                        description: "\(localizationManager.localized("difficulty.initial_rent")): 50\(localizationManager.localized("game.coins"))\n\(localizationManager.localized("difficulty.increase")): 50%",
                        color: .blue,
                        isSelected: configManager.currentDifficulty == "normal"
                    ) {
                        selectDifficulty("normal")
                    }
                    
                    DifficultyButton(
                        title: "😤 \(localizationManager.getDifficultyName("hard"))",
                        description: "\(localizationManager.localized("difficulty.initial_rent")): 100\(localizationManager.localized("game.coins"))\n\(localizationManager.localized("difficulty.increase")): 80%",
                        color: .orange,
                        isSelected: configManager.currentDifficulty == "hard"
                    ) {
                        selectDifficulty("hard")
                    }
                    
                    DifficultyButton(
                        title: "🔥 \(localizationManager.getDifficultyName("extreme"))",
                        description: "\(localizationManager.localized("difficulty.initial_rent")): 200\(localizationManager.localized("game.coins"))\n\(localizationManager.localized("difficulty.increase")): 100%",
                        color: .red,
                        isSelected: configManager.currentDifficulty == "extreme"
                    ) {
                        selectDifficulty("extreme")
                    }
                }
                
                // 关闭按钮
                Button(localizationManager.localized("settings.close")) {
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
