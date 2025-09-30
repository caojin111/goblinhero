//
//  SymbolConfigView.swift
//  A004
//
//  符号配置管理界面
//

import SwiftUI

struct SymbolConfigView: View {
    @StateObject private var configManager = SymbolConfigManager.shared
    @State private var selectedCategory: String = "all"
    @State private var selectedRarity: String = "all"
    @State private var showUnlockSettings = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 顶部筛选栏
                FilterBar(
                    selectedCategory: $selectedCategory,
                    selectedRarity: $selectedRarity,
                    categories: getCategories(),
                    rarities: getRarities()
                )
                
                // 符号列表
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(filteredSymbols(), id: \.id) { symbol in
                            SymbolConfigRow(symbol: symbol)
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("符号配置")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("解锁设置") {
                        showUnlockSettings = true
                    }
                }
            }
            .sheet(isPresented: $showUnlockSettings) {
                UnlockSettingsView()
            }
        }
    }
    
    private func getCategories() -> [String] {
        return ["all"] + Array(configManager.config.symbolCategories.keys).sorted()
    }
    
    private func getRarities() -> [String] {
        return ["all"] + Array(configManager.config.raritySettings.keys).sorted()
    }
    
    private func filteredSymbols() -> [SymbolConfigData] {
        var symbols = configManager.getAllSymbols()
        
        if selectedCategory != "all" {
            symbols = symbols.filter { $0.category == selectedCategory }
        }
        
        if selectedRarity != "all" {
            symbols = symbols.filter { $0.rarity == selectedRarity }
        }
        
        return symbols.sorted { $0.name < $1.name }
    }
}

// MARK: - 筛选栏
struct FilterBar: View {
    @Binding var selectedCategory: String
    @Binding var selectedRarity: String
    let categories: [String]
    let rarities: [String]
    
    var body: some View {
        VStack(spacing: 12) {
            // 分类筛选
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(categories, id: \.self) { category in
                        FilterChip(
                            title: category == "all" ? "全部" : category,
                            isSelected: selectedCategory == category,
                            color: getCategoryColor(category)
                        ) {
                            selectedCategory = category
                        }
                    }
                }
                .padding(.horizontal)
            }
            
            // 稀有度筛选
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(rarities, id: \.self) { rarity in
                        FilterChip(
                            title: rarity == "all" ? "全部" : rarity,
                            isSelected: selectedRarity == rarity,
                            color: getRarityColor(rarity)
                        ) {
                            selectedRarity = rarity
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
        .padding(.vertical, 8)
        .background(Color(.systemGray6))
    }
    
    private func getCategoryColor(_ category: String) -> Color {
        guard category != "all",
              let categoryData = SymbolConfigManager.shared.config.symbolCategories[category] else {
            return .blue
        }
        return Color(hex: categoryData.color) ?? .blue
    }
    
    private func getRarityColor(_ rarity: String) -> Color {
        guard rarity != "all",
              let rarityData = SymbolConfigManager.shared.config.raritySettings[rarity] else {
            return .gray
        }
        return Color(hex: rarityData.color) ?? .gray
    }
}

// MARK: - 筛选芯片
struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(isSelected ? .white : .primary)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(isSelected ? color : Color(.systemGray5))
                )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - 符号配置行
struct SymbolConfigRow: View {
    let symbol: SymbolConfigData
    
    var body: some View {
        HStack(spacing: 12) {
            // 符号图标
            Text(symbol.icon)
                .font(.system(size: 32))
            
            // 符号信息
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(symbol.name)
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Spacer()
                    
                    Text("\(symbol.baseValue)💰")
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundColor(.yellow)
                }
                
                HStack {
                    // 分类标签
                    Text(symbol.category)
                        .font(.caption)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            RoundedRectangle(cornerRadius: 4)
                                .fill(getCategoryColor().opacity(0.2))
                        )
                        .foregroundColor(getCategoryColor())
                    
                    // 稀有度标签
                    Text(symbol.rarity)
                        .font(.caption)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            RoundedRectangle(cornerRadius: 4)
                                .fill(getRarityColor().opacity(0.2))
                        )
                        .foregroundColor(getRarityColor())
                    
                    Spacer()
                    
                    // 解锁等级
                    if symbol.unlockLevel > 1 {
                        Text("Lv.\(symbol.unlockLevel)")
                            .font(.caption2)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 2)
                            .background(
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color.orange.opacity(0.2))
                            )
                            .foregroundColor(.orange)
                    }
                }
                
                Text(symbol.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            // 状态指示器
            VStack {
                if symbol.isEnabled {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                } else {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.red)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
        )
    }
    
    private func getCategoryColor() -> Color {
        guard let categoryData = SymbolConfigManager.shared.config.symbolCategories[symbol.category] else {
            return .blue
        }
        return Color(hex: categoryData.color) ?? .blue
    }
    
    private func getRarityColor() -> Color {
        guard let rarityData = SymbolConfigManager.shared.config.raritySettings[symbol.rarity] else {
            return .gray
        }
        return Color(hex: rarityData.color) ?? .gray
    }
}

// MARK: - 解锁设置界面
struct UnlockSettingsView: View {
    @StateObject private var configManager = SymbolConfigManager.shared
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // 当前解锁等级
                VStack(spacing: 8) {
                    Text("当前解锁等级")
                        .font(.headline)
                    
                    Text("\(configManager.currentUnlockLevel)")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.blue.opacity(0.1))
                )
                
                // 等级滑块
                VStack(alignment: .leading, spacing: 8) {
                    Text("调整解锁等级")
                        .font(.headline)
                    
                    Slider(
                        value: Binding(
                            get: { Double(configManager.currentUnlockLevel) },
                            set: { configManager.setUnlockLevel(Int($0)) }
                        ),
                        in: 1...20,
                        step: 1
                    )
                    
                    HStack {
                        Text("1")
                        Spacer()
                        Text("20")
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemGray6))
                )
                
                // 解锁的符号统计
                VStack(alignment: .leading, spacing: 12) {
                    Text("符号统计")
                        .font(.headline)
                    
                    let unlockedSymbols = configManager.getUnlockedSymbols()
                    
                    HStack {
                        Text("已解锁符号:")
                        Spacer()
                        Text("\(unlockedSymbols.count)")
                            .fontWeight(.bold)
                    }
                    
                    HStack {
                        Text("总符号数:")
                        Spacer()
                        Text("\(configManager.getAllSymbols().count)")
                            .fontWeight(.bold)
                    }
                    
                    HStack {
                        Text("解锁进度:")
                        Spacer()
                        Text("\(Int(Double(unlockedSymbols.count) / Double(configManager.getAllSymbols().count) * 100))%")
                            .fontWeight(.bold)
                            .foregroundColor(.green)
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemGray6))
                )
                
                Spacer()
            }
            .padding()
            .navigationTitle("解锁设置")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - 颜色扩展
extension Color {
    init?(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            return nil
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

#Preview {
    SymbolConfigView()
}
