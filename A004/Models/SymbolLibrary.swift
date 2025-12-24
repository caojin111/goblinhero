//
//  SymbolLibrary.swift
//  A004
//
//  符号库 - 从配置文件加载所有符号
//

import Foundation

struct SymbolLibrary {
    // 配置管理器
    private static let configManager = SymbolConfigManager.shared
    
    // 所有可用符号（从配置文件加载）
    static var allSymbols: [Symbol] {
        return configManager.getAllSymbols()
    }
    
    // 初始符号池（游戏开始时的符号）
    static var startingSymbols: [Symbol] {
        return configManager.getStartingSymbols()
    }
    
    // 根据稀有度获取符号
    static func getSymbols(byRarity rarity: SymbolRarity) -> [Symbol] {
        return configManager.getSymbols(byRarity: rarity)
    }
    
    // 根据类型获取符号
    static func getSymbols(byType type: String) -> [Symbol] {
        return configManager.getSymbols(byType: type)
    }
    
    // 根据名称查找符号
    static func getSymbol(byName name: String) -> Symbol? {
        return configManager.getSymbol(byName: name)
    }
    
    // 获取符号选择选项（3选1）
    static func getSymbolChoiceOptions(symbolPool: [Symbol] = []) -> [Symbol] {
        return configManager.getSymbolChoiceOptions(symbolPool: symbolPool)
    }
    
    // 随机获取一个符号（基于权重）
    static func getRandomSymbol() -> Symbol? {
        return configManager.getRandomSymbol(fromPool: allSymbols)
    }
    
    // 随机获取多个符号（基于权重）
    static func getRandomSymbols(count: Int) -> [Symbol] {
        var symbols: [Symbol] = []
        for _ in 0..<count {
            if let symbol = getRandomSymbol() {
                symbols.append(symbol)
            }
        }
        return symbols
    }
    
    // 打印符号库信息
    static func printSymbolLibrarySummary() {
        let symbols = allSymbols
        print("📚 [符号库] 共 \(symbols.count) 个符号")
        
        let normal = symbols.filter { $0.rarity == .common }.count
        let rare = symbols.filter { $0.rarity == .rare }.count
        let epic = symbols.filter { $0.rarity == .epic }.count
        let legendary = symbols.filter { $0.rarity == .legendary }.count
        
        let commonName = LocalizationManager.shared.localized("rarity.common")
        let rareName = LocalizationManager.shared.localized("rarity.rare")
        let epicName = LocalizationManager.shared.localized("rarity.epic")
        let legendaryName = LocalizationManager.shared.localized("rarity.legendary")
        print("📊 [符号库] 稀有度分布: \(commonName)\(normal) | \(rareName)\(rare) | \(epicName)\(epic) | \(legendaryName)\(legendary)")
        
        let typeGroups = Dictionary(grouping: symbols) { $0.types.first ?? "unknown" }
        print("🏷️ [符号库] 类型分布:")
        for (type, typeSymbols) in typeGroups.sorted(by: { $0.key < $1.key }) {
            print("   - \(type): \(typeSymbols.count)个")
        }
    }
}
