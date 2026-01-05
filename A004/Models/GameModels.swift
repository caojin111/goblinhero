//
//  GameModels.swift
//  A004
//
//  游戏数据模型
//

import Foundation
import SwiftUI

// MARK: - 符号稀有度
enum SymbolRarity: String, Codable {
    case common = "common"
    case rare = "rare"
    case epic = "epic"
    case legendary = "legendary"
    
    var color: Color {
        switch self {
        case .common: return .gray
        case .rare: return .blue
        case .epic: return .purple
        case .legendary: return .orange
        }
    }
    
    // 本地化显示名称
    var displayName: String {
        return LocalizationManager.shared.localized("rarity.\(rawValue)")
    }
}

// MARK: - 符号类型
enum SymbolType: String, Codable, CaseIterable {
    case fruit = "fruit"
    case coin = "coin"
    case animal = "animal"
    case special = "special"
    case gem = "gem"
    case magic = "magic"
    
    var displayName: String {
        return LocalizationManager.shared.localized("symbol_type.\(rawValue)")
    }
}

// MARK: - 符号模型
struct Symbol: Identifiable, Codable, Hashable {
    let id: UUID
    let nameKey: String // 多语言键名
    let icon: String // 图片资源名（如symbol_01.png）
    let baseValue: Int
    let rarity: SymbolRarity
    let type: SymbolType // 主类型（用于向后兼容）
    let descriptionKey: String // 多语言描述键名
    let weight: Int // 随机权重
    let types: [String] // 所有类型标签
    let effectType: String // 效果类型
    let effectParams: [String: Any] // 效果参数
    let bondIDs: [String] // 此符号可生效的羁绊ID列表

    // 兼容性属性：返回本地化的名称
    var name: String {
        return LocalizationManager.shared.localized("symbols.\(nameKey).name")
    }

    // 兼容性属性：返回本地化的描述
    var description: String {
        return LocalizationManager.shared.localized("symbols.\(nameKey).description")
    }

    // 获取图片资源名（去掉.png后缀，用于Image加载）
    var imageName: String {
        if icon.hasSuffix(".png") {
            // 去掉.png后缀，因为Assets.xcassets中的imageset名称不包含扩展名
            let name = String(icon.dropLast(4))
            return name
        }
        return icon
    }
    
    // 判断是否为图片资源（而非emoji）
    var isImageResource: Bool {
        return icon.hasSuffix(".png") || icon.hasSuffix(".jpg") || icon.hasSuffix(".jpeg")
    }

    init(id: UUID = UUID(), nameKey: String, icon: String, baseValue: Int, rarity: SymbolRarity, type: SymbolType, descriptionKey: String, weight: Int = 1000, types: [String] = [], effectType: String = "none", effectParams: [String: Any] = [:], bondIDs: [String] = []) {
        self.id = id
        self.nameKey = nameKey
        self.icon = icon
        self.baseValue = baseValue
        self.rarity = rarity
        self.type = type
        self.descriptionKey = descriptionKey
        self.weight = weight
        self.types = types
        self.effectType = effectType
        self.effectParams = effectParams
        self.bondIDs = bondIDs
    }
    
    // 计算实际收益
    func calculateValue(adjacentSymbols: [Symbol] = [], effectProcessor: SymbolEffectProcessor? = nil, symbolPool: [Symbol] = []) -> Int {
        var value = baseValue

        // **新功能：应用全局buff**
        if let processor = effectProcessor {
            // 应用基础价值加成（如商人的buff），使用nameKey匹配以避免多语言影响
            value += processor.getGlobalBuffBonus(for: nameKey)

            // 应用倍率（如可能的其他buff）
            let multiplier = processor.getGlobalBuffMultiplier(for: nameKey, symbolPool: symbolPool)
            value = Int(Double(value) * multiplier)
        }

        // 相邻符号加成机制已移除

        return value
    }
    
    // 检查是否包含特定类型
    func hasType(_ typeTag: String) -> Bool {
        return types.contains(typeTag)
    }
    
    // Codable 实现
    enum CodingKeys: String, CodingKey {
        case id, nameKey, icon, baseValue, rarity, type, descriptionKey, weight, types, effectType, effectParams, bondIDs
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        nameKey = try container.decode(String.self, forKey: .nameKey)
        icon = try container.decode(String.self, forKey: .icon)
        baseValue = try container.decode(Int.self, forKey: .baseValue)
        rarity = try container.decode(SymbolRarity.self, forKey: .rarity)
        type = try container.decode(SymbolType.self, forKey: .type)
        descriptionKey = try container.decode(String.self, forKey: .descriptionKey)
        weight = try container.decodeIfPresent(Int.self, forKey: .weight) ?? 1000
        types = try container.decodeIfPresent([String].self, forKey: .types) ?? []
        effectType = try container.decodeIfPresent(String.self, forKey: .effectType) ?? "none"
        // 注意：effectParams 不能从 JSON 解码，因为它是 [String: Any]
        // 如果是从 CSV 创建的符号，effectParams 已经在 SymbolConfigManager 中设置
        effectParams = [:] // 简化：不直接解码 effectParams
        bondIDs = try container.decodeIfPresent([String].self, forKey: .bondIDs) ?? []
        
        // 调试：如果是从JSON解码的符号，effectParams会是空的
        if effectParams.isEmpty && effectType != "none" {
            print("⚠️ [符号解码] 警告：符号 \(nameKey) 的 effectType=\(effectType) 但 effectParams 为空（可能是从JSON解码的）")
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(nameKey, forKey: .nameKey)
        try container.encode(icon, forKey: .icon)
        try container.encode(baseValue, forKey: .baseValue)
        try container.encode(rarity, forKey: .rarity)
        try container.encode(type, forKey: .type)
        try container.encode(descriptionKey, forKey: .descriptionKey)
        try container.encode(weight, forKey: .weight)
        try container.encode(types, forKey: .types)
        try container.encode(effectType, forKey: .effectType)
        try container.encode(bondIDs, forKey: .bondIDs)
        // 简化：不直接编码 effectParams
    }
    
    // Hashable 实现
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: Symbol, rhs: Symbol) -> Bool {
        return lhs.id == rhs.id
    }
}

// MARK: - 道具模型
struct Item: Identifiable, Codable {
    let id: UUID
    let name: String
    let icon: String
    let description: String
    let multiplier: Double // 收益倍率
    
    init(id: UUID = UUID(), name: String, icon: String, description: String, multiplier: Double = 1.0) {
        self.id = id
        self.name = name
        self.icon = icon
        self.description = description
        self.multiplier = multiplier
    }
}

// MARK: - 游戏阶段
enum GamePhase {
    case selectingSymbol // 选择符号
    case spinning // 旋转中
    case result // 结果展示
    case payingRent // 支付房租
    case gameOver // 游戏结束
}

// MARK: - 老虎机格子
struct SlotCell: Identifiable, Hashable {
    let id = UUID()
    var symbol: Symbol?
    var isHighlighted: Bool = false
    var isMined: Bool = false // 是否已挖开矿石
    var isSpecial: Bool = false // classic tale 特殊格（收益翻倍）
}

// MARK: - 哥布林模型
struct Goblin: Identifiable, Codable, Equatable {
    let id: Int
    let nameKey: String // 多语言键名
    let icon: String // emoji图标
    let isFree: Bool // 是否免费
    let buffKey: String // buff描述键名
    let buffType: String // buff类型（用于程序判断）
    let buffValue: Double // buff数值
    let unlockPrice: Int // 解锁价格（免费角色为0）
    let descriptionKey: String // 详细描述键名
    let unlockCurrency: String // 解锁货币类型："coins" 或 "diamonds" 或 "usd"
    let productId: String? // StoreKit product identifier (用于 USD 购买)

    // 兼容性属性：返回本地化的名称
    var name: String {
        return LocalizationManager.shared.localized("goblins.\(nameKey).name")
    }

    // 兼容性属性：返回本地化的buff描述
    var buff: String {
        return LocalizationManager.shared.localized("goblins.\(nameKey).buff")
    }

    // 兼容性属性：返回本地化的详细描述
    var description: String {
        return LocalizationManager.shared.localized("goblins.\(nameKey).description")
    }
    
    init(id: Int, nameKey: String, icon: String, isFree: Bool, buffKey: String, buffType: String = "", buffValue: Double = 0, unlockPrice: Int = 0, descriptionKey: String = "", unlockCurrency: String = "coins", productId: String? = nil) {
        self.id = id
        self.nameKey = nameKey
        self.icon = icon
        self.isFree = isFree
        self.buffKey = buffKey
        self.buffType = buffType
        self.buffValue = buffValue
        self.unlockPrice = unlockPrice
        self.descriptionKey = descriptionKey
        self.unlockCurrency = unlockCurrency
        self.productId = productId
    }
    
    // 从配置文件加载所有哥布林
    static var allGoblins: [Goblin] {
        return GoblinConfigManager.shared.getAllGoblins()
    }
}
