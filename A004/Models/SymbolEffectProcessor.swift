//
//  SymbolEffectProcessor.swift
//  A004
//
//  符号效果处理器 - 处理所有符号的特殊效果
//

import Foundation

class SymbolEffectProcessor {
    // MARK: - 状态追踪
    private var cyclopsCounters: [String: Int] = [:] // 独眼怪物计数器
    private var diceCount: Int = 1 // 当前拥有的骰子数量
    private var eliminatedSymbolCount: Int = 0 // 本次消除的符号数量
    
    // MARK: - 重置回合状态
    func resetRoundState() {
        cyclopsCounters.removeAll()
        eliminatedSymbolCount = 0
        print("🔄 [效果处理] 回合重置：独眼怪物计数器清空，消除计数器清零")
    }
    
    // 获取消除的符号数量
    func getEliminatedSymbolCount() -> Int {
        return eliminatedSymbolCount
    }
    
    // MARK: - 骰子相关
    func getDiceCount() -> Int {
        return diceCount
    }
    
    func addDice(count: Int) {
        diceCount += count
        print("🎲 [骰子系统] 获得\(count)个骰子，当前拥有\(diceCount)个骰子")
    }
    
    func resetDiceCount() {
        diceCount = 1
    }
    
    // MARK: - 主处理方法
    func processMinedSymbols(
        minedSymbols: [Symbol],
        symbolPool: inout [Symbol],
        enableEffects: Bool,
        logCallback: ((String) -> Void)? = nil
    ) -> Int {
        // 重置本次消除计数器
        eliminatedSymbolCount = 0
        
        guard enableEffects else {
            let msg = "⚠️ 效果已禁用"
            print(msg)
            logCallback?(msg)
            return 0
        }
        
        guard !minedSymbols.isEmpty else {
            return 0
        }
        
        let header = "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        let title = "🎯 [效果处理] 开始处理\(minedSymbols.count)个符号的效果"
        let queue = "📋 [挖出队列] \(minedSymbols.map { $0.icon + $0.name }.joined(separator: " → "))"
        
        print(header)
        print(title)
        print(queue)
        print(header)
        
        logCallback?(header)
        logCallback?(title)
        logCallback?(queue)
        logCallback?(header + "\n")
        
        var totalBonus = 0
        
        // 按队列顺序依次处理每个符号
        for (index, symbol) in minedSymbols.enumerated() {
            let processing = "[\(index + 1)/\(minedSymbols.count)] 🔸 处理: \(symbol.icon) \(symbol.name)"
            print("\n\(processing)")
            logCallback?(processing)
            
            let bonus = processSymbolEffect(
                symbol: symbol,
                minedSymbols: minedSymbols,
                symbolPool: &symbolPool,
                logCallback: logCallback
            )
            
            if bonus != 0 {
                totalBonus += bonus
                let bonusMsg = "   💰 效果奖励: \(bonus > 0 ? "+" : "")\(bonus) 金币"
                print(bonusMsg)
                logCallback?(bonusMsg)
            } else {
                logCallback?("   (无效果)")
            }
            logCallback?("")
        }
        
        let footer = "\n" + header
        let summary = "✅ [效果处理] 完成，总效果奖励: \(totalBonus > 0 ? "+" : "")\(totalBonus) 金币"
        
        print(footer)
        print(summary)
        print(header + "\n")
        
        logCallback?(footer)
        logCallback?(summary)
        logCallback?(header)
        
        return totalBonus
    }
    
    // MARK: - 单个符号效果处理
    private func processSymbolEffect(
        symbol: Symbol,
        minedSymbols: [Symbol],
        symbolPool: inout [Symbol],
        logCallback: ((String) -> Void)? = nil
    ) -> Int {
        switch symbol.effectType {
        case "none":
            return 0
            
        case "conditional_bonus":
            return processConditionalBonus(symbol: symbol, symbolPool: symbolPool, logCallback: logCallback)
            
        case "count_bonus":
            return processCountBonus(symbol: symbol, symbolPool: symbolPool, logCallback: logCallback)
            
        case "mixed_count_bonus":
            return processMixedCountBonus(symbol: symbol, symbolPool: symbolPool, logCallback: logCallback)
            
        case "eliminate_bonus":
            return processEliminateBonus(symbol: symbol, minedSymbols: minedSymbols, symbolPool: &symbolPool, logCallback: logCallback)
            
        case "conditional_eliminate":
            return processConditionalEliminate(symbol: symbol, symbolPool: &symbolPool, logCallback: logCallback)
            
        case "conditional_target_eliminate":
            return processConditionalTargetEliminate(symbol: symbol, symbolPool: &symbolPool, logCallback: logCallback)
            
        case "random_spawn":
            return processRandomSpawn(symbol: symbol, symbolPool: &symbolPool, logCallback: logCallback)
            
        case "spawn_multiple":
            return processSpawnMultiple(symbol: symbol, symbolPool: &symbolPool, logCallback: logCallback)
            
        case "unlock_bonus":
            return processUnlockBonus(symbol: symbol, symbolPool: &symbolPool, logCallback: logCallback)
            
        case "universal_unlock":
            return processUniversalUnlock(symbol: symbol, symbolPool: &symbolPool, logCallback: logCallback)
            
        case "infect_and_bonus":
            return processInfectAndBonus(symbol: symbol, symbolPool: &symbolPool, logCallback: logCallback)
            
        case "diminishing_value":
            return processDiminishingValue(symbol: symbol, logCallback: logCallback)
            
        case "random_eliminate_bonus":
            return processRandomEliminateBonus(symbol: symbol, symbolPool: &symbolPool, logCallback: logCallback)
            
        case "combo_bonus":
            return processComboBonus(symbol: symbol, minedSymbols: minedSymbols, logCallback: logCallback)
            
        case "spawn_random":
            return processSpawnRandom(symbol: symbol, symbolPool: &symbolPool, logCallback: logCallback)
            
        case "dice_bonus":
            return processDiceBonus(symbol: symbol, logCallback: logCallback)
            
        case "spawn_random_multiple":
            return processSpawnRandomMultiple(symbol: symbol, symbolPool: &symbolPool, logCallback: logCallback)
            
        default:
            let msg = "   ⚠️ 未知效果类型: \(symbol.effectType)"
            print(msg)
            logCallback?(msg)
            return 0
        }
    }
    
    // MARK: - 效果实现
    
    /// 条件奖励：如果符号池有指定符号，则获得奖励
    private func processConditionalBonus(symbol: Symbol, symbolPool: [Symbol], logCallback: ((String) -> Void)? = nil) -> Int {
        guard let requireSymbol = symbol.effectParams["requireSymbol"] as? String,
              let bonus = symbol.effectParams["bonus"] as? Int else {
            return 0
        }
        
        let hasRequired = symbolPool.contains { $0.name == requireSymbol }
        if hasRequired {
            let msg = "   ✓ 条件满足：符号池有\(requireSymbol)，获得\(bonus)金币"
            print(msg)
            logCallback?(msg)
            return bonus
        } else {
            let msg = "   ✗ 条件不满足：符号池没有\(requireSymbol)"
            print(msg)
            logCallback?(msg)
            return 0
        }
    }
    
    /// 计数奖励：根据符号池中指定类型的数量给予奖励
    private func processCountBonus(symbol: Symbol, symbolPool: [Symbol], logCallback: ((String) -> Void)? = nil) -> Int {
        guard let countType = symbol.effectParams["countType"] as? String,
              let bonusPerCount = symbol.effectParams["bonusPerCount"] as? Int else {
            return 0
        }
        
        let count = symbolPool.filter { $0.types.contains(countType) }.count
        let bonus = count * bonusPerCount
        
        if count > 0 {
            let msg = "   ✓ 符号池有\(count)个\(countType)，获得\(bonus)金币"
            print(msg)
            logCallback?(msg)
        } else {
            let msg = "   ✗ 符号池没有\(countType)类型符号"
            print(msg)
            logCallback?(msg)
        }
        
        return bonus
    }
    
    /// 混合计数奖励：多种类型不同奖励
    private func processMixedCountBonus(symbol: Symbol, symbolPool: [Symbol], logCallback: ((String) -> Void)? = nil) -> Int {
        guard let bonuses = symbol.effectParams["bonuses"] as? [[String: Any]] else {
            return 0
        }
        
        var totalBonus = 0
        
        for bonusData in bonuses {
            guard let countType = bonusData["countType"] as? String,
                  let bonusPerCount = bonusData["bonusPerCount"] as? Int else {
                continue
            }
            
            let count = symbolPool.filter { $0.types.contains(countType) }.count
            let bonus = count * bonusPerCount
            
            if bonus != 0 {
                let msg = "   \(bonus > 0 ? "+" : "")\(bonus) 金币 (符号池\(count)个\(countType) × \(bonusPerCount))"
                print(msg)
                logCallback?(msg)
                totalBonus += bonus
            }
        }
        
        return totalBonus
    }
    
    /// 消除奖励：消除本次挖出的指定类型符号并获得奖励
    private func processEliminateBonus(symbol: Symbol, minedSymbols: [Symbol], symbolPool: inout [Symbol], logCallback: ((String) -> Void)? = nil) -> Int {
        guard let eliminateType = symbol.effectParams["eliminateType"] as? String,
              let bonus = symbol.effectParams["bonus"] as? Int else {
            return 0
        }
        
        // 找出本次挖出的要消除的符号
        let toEliminate = minedSymbols.filter { $0.types.contains(eliminateType) }
        
        if toEliminate.isEmpty {
            let msg = "   ✗ 本次没有挖出\(eliminateType)类型符号"
            print(msg)
            logCallback?(msg)
            return 0
        }
        
        // 从符号池消除
        var eliminatedCount = 0
        for targetSymbol in toEliminate {
            if let index = symbolPool.firstIndex(where: { $0.name == targetSymbol.name }) {
                symbolPool.remove(at: index)
                eliminatedCount += 1
                eliminatedSymbolCount += 1 // 计入消除数量
                let msg = "   🗑️ 消除: \(targetSymbol.icon) \(targetSymbol.name)"
                print(msg)
                logCallback?(msg)
            }
        }
        
        let totalBonus = eliminatedCount * bonus
        if eliminatedCount > 0 {
            let msg = "   ✓ 消除\(eliminatedCount)个\(eliminateType)，获得\(totalBonus)金币"
            print(msg)
            logCallback?(msg)
        }
        
        return totalBonus
    }
    
    /// 条件消除：遇到特定符号时被消除
    private func processConditionalEliminate(symbol: Symbol, symbolPool: inout [Symbol], logCallback: ((String) -> Void)? = nil) -> Int {
        guard let triggerSymbol = symbol.effectParams["triggerSymbol"] as? String,
              let bonus = symbol.effectParams["bonus"] as? Int else {
            return 0
        }
        
        let hasTrigger = symbolPool.contains { $0.name == triggerSymbol }
        
        if hasTrigger {
            // 从符号池移除自己
            if let index = symbolPool.firstIndex(where: { $0.name == symbol.name }) {
                symbolPool.remove(at: index)
                eliminatedSymbolCount += 1 // 计入消除数量
                let msg = "   🗑️ 遇到\(triggerSymbol)，\(symbol.name)被消除，获得\(bonus)金币"
                print(msg)
                logCallback?(msg)
                return bonus
            }
        }
        
        return 0
    }
    
    /// 条件目标消除：如果有特定符号，则消除该符号
    private func processConditionalTargetEliminate(symbol: Symbol, symbolPool: inout [Symbol], logCallback: ((String) -> Void)? = nil) -> Int {
        guard let targetSymbol = symbol.effectParams["targetSymbol"] as? String,
              let bonus = symbol.effectParams["bonus"] as? Int else {
            return 0
        }
        
        // 检查符号池是否有目标符号
        if let index = symbolPool.firstIndex(where: { $0.name == targetSymbol }) {
            let removed = symbolPool.remove(at: index)
            eliminatedSymbolCount += 1 // 计入消除数量
            let msg = "   🗑️ 消除目标: \(removed.icon) \(removed.name)，获得\(bonus)金币"
            print(msg)
            logCallback?(msg)
            return bonus
        } else {
            let msg = "   ✗ 符号池没有\(targetSymbol)"
            print(msg)
            logCallback?(msg)
            return 0
        }
    }
    
    /// 随机生成：概率性生成其他符号
    private func processRandomSpawn(symbol: Symbol, symbolPool: inout [Symbol], logCallback: ((String) -> Void)? = nil) -> Int {
        guard let options = symbol.effectParams["options"] as? [[String: Any]] else {
            return 0
        }
        
        let random = Double.random(in: 0...1)
        var cumulative = 0.0
        
        for option in options {
            guard let symbolName = option["symbol"] as? String,
                  let probability = option["probability"] as? Double else {
                continue
            }
            
            cumulative += probability
            if random <= cumulative {
                // 生成符号
                if let newSymbol = SymbolLibrary.getSymbol(byName: symbolName) {
                    symbolPool.append(newSymbol)
                    let msg = "   🎲 随机生成: \(newSymbol.icon) \(newSymbol.name) (概率\(Int(probability * 100))%)"
                    print(msg)
                    logCallback?(msg)
                }
                break
            }
        }
        
        return 0
    }
    
    /// 批量生成：生成多个指定符号
    private func processSpawnMultiple(symbol: Symbol, symbolPool: inout [Symbol], logCallback: ((String) -> Void)? = nil) -> Int {
        guard let symbolName = symbol.effectParams["symbol"] as? String,
              let count = symbol.effectParams["count"] as? Int else {
            return 0
        }
        
        if let newSymbol = SymbolLibrary.getSymbol(byName: symbolName) {
            for _ in 0..<count {
                symbolPool.append(newSymbol)
            }
            let msg = "   🎁 生成\(count)个: \(newSymbol.icon) \(newSymbol.name)"
            print(msg)
            logCallback?(msg)
        }
        
        return 0
    }
    
    /// 解锁奖励：消除指定符号并获得奖励
    private func processUnlockBonus(symbol: Symbol, symbolPool: inout [Symbol], logCallback: ((String) -> Void)? = nil) -> Int {
        guard let unlockSymbol = symbol.effectParams["unlockSymbol"] as? String,
              let bonus = symbol.effectParams["bonus"] as? Int else {
            return 0
        }
        
        if let index = symbolPool.firstIndex(where: { $0.name == unlockSymbol }) {
            let removed = symbolPool.remove(at: index)
            eliminatedSymbolCount += 1 // 计入消除数量
            let msg = "   🔓 解锁消除: \(removed.icon) \(removed.name)，获得\(bonus)金币"
            print(msg)
            logCallback?(msg)
            return bonus
        } else {
            let msg = "   ✗ 符号池没有\(unlockSymbol)"
            print(msg)
            logCallback?(msg)
            return 0
        }
    }
    
    /// 万能解锁：消除任意类型的箱子
    private func processUniversalUnlock(symbol: Symbol, symbolPool: inout [Symbol], logCallback: ((String) -> Void)? = nil) -> Int {
        guard let unlockTypes = symbol.effectParams["unlockTypes"] as? [String] else {
            return 0
        }
        
        // 找到符号池中的纯箱子（types包含两个"box"的符号）
        let boxes = symbolPool.filter { box in
            box.name != symbol.name && // 排除自己
            unlockTypes.contains("box") && // 需要是box类型
            box.types.filter({ $0 == "box" }).count >= 2 // 必须有两个"box"标签（纯箱子）
        }
        
        if let bestBox = boxes.max(by: { $0.baseValue < $1.baseValue }),
           let index = symbolPool.firstIndex(where: { $0.name == bestBox.name }) {
            let bonus = bestBox.baseValue * 2 // 获得箱子价值的2倍
            symbolPool.remove(at: index)
            eliminatedSymbolCount += 1 // 计入消除数量
            let msg = "   🔓 万能解锁: \(bestBox.icon) \(bestBox.name)，获得\(bonus)金币"
            print(msg)
            logCallback?(msg)
            return bonus
        } else {
            let msg = "   ✗ 符号池没有可解锁的纯箱子"
            print(msg)
            logCallback?(msg)
            return 0
        }
    }
    
    /// 感染与奖励：感染人类并根据丧尸数量获得奖励
    private func processInfectAndBonus(symbol: Symbol, symbolPool: inout [Symbol], logCallback: ((String) -> Void)? = nil) -> Int {
        guard let infectType = symbol.effectParams["infectType"] as? String,
              let countType = symbol.effectParams["countType"] as? String,
              let bonusPerCount = symbol.effectParams["bonusPerCount"] as? Int else {
            return 0
        }
        
        // 找到一个人类并感染
        if let humanIndex = symbolPool.firstIndex(where: { $0.types.contains(infectType) }) {
            let human = symbolPool[humanIndex]
            // 替换成丧尸
            if let zombie = SymbolLibrary.getSymbol(byName: countType) {
                symbolPool[humanIndex] = zombie
                let msg = "   🧟 感染: \(human.icon) \(human.name) → \(zombie.icon) \(zombie.name)"
                print(msg)
                logCallback?(msg)
            }
        } else {
            let msg = "   ✗ 符号池没有\(infectType)可感染"
            print(msg)
            logCallback?(msg)
        }
        
        // 计算丧尸数量奖励
        let zombieCount = symbolPool.filter { $0.name == countType }.count
        let bonus = zombieCount * bonusPerCount
        
        if zombieCount > 0 {
            let msg = "   💰 符号池有\(zombieCount)个\(countType)，获得\(bonus)金币"
            print(msg)
            logCallback?(msg)
        }
        
        return bonus
    }
    
    /// 递减价值：每次价值递减
    private func processDiminishingValue(symbol: Symbol, logCallback: ((String) -> Void)? = nil) -> Int {
        guard let initialValue = symbol.effectParams["initialValue"] as? Int,
              let decrement = symbol.effectParams["decrement"] as? Int,
              let minValue = symbol.effectParams["minValue"] as? Int else {
            return 0
        }
        
        let key = symbol.name
        let currentCount = cyclopsCounters[key, default: 0]
        let value = max(initialValue - (currentCount * decrement), minValue)
        
        cyclopsCounters[key] = currentCount + 1
        
        let msg = "   🔽 第\(currentCount + 1)次挖出，价值: \(value)金币"
        print(msg)
        logCallback?(msg)
        
        return value
    }
    
    /// 随机消除奖励：随机消除一个符号
    private func processRandomEliminateBonus(symbol: Symbol, symbolPool: inout [Symbol], logCallback: ((String) -> Void)? = nil) -> Int {
        guard let bonus = symbol.effectParams["bonus"] as? Int else {
            return 0
        }
        
        // 排除自己
        let eligibleSymbols = symbolPool.filter { $0.name != symbol.name }
        
        if let randomSymbol = eligibleSymbols.randomElement(),
           let index = symbolPool.firstIndex(where: { $0.name == randomSymbol.name }) {
            let removed = symbolPool.remove(at: index)
            eliminatedSymbolCount += 1 // 计入消除数量
            let msg = "   🎲 随机消除: \(removed.icon) \(removed.name)，获得\(bonus)金币"
            print(msg)
            logCallback?(msg)
            return bonus
        } else {
            let msg = "   ✗ 符号池为空，无法消除"
            print(msg)
            logCallback?(msg)
            return 0
        }
    }
    
    /// 组合奖励：与特定符号组合时获得奖励
    private func processComboBonus(symbol: Symbol, minedSymbols: [Symbol], logCallback: ((String) -> Void)? = nil) -> Int {
        guard let comboSymbols = symbol.effectParams["comboSymbols"] as? [String],
              let bonus = symbol.effectParams["bonus"] as? Int else {
            return 0
        }
        
        // 检查本次挖出是否有所有组合符号
        let hasAllCombo = comboSymbols.allSatisfy { targetName in
            minedSymbols.contains { $0.name == targetName }
        }
        
        if hasAllCombo {
            let msg = "   ✨ 组合成功！与\(comboSymbols.joined(separator: "、"))同时挖出，获得\(bonus)金币"
            print(msg)
            logCallback?(msg)
            return bonus
        } else {
            let msg = "   ✗ 组合未完成，需要\(comboSymbols.joined(separator: "、"))"
            print(msg)
            logCallback?(msg)
            return 0
        }
    }
    
    /// 生成随机符号
    private func processSpawnRandom(symbol: Symbol, symbolPool: inout [Symbol], logCallback: ((String) -> Void)? = nil) -> Int {
        guard let count = symbol.effectParams["count"] as? Int else {
            return 0
        }
        
        let randomSymbols = SymbolLibrary.getRandomSymbols(count: count)
        symbolPool.append(contentsOf: randomSymbols)
        
        let msg = "   🎁 随机生成\(count)个符号: \(randomSymbols.map { $0.icon + $0.name }.joined(separator: ", "))"
        print(msg)
        logCallback?(msg)
        
        return 0
    }
    
    /// 骰子奖励
    private func processDiceBonus(symbol: Symbol, logCallback: ((String) -> Void)? = nil) -> Int {
        guard let diceBonus = symbol.effectParams["diceBonus"] as? Int else {
            let msg = "   ⚠️ 骰子效果参数错误"
            print(msg)
            logCallback?(msg)
            return 0
        }
        
        addDice(count: diceBonus)
        let msg = "   🎲 获得\(diceBonus)个骰子，当前拥有\(diceCount)个骰子"
        print(msg)
        logCallback?(msg)
        
        return 0
    }
    
    /// 随机数量生成
    private func processSpawnRandomMultiple(symbol: Symbol, symbolPool: inout [Symbol], logCallback: ((String) -> Void)? = nil) -> Int {
        guard let minCount = symbol.effectParams["minCount"] as? Int,
              let maxCount = symbol.effectParams["maxCount"] as? Int else {
            return 0
        }
        
        let count = Int.random(in: minCount...maxCount)
        let randomSymbols = SymbolLibrary.getRandomSymbols(count: count)
        symbolPool.append(contentsOf: randomSymbols)
        
        let msg = "   🎒 魔法袋生成\(count)个随机符号: \(randomSymbols.map { $0.icon + $0.name }.joined(separator: ", "))"
        print(msg)
        logCallback?(msg)
        
        return 0
    }
}

