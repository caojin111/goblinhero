//
//  SymbolLibrary.swift
//  A004
//
//  符号库 - 所有可用符号定义
//

import Foundation

struct SymbolLibrary {
    // 所有可用符号
    static let allSymbols: [Symbol] = [
        // 基础水果符号
        Symbol(name: "苹果", icon: "🍎", baseValue: 2, rarity: .common, type: .fruit, description: "基础水果，提供2金币"),
        Symbol(name: "香蕉", icon: "🍌", baseValue: 2, rarity: .common, type: .fruit, description: "基础水果，提供2金币"),
        Symbol(name: "橙子", icon: "🍊", baseValue: 2, rarity: .common, type: .fruit, description: "基础水果，提供2金币"),
        Symbol(name: "葡萄", icon: "🍇", baseValue: 3, rarity: .common, type: .fruit, description: "基础水果，提供3金币"),
        Symbol(name: "西瓜", icon: "🍉", baseValue: 4, rarity: .rare, type: .fruit, description: "稀有水果，提供4金币"),
        
        // 金币符号
        Symbol(name: "铜币", icon: "🪙", baseValue: 1, rarity: .common, type: .coin, description: "基础金币，提供1金币"),
        Symbol(name: "银币", icon: "💰", baseValue: 3, rarity: .common, type: .coin, description: "银币，提供3金币"),
        Symbol(name: "金币", icon: "💎", baseValue: 5, rarity: .rare, type: .coin, description: "金币，提供5金币"),
        Symbol(name: "宝箱", icon: "💼", baseValue: 8, rarity: .epic, type: .coin, description: "宝箱，提供8金币"),
        
        // 动物符号
        Symbol(name: "蜜蜂", icon: "🐝", baseValue: 2, rarity: .common, type: .animal, description: "蜜蜂，相邻水果额外+1金币"),
        Symbol(name: "兔子", icon: "🐰", baseValue: 3, rarity: .rare, type: .animal, description: "幸运兔子，提供3金币"),
        Symbol(name: "小猫", icon: "🐱", baseValue: 4, rarity: .rare, type: .animal, description: "可爱小猫，提供4金币"),
        
        // 特殊符号
        Symbol(name: "幸运草", icon: "🍀", baseValue: 5, rarity: .epic, type: .special, description: "幸运草，提供5金币"),
        Symbol(name: "钻石", icon: "💎", baseValue: 10, rarity: .legendary, type: .special, description: "稀有钻石，提供10金币"),
        Symbol(name: "星星", icon: "⭐️", baseValue: 7, rarity: .epic, type: .special, description: "闪耀星星，提供7金币"),
    ]
    
    // 初始符号池（游戏开始时的符号）
    static let startingSymbols: [Symbol] = [
        Symbol(name: "铜币", icon: "🪙", baseValue: 1, rarity: .common, type: .coin, description: "基础金币，提供1金币"),
        Symbol(name: "苹果", icon: "🍎", baseValue: 2, rarity: .common, type: .fruit, description: "基础水果，提供2金币"),
        Symbol(name: "香蕉", icon: "🍌", baseValue: 2, rarity: .common, type: .fruit, description: "基础水果，提供2金币"),
    ]
    
    // 根据稀有度获取符号
    static func getSymbols(byRarity rarity: SymbolRarity) -> [Symbol] {
        return allSymbols.filter { $0.rarity == rarity }
    }
    
    // 随机获取符号（考虑稀有度权重）
    static func getRandomSymbols(count: Int) -> [Symbol] {
        var result: [Symbol] = []
        
        for _ in 0..<count {
            let random = Double.random(in: 0...1)
            let symbol: Symbol
            
            switch random {
            case 0..<0.5: // 50% 普通
                symbol = getSymbols(byRarity: .common).randomElement() ?? allSymbols[0]
            case 0.5..<0.8: // 30% 稀有
                symbol = getSymbols(byRarity: .rare).randomElement() ?? allSymbols[0]
            case 0.8..<0.95: // 15% 史诗
                symbol = getSymbols(byRarity: .epic).randomElement() ?? allSymbols[0]
            default: // 5% 传说
                symbol = getSymbols(byRarity: .legendary).randomElement() ?? allSymbols[0]
            }
            
            result.append(symbol)
        }
        
        return result
    }
}
