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
    case common = "普通"
    case rare = "稀有"
    case epic = "史诗"
    case legendary = "传说"
    
    var color: Color {
        switch self {
        case .common: return .gray
        case .rare: return .blue
        case .epic: return .purple
        case .legendary: return .orange
        }
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
        switch self {
        case .fruit: return "水果"
        case .coin: return "金币"
        case .animal: return "动物"
        case .special: return "特殊"
        case .gem: return "宝石"
        case .magic: return "魔法"
        }
    }
}

// MARK: - 符号模型
struct Symbol: Identifiable, Codable, Hashable {
    let id: UUID
    let name: String
    let icon: String // emoji图标
    let baseValue: Int
    let rarity: SymbolRarity
    let type: SymbolType // 主类型（用于向后兼容）
    let description: String
    let weight: Int // 随机权重
    let types: [String] // 所有类型标签
    let effectType: String // 效果类型
    let effectParams: [String: Any] // 效果参数
    
    init(id: UUID = UUID(), name: String, icon: String, baseValue: Int, rarity: SymbolRarity, type: SymbolType, description: String, weight: Int = 1000, types: [String] = [], effectType: String = "none", effectParams: [String: Any] = [:]) {
        self.id = id
        self.name = name
        self.icon = icon
        self.baseValue = baseValue
        self.rarity = rarity
        self.type = type
        self.description = description
        self.weight = weight
        self.types = types
        self.effectType = effectType
        self.effectParams = effectParams
    }
    
    // 计算实际收益
    func calculateValue(adjacentSymbols: [Symbol] = []) -> Int {
        var value = baseValue
        
        // 简单协同效果：相邻相同类型符号增加收益
        let sameTypeCount = adjacentSymbols.filter { $0.type == self.type }.count
        if sameTypeCount > 0 {
            value += sameTypeCount
        }
        
        return value
    }
    
    // 检查是否包含特定类型
    func hasType(_ typeTag: String) -> Bool {
        return types.contains(typeTag)
    }
    
    // Codable 实现
    enum CodingKeys: String, CodingKey {
        case id, name, icon, baseValue, rarity, type, description, weight, types, effectType
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        icon = try container.decode(String.self, forKey: .icon)
        baseValue = try container.decode(Int.self, forKey: .baseValue)
        rarity = try container.decode(SymbolRarity.self, forKey: .rarity)
        type = try container.decode(SymbolType.self, forKey: .type)
        description = try container.decode(String.self, forKey: .description)
        weight = try container.decodeIfPresent(Int.self, forKey: .weight) ?? 1000
        types = try container.decodeIfPresent([String].self, forKey: .types) ?? []
        effectType = try container.decodeIfPresent(String.self, forKey: .effectType) ?? "none"
        effectParams = [:]
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(icon, forKey: .icon)
        try container.encode(baseValue, forKey: .baseValue)
        try container.encode(rarity, forKey: .rarity)
        try container.encode(type, forKey: .type)
        try container.encode(description, forKey: .description)
        try container.encode(weight, forKey: .weight)
        try container.encode(types, forKey: .types)
        try container.encode(effectType, forKey: .effectType)
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
}

// MARK: - 哥布林模型
struct Goblin: Identifiable, Codable, Equatable {
    let id: Int
    let name: String
    let icon: String // emoji图标
    let isFree: Bool // 是否免费
    let buff: String // buff描述
    let buffType: String // buff类型（用于程序判断）
    let buffValue: Double // buff数值
    let unlockPrice: Int // 解锁价格（免费角色为0）
    let description: String // 详细描述
    
    init(id: Int, name: String, icon: String, isFree: Bool, buff: String, buffType: String = "", buffValue: Double = 0, unlockPrice: Int = 0, description: String = "") {
        self.id = id
        self.name = name
        self.icon = icon
        self.isFree = isFree
        self.buff = buff
        self.buffType = buffType
        self.buffValue = buffValue
        self.unlockPrice = unlockPrice
        self.description = description
    }
    
    // 从配置文件加载所有哥布林
    static var allGoblins: [Goblin] {
        return GoblinConfigManager.shared.getAllGoblins()
    }
}
