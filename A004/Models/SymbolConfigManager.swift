//
//  SymbolConfigManager.swift
//  A004
//
//  符号配置管理器
//

import Foundation
import SwiftUI

// MARK: - 配置文件结构
struct SymbolConfigFile: Codable {
    let symbols: [SymbolConfigData]
    let config: SymbolSystemConfig
}

struct SymbolConfigData: Codable {
    let id: Int
    let nameKey: String
    let icon: String
    let rarity: String
    let types: [String]
    let baseValue: Int
    let weight: Int
    let effect: String  // 被挖起时的效果（技术性描述，给开发看的）
    let descriptionKey: String?  // 展示描述键名（多语言）
    let effectType: String
    let effectParams: [String: AnyCodable]
}

struct SymbolSystemConfig: Codable {
    let enableEffects: Bool
    let totalWeight: Int
    let rarityWeightMultipliers: [String: Double]
    let startingSymbolCount: Int
    let symbolPoolMaxSize: Int
}

// MARK: - AnyCodable 辅助类型
struct AnyCodable: Codable {
    let value: Any
    
    init(_ value: Any) {
        self.value = value
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        if let intValue = try? container.decode(Int.self) {
            value = intValue
        } else if let doubleValue = try? container.decode(Double.self) {
            value = doubleValue
        } else if let stringValue = try? container.decode(String.self) {
            value = stringValue
        } else if let boolValue = try? container.decode(Bool.self) {
            value = boolValue
        } else if let arrayValue = try? container.decode([AnyCodable].self) {
            value = arrayValue.map { $0.value }
        } else if let dictValue = try? container.decode([String: AnyCodable].self) {
            value = dictValue.mapValues { $0.value }
        } else {
            value = NSNull()
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        
        switch value {
        case let intValue as Int:
            try container.encode(intValue)
        case let doubleValue as Double:
            try container.encode(doubleValue)
        case let stringValue as String:
            try container.encode(stringValue)
        case let boolValue as Bool:
            try container.encode(boolValue)
        case let arrayValue as [Any]:
            try container.encode(arrayValue.map { AnyCodable($0) })
        case let dictValue as [String: Any]:
            try container.encode(dictValue.mapValues { AnyCodable($0) })
        default:
            try container.encodeNil()
        }
    }
}

// MARK: - 符号配置管理器
class SymbolConfigManager {
    static let shared = SymbolConfigManager()
    
    private var configFile: SymbolConfigFile?
    private let configFileName = "SymbolConfig"
    
    private init() {
        loadConfig()
    }
    
    /// 加载配置文件
    private func loadConfig() {
        guard let url = Bundle.main.url(forResource: configFileName, withExtension: "json") else {
            print("❌ [符号配置] 找不到配置文件: \(configFileName).json")
            return
        }
        
        do {
            let data = try Data(contentsOf: url)
            configFile = try JSONDecoder().decode(SymbolConfigFile.self, from: data)
            print("✅ [符号配置] 成功加载配置文件，共 \(configFile?.symbols.count ?? 0) 个符号")
        } catch {
            print("❌ [符号配置] 解析配置文件失败: \(error)")
        }
    }
    
    /// 获取所有符号
    func getAllSymbols() -> [Symbol] {
        guard let configFile = configFile else {
            print("⚠️ [符号配置] 配置文件未加载，返回空数组")
            return []
        }
        
        return configFile.symbols.map { config in
            Symbol(
                id: UUID(),
                nameKey: config.nameKey,
                icon: config.icon,
                baseValue: config.baseValue,
                rarity: mapRarity(config.rarity),
                type: mapPrimaryType(config.types),
                descriptionKey: config.descriptionKey ?? config.nameKey,  // 使用键名作为描述键，如果没有则使用名称键
                weight: config.weight,
                types: config.types,
                effectType: config.effectType,
                effectParams: config.effectParams.mapValues { $0.value }
            )
        }
    }
    
    /// 根据权重随机选择符号
    func getRandomSymbol(fromPool pool: [Symbol]) -> Symbol? {
        let totalWeight = pool.reduce(0) { $0 + $1.weight }
        guard totalWeight > 0 else { return pool.randomElement() }
        
        let randomValue = Int.random(in: 1...totalWeight)
        var currentWeight = 0
        
        for symbol in pool {
            currentWeight += symbol.weight
            if randomValue <= currentWeight {
                return symbol
            }
        }
        
        return pool.first
    }
    
    /// 获取随机的起始符号
    func getStartingSymbols() -> [Symbol] {
        let allSymbols = getAllSymbols()
        let count = configFile?.config.startingSymbolCount ?? 3
        
        var selectedSymbols: [Symbol] = []
        for _ in 0..<count {
            if let symbol = getRandomSymbol(fromPool: allSymbols) {
                selectedSymbols.append(symbol)
            }
        }
        
        print("🎯 [符号配置] 生成\(count)个起始符号: \(selectedSymbols.map { $0.name })")
        return selectedSymbols
    }
    
    /// 根据名称查找符号（支持本地化名称和键值）
    func getSymbol(byName name: String) -> Symbol? {
        return getAllSymbols().first { $0.name == name || $0.nameKey == name }
    }
    
    /// 根据类型过滤符号
    func getSymbols(byType type: String) -> [Symbol] {
        return getAllSymbols().filter { $0.types.contains(type) }
    }
    
    /// 根据稀有度过滤符号
    func getSymbols(byRarity rarity: SymbolRarity) -> [Symbol] {
        return getAllSymbols().filter { $0.rarity == rarity }
    }
    
    /// 获取符号选择选项（3选1）
    func getSymbolChoiceOptions() -> [Symbol] {
        // 过滤掉不应该出现在三选一中的符号（死神只能通过死灵之书产出）
        let availableSymbols = getAllSymbols().filter { symbol in
            symbol.name != "死神"
        }
        
        var options: [Symbol] = []
        var usedSymbols = Set<String>() // 用于跟踪已选择的符号名称
        
        // 确保至少选择3个不同的符号
        var attempts = 0
        let maxAttempts = availableSymbols.count * 2 // 防止无限循环
        
        while options.count < 3 && attempts < maxAttempts {
            if let symbol = getRandomSymbol(fromPool: availableSymbols) {
                // 检查是否已经选择过这个符号
                if !usedSymbols.contains(symbol.name) {
                    options.append(symbol)
                    usedSymbols.insert(symbol.name)
                    print("🎯 [符号选择] 添加选项: \(symbol.name)")
                } else {
                    print("🎯 [符号选择] 跳过重复符号: \(symbol.name)")
                }
            }
            attempts += 1
        }
        
        // 如果仍然不足3个，从剩余符号中随机选择
        if options.count < 3 {
            let remainingSymbols = availableSymbols.filter { !usedSymbols.contains($0.name) }
            let needed = 3 - options.count
            let additionalSymbols = Array(remainingSymbols.shuffled().prefix(needed))
            options.append(contentsOf: additionalSymbols)
            print("🎯 [符号选择] 补充选项: \(additionalSymbols.map { $0.name })")
        }
        
        print("🎯 [符号选择] 最终选项: \(options.map { $0.name })")
        return options
    }
    
    /// 检查是否启用效果
    func isEffectsEnabled() -> Bool {
        return configFile?.config.enableEffects ?? true
    }
    
    /// 获取符号池最大大小
    func getSymbolPoolMaxSize() -> Int {
        return configFile?.config.symbolPoolMaxSize ?? 100
    }
    
    /// 重新加载配置
    func reloadConfig() {
        print("🔄 [符号配置] 重新加载配置文件")
        loadConfig()
    }
    
    // MARK: - 私有辅助方法
    
    private func mapRarity(_ rarity: String) -> SymbolRarity {
        switch rarity.lowercased() {
        case "normal": return .common
        case "rare": return .rare
        case "epic": return .epic
        case "legendary": return .legendary
        default: return .common
        }
    }
    
    private func mapPrimaryType(_ types: [String]) -> SymbolType {
        guard let firstType = types.first else { return .special }
        
        switch firstType.lowercased() {
        case "human": return .animal
        case "material": return .special
        case "box": return .special
        case "monster": return .special
        case "alien": return .special
        case "dice": return .magic
        case "tool": return .special
        default: return .special
        }
    }
}
