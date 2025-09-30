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
    let icon: String // SF Symbol名称
    let baseValue: Int
    let rarity: SymbolRarity
    let type: SymbolType
    let description: String
    
    init(id: UUID = UUID(), name: String, icon: String, baseValue: Int, rarity: SymbolRarity, type: SymbolType, description: String) {
        self.id = id
        self.name = name
        self.icon = icon
        self.baseValue = baseValue
        self.rarity = rarity
        self.type = type
        self.description = description
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
}
