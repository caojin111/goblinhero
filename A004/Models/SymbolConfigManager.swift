//
//  SymbolConfigManager.swift
//  A004
//
//  符号配置管理器
//

import Foundation
import SwiftUI

// MARK: - 符号配置数据模型
struct SymbolConfig: Codable {
    let symbolCategories: [String: SymbolCategory]
    let raritySettings: [String: RaritySetting]
    let symbols: [SymbolConfigData]
    let unlockSettings: UnlockSettings
    let effectTypes: [String: EffectType]
    let balanceSettings: BalanceSettings
}

struct SymbolCategory: Codable {
    let name: String
    let description: String
    let color: String
    let icon: String
}

struct RaritySetting: Codable {
    let name: String
    let weight: Double
    let color: String
    let description: String
}

struct SymbolConfigData: Codable {
    let id: String
    let name: String
    let icon: String
    let category: String
    let rarity: String
    let baseValue: Int
    let description: String
    let effects: [SymbolEffect]
    let unlockLevel: Int
    let isEnabled: Bool
}

struct SymbolEffect: Codable {
    let type: String
    let targetCategory: String?
    let bonusValue: Int?
    let multiplier: Double?
    let description: String
}

struct UnlockSettings: Codable {
    let levelBasedUnlock: Bool
    let maxUnlockLevel: Int
    let unlockRequirements: [String: String]
}

struct EffectType: Codable {
    let name: String
    let description: String
}

struct BalanceSettings: Codable {
    let maxSymbolsPerCategory: Int
    let maxSymbolsPerRarity: [String: Int]
    let valueRange: [String: [Int]]
}

// MARK: - 符号配置管理器
class SymbolConfigManager: ObservableObject {
    static let shared = SymbolConfigManager()
    
    @Published var config: SymbolConfig
    @Published var currentUnlockLevel: Int = 1
    
    private init() {
        self.config = SymbolConfigManager.loadDefaultConfig()
    }
    
    // MARK: - 配置加载
    static func loadDefaultConfig() -> SymbolConfig {
        guard let url = Bundle.main.url(forResource: "SymbolConfig", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let config = try? JSONDecoder().decode(SymbolConfig.self, from: data) else {
            print("❌ [符号配置] 无法加载配置文件，使用默认配置")
            return SymbolConfigManager.createDefaultConfig()
        }
        
        print("✅ [符号配置] 成功加载配置文件")
        return config
    }
    
    static func createDefaultConfig() -> SymbolConfig {
        return SymbolConfig(
            symbolCategories: [:],
            raritySettings: [:],
            symbols: [],
            unlockSettings: UnlockSettings(levelBasedUnlock: true, maxUnlockLevel: 20, unlockRequirements: [:]),
            effectTypes: [:],
            balanceSettings: BalanceSettings(maxSymbolsPerCategory: 10, maxSymbolsPerRarity: [:], valueRange: [:])
        )
    }
    
    // MARK: - 符号获取
    func getAllSymbols() -> [SymbolConfigData] {
        return config.symbols.filter { $0.isEnabled }
    }
    
    func getSymbolsByCategory(_ category: String) -> [SymbolConfigData] {
        return config.symbols.filter { $0.category == category && $0.isEnabled }
    }
    
    func getSymbolsByRarity(_ rarity: String) -> [SymbolConfigData] {
        return config.symbols.filter { $0.rarity == rarity && $0.isEnabled }
    }
    
    func getUnlockedSymbols() -> [SymbolConfigData] {
        return config.symbols.filter { $0.isEnabled && $0.unlockLevel <= currentUnlockLevel }
    }
    
    func getSymbol(by id: String) -> SymbolConfigData? {
        return config.symbols.first { $0.id == id }
    }
    
    // MARK: - 随机符号生成
    func getRandomSymbols(count: Int) -> [SymbolConfigData] {
        let unlockedSymbols = getUnlockedSymbols()
        guard !unlockedSymbols.isEmpty else { return [] }
        
        var result: [SymbolConfigData] = []
        
        for _ in 0..<count {
            let random = Double.random(in: 0...1)
            let rarity = getRarityByWeight(random)
            
            let symbolsOfRarity = unlockedSymbols.filter { $0.rarity == rarity }
            if let randomSymbol = symbolsOfRarity.randomElement() {
                result.append(randomSymbol)
            }
        }
        
        return result
    }
    
    private func getRarityByWeight(_ random: Double) -> String {
        let rarityWeights = config.raritySettings
        
        var cumulativeWeight = 0.0
        for (rarity, setting) in rarityWeights {
            cumulativeWeight += setting.weight
            if random <= cumulativeWeight {
                return rarity
            }
        }
        
        return "common" // 默认返回普通
    }
    
    // MARK: - 稀有度权重
    func getRarityWeights() -> [String: Double] {
        var weights: [String: Double] = [:]
        for (rarity, setting) in config.raritySettings {
            weights[rarity] = setting.weight
        }
        return weights
    }
    
    // MARK: - 符号转换
    func convertToGameSymbol(_ configSymbol: SymbolConfigData) -> Symbol {
        let rarity = SymbolRarity(rawValue: configSymbol.rarity) ?? .common
        let type = SymbolType(rawValue: configSymbol.category) ?? .fruit
        
        return Symbol(
            name: configSymbol.name,
            icon: configSymbol.icon,
            baseValue: configSymbol.baseValue,
            rarity: rarity,
            type: type,
            description: configSymbol.description
        )
    }
    
    // MARK: - 解锁管理
    func setUnlockLevel(_ level: Int) {
        currentUnlockLevel = min(level, config.unlockSettings.maxUnlockLevel)
        print("🔓 [解锁] 当前解锁等级: \(currentUnlockLevel)")
    }
    
    func getUnlockRequirement(for level: Int) -> String? {
        return config.unlockSettings.unlockRequirements["level_\(level)"]
    }
    
    // MARK: - 符号效果处理
    func processSymbolEffects(_ symbol: SymbolConfigData, adjacentSymbols: [Symbol]) -> Int {
        var totalValue = symbol.baseValue
        
        for effect in symbol.effects {
            switch effect.type {
            case "adjacent_bonus":
                if let targetCategory = effect.targetCategory,
                   let bonusValue = effect.bonusValue {
                    let adjacentCount = adjacentSymbols.filter { 
                        SymbolType(rawValue: targetCategory) == $0.type 
                    }.count
                    totalValue += adjacentCount * bonusValue
                }
                
            case "multiplier":
                if let multiplier = effect.multiplier {
                    totalValue = Int(Double(totalValue) * multiplier)
                }
                
            default:
                break
            }
        }
        
        return totalValue
    }
    
    // MARK: - 配置验证
    func validateConfig() -> Bool {
        // 检查符号数量限制
        for (category, _) in config.symbolCategories {
            let categorySymbols = getSymbolsByCategory(category)
            if categorySymbols.count > config.balanceSettings.maxSymbolsPerCategory {
                print("⚠️ [配置验证] 分类 \(category) 符号数量超出限制")
                return false
            }
        }
        
        // 检查稀有度数量限制
        for (rarity, maxCount) in config.balanceSettings.maxSymbolsPerRarity {
            let raritySymbols = getSymbolsByRarity(rarity)
            if raritySymbols.count > maxCount {
                print("⚠️ [配置验证] 稀有度 \(rarity) 符号数量超出限制")
                return false
            }
        }
        
        return true
    }
    
    // MARK: - 调试信息
    func printConfigSummary() {
        print("📊 [符号配置] 配置摘要:")
        print("  - 总符号数: \(config.symbols.count)")
        print("  - 已启用: \(config.symbols.filter { $0.isEnabled }.count)")
        print("  - 已解锁: \(getUnlockedSymbols().count)")
        print("  - 当前解锁等级: \(currentUnlockLevel)")
        
        for (category, _) in config.symbolCategories {
            let count = getSymbolsByCategory(category).count
            print("  - \(category): \(count) 个符号")
        }
    }
}
