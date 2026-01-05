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

// MARK: - CSV符号配置数据
struct CSVSymbolConfigData {
    let id: Int
    let nameKey: String
    let icon: String // 图片资源名
    let rarity: String
    let types: [String]
    let baseValue: Int
    let bondID: String // 可能为空，多个用引号分割
    let weight: Int
    let effect: String
    let effectType: String
    let effectParams: [String: Any]
    let descriptionKey: String
}

// MARK: - 符号配置管理器
class SymbolConfigManager {
    static let shared = SymbolConfigManager()
    
    private var configFile: SymbolConfigFile?
    private var csvSymbols: [CSVSymbolConfigData] = []
    private var symbolIdMap: [String: Int] = [:] // nameKey -> id 映射
    private let configFileName = "SymbolConfig"
    private var useCSV: Bool = false
    
    private init() {
        loadConfig()
    }
    
    /// 加载配置文件（优先尝试CSV，失败则使用JSON）
    private func loadConfig() {
        // 优先尝试加载CSV
        if loadCSVConfig() {
            useCSV = true
            print("✅ [符号配置] 成功从CSV加载配置，共 \(csvSymbols.count) 个符号")
            return
        }
        
        // 如果CSV加载失败，尝试JSON（向后兼容）
        guard let url = Bundle.main.url(forResource: configFileName, withExtension: "json") else {
            print("❌ [符号配置] 找不到配置文件: \(configFileName).json")
            return
        }
        
        do {
            let data = try Data(contentsOf: url)
            configFile = try JSONDecoder().decode(SymbolConfigFile.self, from: data)
            useCSV = false
            print("✅ [符号配置] 成功从JSON加载配置文件，共 \(configFile?.symbols.count ?? 0) 个符号")
        } catch {
            print("❌ [符号配置] 解析JSON配置文件失败: \(error)")
        }
    }
    
    /// 加载CSV配置
    private func loadCSVConfig() -> Bool {
        print("🔍 [符号配置] 尝试加载CSV配置文件: \(configFileName).csv")
        guard let rows = CSVReader.readCSV(fileName: configFileName) else {
            print("⚠️ [符号配置] CSV文件不存在或读取失败，尝试JSON")
            return false
        }
        
        print("✅ [符号配置] CSV文件读取成功，共\(rows.count)行数据")
        
        csvSymbols = rows.compactMap { row -> CSVSymbolConfigData? in
            guard let idStr = row["id"],
                  let id = Int(idStr),
                  let nameKey = row["nameKey"],
                  let icon = row["icon"],
                  let rarity = row["rarity"],
                  let typesStr = row["types"],
                  let baseValueStr = row["baseValue"],
                  let baseValue = Int(baseValueStr),
                  let weightStr = row["weight"],
                  let weight = Int(weightStr),
                  let effect = row["effect"],
                  let effectType = row["effectType"],
                  let effectParamsStr = row["effectParams"],
                  let descriptionKey = row["descriptionKey"] else {
                print("⚠️ [符号配置] CSV行数据不完整，跳过: \(row)")
                return nil
            }
            
            // 解析types（用分号分割）
            let types = typesStr.split(separator: ";").map { String($0.trimmingCharacters(in: .whitespaces)) }
            
            // 解析bondID（可能为空，多个用引号分割）
            let bondID = row["bondID"] ?? ""
            
            // 解析effectParams（JSON字符串）
            var effectParams: [String: Any] = [:]
            if !effectParamsStr.isEmpty {
                // 调试：打印原始字符串
                if nameKey == "death" || nameKey == "merchant" || nameKey == "child" {
                    print("🔍 [CSV解析] \(nameKey) 原始effectParams字符串: \(effectParamsStr)")
                }
                
                if let data = effectParamsStr.data(using: .utf8),
                   let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    effectParams = json
                    if nameKey == "death" || nameKey == "merchant" || nameKey == "child" {
                        print("✅ [CSV解析] \(nameKey) effectParams解析成功: \(effectParams)")
                        // 特别检查死神的参数
                        if nameKey == "death" {
                            print("🔍 [CSV解析] 死神 rounds类型: \(type(of: effectParams["rounds"])), 值: \(effectParams["rounds"] ?? "nil")")
                            print("🔍 [CSV解析] 死神 bonusPerRound类型: \(type(of: effectParams["bonusPerRound"])), 值: \(effectParams["bonusPerRound"] ?? "nil")")
                            print("🔍 [CSV解析] 死神 gameOverAfter类型: \(type(of: effectParams["gameOverAfter"])), 值: \(effectParams["gameOverAfter"] ?? "nil")")
                        }
                    }
                } else {
                    print("⚠️ [CSV解析] \(nameKey) effectParams解析失败: \(effectParamsStr)")
                    // 尝试打印解析错误
                    if let data = effectParamsStr.data(using: .utf8) {
                        if let error = try? JSONSerialization.jsonObject(with: data) {
                            print("🔍 [CSV解析] 解析结果: \(error)")
                        } else {
                            print("🔍 [CSV解析] JSON解析完全失败")
                        }
                    }
                }
            } else {
                if nameKey == "death" || nameKey == "merchant" || nameKey == "child" {
                    print("ℹ️ [CSV解析] \(nameKey) effectParams为空")
                }
            }
            
            // 建立nameKey到id的映射
            symbolIdMap[nameKey] = id
            
            let configData = CSVSymbolConfigData(
                id: id,
                nameKey: nameKey,
                icon: icon,
                rarity: rarity,
                types: types,
                baseValue: baseValue,
                bondID: bondID,
                weight: weight,
                effect: effect,
                effectType: effectType,
                effectParams: effectParams,
                descriptionKey: descriptionKey
            )
            
            // 调试：打印关键符号的配置
            if nameKey == "death" || nameKey == "merchant" || nameKey == "child" {
                print("🔍 [CSV解析] 符号 \(nameKey): effectType=\(effectType), effectParams=\(effectParams)")
            }
            
            return configData
        }
        
        return !csvSymbols.isEmpty
    }
    
    /// 获取所有符号
    func getAllSymbols() -> [Symbol] {
        if useCSV {
            print("🔍 [符号配置] 使用CSV配置，共\(csvSymbols.count)个符号")
            return csvSymbols.map { config in
                // 解析bondID（多个用引号分割）
                let bondIDs = CSVReader.parseIDList(config.bondID).map { String($0) }
                
                let symbol = Symbol(
                    id: UUID(),
                    nameKey: config.nameKey,
                    icon: config.icon,
                    baseValue: config.baseValue,
                    rarity: mapRarity(config.rarity),
                    type: mapPrimaryType(config.types),
                    descriptionKey: config.descriptionKey,
                    weight: config.weight,
                    types: config.types,
                    effectType: config.effectType,
                    effectParams: config.effectParams,
                    bondIDs: bondIDs
                )
                
                // 验证符号的effectType是否正确设置
                if config.nameKey == "death" && symbol.effectType.isEmpty {
                    print("⚠️ [符号创建] 警告：死神符号的effectType为空！")
                }
                
                return symbol
            }
        }
        
        guard let configFile = configFile else {
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
                effectParams: config.effectParams.mapValues { $0.value },
                bondIDs: [] // JSON格式没有bondID
            )
        }
    }
    
    /// 根据权重随机选择符号（支持羁绊权重加成和全局权重buff）
    func getRandomSymbol(fromPool pool: [Symbol], symbolPool: [Symbol] = []) -> Symbol? {
        var adjustedPool = pool
        
        // **新功能1：应用羁绊权重加成（如正义必胜）**
        let bondBuffs = BondBuffConfigManager.shared.getActiveBondBuffs(symbolPool: symbolPool)
        let hasJusticeBond = bondBuffs.contains { $0.nameKey.contains("justice_bond") }
        
        // **新功能2：应用全局权重buff（正义必胜羁绊的猎人权重翻倍）**
        if hasJusticeBond {
            // 为猎人符号创建权重翻倍的副本（用于权重计算，使用nameKey匹配）
            adjustedPool = pool.map { symbol in
                if symbol.nameKey == "hunter" {
                    // 正义必胜羁绊：权重×2
                    let weightMultiplier = 2.0
                    
                    // 创建权重翻倍的副本
                    return Symbol(
                        id: symbol.id,
                        nameKey: symbol.nameKey,
                        icon: symbol.icon,
                        baseValue: symbol.baseValue,
                        rarity: symbol.rarity,
                        type: symbol.type,
                        descriptionKey: symbol.descriptionKey,
                        weight: Int(Double(symbol.weight) * weightMultiplier), // 应用权重倍数
                        types: symbol.types,
                        effectType: symbol.effectType,
                        effectParams: symbol.effectParams,
                        bondIDs: symbol.bondIDs
                    )
                }
                return symbol
            }
            
            print("⚖️ [羁绊Buff] 正义必胜：猎人权重翻倍应用于随机选择")
        }
        
        let totalWeight = adjustedPool.reduce(0) { $0 + $1.weight }
        guard totalWeight > 0 else { return pool.randomElement() }
        
        let randomValue = Int.random(in: 1...totalWeight)
        var currentWeight = 0
        
        for symbol in adjustedPool {
            currentWeight += symbol.weight
            if randomValue <= currentWeight {
                // 返回原始pool中的符号（不是调整后的副本）
                return pool.first(where: { $0.id == symbol.id }) ?? symbol
            }
        }
        
        return pool.first
    }
    
    /// 获取随机的起始符号
    func getStartingSymbols() -> [Symbol] {
        // 排除不应该作为初始符号的符号：死神、圣骑士、艺术品、魔法袋、丧尸
        let excludedNameKeys = ["death", "paladin", "artwork", "magic_bag", "zombie"]
        let allSymbols = getAllSymbols().filter { !excludedNameKeys.contains($0.nameKey) }
        let count = useCSV ? 3 : (configFile?.config.startingSymbolCount ?? 3)
        
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
    
    /// 根据nameKey获取符号的配置ID（用于羁绊系统）
    func getSymbolConfigId(byNameKey nameKey: String) -> Int? {
        if useCSV {
            return symbolIdMap[nameKey]
        }
        guard let configFile = configFile else { return nil }
        return configFile.symbols.first(where: { $0.nameKey == nameKey })?.id
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
    func getSymbolChoiceOptions(symbolPool: [Symbol] = []) -> [Symbol] {
        // 过滤掉不应该出现在三选一中的符号（死神只能通过死灵之书产出，龙火枪和圣骑士不应该出现）
        let excludedNameKeys = ["death", "dragon_fire_gun", "paladin"]
        let availableSymbols = getAllSymbols().filter { symbol in
            !excludedNameKeys.contains(symbol.nameKey) // 使用nameKey匹配更准确
        }
        
        var options: [Symbol] = []
        var usedSymbols = Set<String>() // 用于跟踪已选择的符号名称
        
        // 确保至少选择3个不同的符号
        var attempts = 0
        let maxAttempts = availableSymbols.count * 2 // 防止无限循环
        
        while options.count < 3 && attempts < maxAttempts {
            if let symbol = getRandomSymbol(fromPool: availableSymbols, symbolPool: symbolPool) {
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
        if useCSV {
            return true // CSV格式默认启用
        }
        return configFile?.config.enableEffects ?? true
    }
    
    /// 根据配置ID获取符号
    func getSymbol(byConfigId configId: Int) -> Symbol? {
        let allSymbols = getAllSymbols()
        return allSymbols.first { symbol in
            if let symbolConfigId = getSymbolConfigId(byNameKey: symbol.nameKey) {
                return symbolConfigId == configId
            }
            return false
        }
    }
    
    /// 获取符号池最大大小
    func getSymbolPoolMaxSize() -> Int {
        if useCSV {
            return 100 // CSV格式默认值
        }
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
