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

    // 新增状态追踪
    private var globalBuffs: [String: [String: Any]] = [:] // 全局buff系统，格式: ["buffType": ["targetSymbols": [...], "baseValueBonus": 20, ...]]
    private var roundStartChecks: [String: [String: Any]] = [:] // 回合开始检查，格式: ["symbolName": ["checkType": "synthesis", "params": [...]]]
    private var tempDiceBonus: Int = 0 // 临时骰子奖励（本回合有效）
    private var nextRoundBonuses: [String: [String: Any]] = [:] // 下回合奖励
    private var roundStartBuffs: [String: [String: Any]] = [:] // 回合开始buff
    private var roundStartPenalties: [String: [String: Any]] = [:] // 回合开始惩罚
    private var symbolTypeConversions: [String: [String: Any]] = [:] // 符号类型转换记录
    private var shouldDoubleNextReward: Bool = false // 下回合收益是否翻倍（丰收之神效果）

    // MARK: - 全局buff相关方法
    func applyGlobalBuff(buffType: String, targetSymbols: [String], baseValueBonus: Int? = nil, multiplier: Double? = nil) {
        globalBuffs[buffType] = [
            "targetSymbols": targetSymbols,
            "baseValueBonus": baseValueBonus ?? 0,
            "multiplier": multiplier ?? 1.0,
            "isPersistent": true
        ]
        print("🔥 [全局buff] 激活 \(buffType): 目标\(targetSymbols.joined(separator: ",")) 基础价值+\(baseValueBonus ?? 0)")
    }

    func getGlobalBuffMultiplier(for symbolName: String) -> Double {
        var totalMultiplier = 1.0
        for (_, buffData) in globalBuffs {
            if let targetSymbols = buffData["targetSymbols"] as? [String],
               targetSymbols.contains(symbolName),
               let multiplier = buffData["multiplier"] as? Double {
                totalMultiplier *= multiplier
            }
        }
        return totalMultiplier
    }

    func getGlobalBuffBonus(for symbolName: String) -> Int {
        var totalBonus = 0
        for (_, buffData) in globalBuffs {
            if let targetSymbols = buffData["targetSymbols"] as? [String],
               targetSymbols.contains(symbolName),
               let bonus = buffData["baseValueBonus"] as? Int {
                totalBonus += bonus
            }
        }
        return totalBonus
    }

    func clearNonPersistentBuffs() {
        // 清除非持久性buff（如果需要的话）
        globalBuffs = globalBuffs.filter { (_, buffData) in
            buffData["isPersistent"] as? Bool ?? true
        }
    }
    
    // MARK: - 重置回合状态
    func resetRoundState() {
        cyclopsCounters.removeAll()
        eliminatedSymbolCount = 0
        tempDiceBonus = 0 // 重置临时骰子奖励
        nextRoundBonuses.removeAll() // 清除已使用的下回合奖励
        // 注意：shouldDoubleNextReward 不在回合开始时清除，而是在结算收益时清除
        print("🔄 [效果处理] 回合重置：独眼怪物计数器清空，消除计数器清零，临时奖励清空")
    }

    // MARK: - 回合开始处理
    func processRoundStart(symbolPool: inout [Symbol]) -> Int {
        var totalBonus = 0

        print("\n🌅 [回合开始] 开始处理回合开始效果")
        print("🔍 [调试] 当前注册的回合开始buff数量: \(roundStartBuffs.count)")
        for (name, data) in roundStartBuffs {
            print("   - \(name): \(data)")
        }

        // 处理回合开始buff（如死神）
        var buffsToRemove: [String] = []
        for (symbolName, buffData) in roundStartBuffs {
            if let bonusPerRound = buffData["bonusPerRound"] as? Int,
               let rounds = buffData["rounds"] as? Int,
               let currentRound = buffData["currentRound"] as? Int {

                print("🔍 [调试] 处理\(symbolName)的buff: 当前回合\(currentRound)/\(rounds), 每回合奖励\(bonusPerRound)")

                if currentRound < rounds {
                    totalBonus += bonusPerRound
                    
                    // 正确更新字典：先获取，修改，再赋值
                    var updatedBuffData = buffData
                    updatedBuffData["currentRound"] = currentRound + 1
                    roundStartBuffs[symbolName] = updatedBuffData

                    let msg = "💀 \(symbolName)回合开始buff: 获得\(bonusPerRound)金币 (第\(currentRound + 1)/\(rounds)回合)"
                    print(msg)

                    if currentRound + 1 >= rounds {
                        // buff结束，检查是否需要结束游戏
                        if buffData["gameOverAfter"] as? Bool ?? false {
                            print("💀 游戏结束！\(symbolName)的\(rounds)回合buff已结束")
                            // 这里可以设置游戏结束标志
                        }
                        buffsToRemove.append(symbolName)
                    }
                } else {
                    print("🔍 [调试] \(symbolName)的buff已结束（\(currentRound) >= \(rounds)）")
                }
            } else {
                print("⚠️ [调试] \(symbolName)的buff数据格式错误: \(buffData)")
            }
        }
        
        // 移除已结束的buff
        for symbolName in buffsToRemove {
            roundStartBuffs.removeValue(forKey: symbolName)
            print("🗑️ [调试] 移除已结束的buff: \(symbolName)")
        }

        // 处理回合开始惩罚（如吸血鬼、狼人）
        for (symbolName, penaltyData) in roundStartPenalties {
            if let penalty = penaltyData["penalty"] as? Int {
                totalBonus += penalty // 惩罚是负数，所以加到总奖励中
                let msg = "🧛 \(symbolName)回合开始惩罚: \(penalty)金币"
                print(msg)
            }
        }

        // 处理回合开始消除（如忍者）
        for (symbolName, eliminateData) in roundStartChecks {
            if let checkType = eliminateData["checkType"] as? String,
               checkType == "eliminate_zombies" {

                if let requireSymbol = eliminateData["requireSymbol"] as? String,
                   let targetSymbols = eliminateData["targetSymbols"] as? [String] {

                    // 检查是否有需要的符号
                    let hasRequired = symbolPool.contains { $0.name == requireSymbol }

                    if hasRequired {
                        var eliminatedCount = 0
                        for targetName in targetSymbols {
                            let toEliminate = symbolPool.filter { $0.name == targetName }
                            for symbol in toEliminate {
                                if let index = symbolPool.firstIndex(where: { $0.name == symbol.name }) {
                                    symbolPool.remove(at: index)
                                    eliminatedCount += 1
                                    eliminatedSymbolCount += 1
                                }
                            }
                        }

                        if eliminatedCount > 0 {
                            let msg = "🥷 \(symbolName)回合开始消除: 清除\(eliminatedCount)个丧尸"
                            print(msg)
                        }
                    }
                }
            }
        }

        // 处理合成检查（如花精合成森林妖精）
        var synthesisPerformed = false
        repeat {
            synthesisPerformed = false

            let flowerFairies = symbolPool.filter { $0.name == "花精" }
            if flowerFairies.count >= 3 {
                // 移除3个花精
                var removedCount = 0
                symbolPool.removeAll { symbol in
                    if symbol.name == "花精" && removedCount < 3 {
                        removedCount += 1
                        return true
                    }
                    return false
                }

                // 添加一个森林妖精
                if let forestElf = SymbolLibrary.getSymbol(byName: "森林妖精") {
                    symbolPool.append(forestElf)
                    synthesisPerformed = true
                    let msg = "🧚 花精合成: 3个花精 → 1个森林妖精"
                    print(msg)
                }
            }
        } while synthesisPerformed

        // 处理元素收集检查（要求5种不同的元素，而不是5个元素）
        let requiredElements = Set(["水元素", "火元素", "雷元素", "冰元素", "土元素"])
        
        // 从符号池中提取所有元素类型的符号名称，使用Set去重确保只计算不同的元素类型
        let collectedElementNames = Set(symbolPool.filter { requiredElements.contains($0.name) }.map { $0.name })
        
        // 检查是否集齐了全部5种不同的元素
        if collectedElementNames.count == 5 && collectedElementNames == requiredElements {
            // 收集齐全五种不同元素，获得500金币
            totalBonus += 500
            let msg = "✨ 五元素收集完成（5种不同元素）: 获得500金币"
            print(msg)
        } else {
            // 调试信息：显示当前收集到的元素
            if collectedElementNames.count > 0 {
                let msg = "🔍 [元素收集] 当前收集到\(collectedElementNames.count)种元素: \(collectedElementNames.sorted().joined(separator: ", "))"
                print(msg)
            }
        }

        let summary = "🌅 [回合开始] 总效果: \(totalBonus > 0 ? "+" : "")\(totalBonus) 金币"
        print(summary)

        return totalBonus
    }

    // MARK: - 临时骰子奖励
    func getTempDiceBonus() -> Int {
        return tempDiceBonus
    }

    func addTempDiceBonus(count: Int) {
        tempDiceBonus += count
        print("🎲 [临时骰子] 获得\(count)个临时骰子，本回合有效")
    }

    // MARK: - 下回合奖励
    func addNextRoundBonus(symbolName: String, bonus: Int, eliminateSelf: Bool = false) {
        nextRoundBonuses[symbolName] = [
            "bonus": bonus,
            "eliminateSelf": eliminateSelf,
            "used": false
        ]
    }

    func processNextRoundBonuses(symbolPool: inout [Symbol]) -> Int {
        var totalBonus = 0

        for (symbolName, bonusData) in nextRoundBonuses {
            if let bonus = bonusData["bonus"] as? Int,
               let eliminateSelf = bonusData["eliminateSelf"] as? Bool,
               let used = bonusData["used"] as? Bool,
               !used {

                totalBonus += bonus
                nextRoundBonuses[symbolName]!["used"] = true

                let msg = "🔥 \(symbolName)下回合奖励生效: \(bonus > 0 ? "+" : "")\(bonus)金币"
                print(msg)

                if eliminateSelf {
                    // 移除该符号
                    symbolPool.removeAll { $0.name == symbolName }
                    eliminatedSymbolCount += 1
                    let eliminateMsg = "✗ \(symbolName)被消耗，从符号池中移除"
                    print(eliminateMsg)
                }
            }
        }

        // 清除已使用的奖励
        nextRoundBonuses = nextRoundBonuses.filter { (_, data) in
            data["used"] as? Bool ?? false
        }

        return totalBonus
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
            return processConditionalBonus(symbol: symbol, minedSymbols: minedSymbols, symbolPool: symbolPool, logCallback: logCallback)

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
            return processDiceBonus(symbol: symbol, symbolPool: &symbolPool, logCallback: logCallback)

        case "spawn_random_multiple":
            return processSpawnRandomMultiple(symbol: symbol, symbolPool: &symbolPool, logCallback: logCallback)

        // 新增效果类型
        case "global_buff":
            return processGlobalBuff(symbol: symbol, symbolPool: symbolPool, logCallback: logCallback)

        case "cure_negative_effect":
            return processCureNegativeEffect(symbol: symbol, symbolPool: symbolPool, logCallback: logCallback)

        case "protect_symbol":
            return processProtectSymbol(symbol: symbol, symbolPool: symbolPool, logCallback: logCallback)

        case "spawn_specific":
            return processSpawnSpecific(symbol: symbol, symbolPool: &symbolPool, logCallback: logCallback)

        case "conditional_multiplier":
            return processConditionalMultiplier(symbol: symbol, minedSymbols: minedSymbols, logCallback: logCallback)

        case "group_multiplier":
            return processGroupMultiplier(symbol: symbol, minedSymbols: minedSymbols, logCallback: logCallback)

        case "round_start_penalty":
            return processRoundStartPenalty(symbol: symbol, logCallback: logCallback)

        case "eliminate_pair_bonus":
            return processEliminatePairBonus(symbol: symbol, minedSymbols: minedSymbols, symbolPool: &symbolPool, logCallback: logCallback)

        case "round_start_eliminate":
            return processRoundStartEliminate(symbol: symbol, logCallback: logCallback)

        case "next_round_bonus":
            return processNextRoundBonus(symbol: symbol, symbolPool: &symbolPool, logCallback: logCallback)

        case "double_dig_count":
            return processDoubleDigCount(symbol: symbol, symbolPool: &symbolPool, logCallback: logCallback)

        case "double_next_reward":
            return processDoubleNextReward(symbol: symbol, symbolPool: &symbolPool, logCallback: logCallback)

        case "temp_dice_bonus":
            return processTempDiceBonus(symbol: symbol, symbolPool: &symbolPool, logCallback: logCallback)

        case "round_start_buff":
            return processRoundStartBuff(symbol: symbol, logCallback: logCallback)

        case "spawn_random_element":
            return processSpawnRandomElement(symbol: symbol, symbolPool: &symbolPool, logCallback: logCallback)

        case "conditional_self_eliminate":
            return processConditionalSelfEliminate(symbol: symbol, symbolPool: &symbolPool, logCallback: logCallback)

        case "spawn_random_from_list":
            return processSpawnRandomFromList(symbol: symbol, symbolPool: &symbolPool, logCallback: logCallback)

        case "conditional_bonus_eliminate":
            return processConditionalBonusEliminate(symbol: symbol, minedSymbols: minedSymbols, symbolPool: &symbolPool, logCallback: logCallback)

        case "convert_symbol_type":
            return processConvertSymbolType(symbol: symbol, symbolPool: &symbolPool, logCallback: logCallback)

        case "conditional_spawn":
            return processConditionalSpawn(symbol: symbol, minedSymbols: minedSymbols, symbolPool: &symbolPool, logCallback: logCallback)

        default:
            let msg = "   ⚠️ 未知效果类型: \(symbol.effectType)"
            print(msg)
            logCallback?(msg)
            return 0
        }
    }
    
    // MARK: - 效果实现
    
    /// 条件奖励：如果本次挖出或符号池有指定符号，则获得奖励
    private func processConditionalBonus(symbol: Symbol, minedSymbols: [Symbol], symbolPool: [Symbol], logCallback: ((String) -> Void)? = nil) -> Int {
        guard let bonus = symbol.effectParams["bonus"] as? Int else {
            return 0
        }
        
        // 处理特殊条件
        if let condition = symbol.effectParams["condition"] as? String {
            switch condition {
            case "monster_not_eliminated":
                // 修女：如果本次挖出中有怪物，且该怪物没有被其他效果消除
                let hasMonster = minedSymbols.contains { $0.types.contains("monster") }
                if hasMonster {
                    // 这里简化处理：如果本次挖出中有怪物，就给予奖励
                    // 实际的"没有被消除"检查需要在效果处理流程中更复杂地实现
                    let msg = "   ✓ 条件满足：本次挖出中有怪物，获得\(bonus)金币"
                    print(msg)
                    logCallback?(msg)
                    return bonus
                } else {
                    let msg = "   ✗ 条件不满足：本次挖出中没有怪物"
                    print(msg)
                    logCallback?(msg)
                    return 0
                }
                
            case "has_ninja":
                // 手里剑：如果符号池里有女忍者或男忍者
                let hasNinja = symbolPool.contains { $0.name == "女忍者" || $0.name == "男忍者" }
                if hasNinja {
                    let msg = "   ✓ 条件满足：符号池有忍者，获得\(bonus)金币"
                    print(msg)
                    logCallback?(msg)
                    return bonus
                } else {
                    let msg = "   ✗ 条件不满足：符号池没有忍者"
                    print(msg)
                    logCallback?(msg)
                    return 0
                }
                
            default:
                let msg = "   ⚠️ 未知条件类型: \(condition)"
                print(msg)
                logCallback?(msg)
                return 0
            }
        }
        
        // 支持triggerSymbol（本次挖出）或requireSymbol（符号池）
        let triggerSymbol = symbol.effectParams["triggerSymbol"] as? String
        let requireSymbol = symbol.effectParams["requireSymbol"] as? String
        let targetSymbol = triggerSymbol ?? requireSymbol
        
        guard let targetSymbol = targetSymbol else {
            return 0
        }
        
        // 如果使用triggerSymbol，检查本次挖出的符号
        if triggerSymbol != nil {
            let hasTrigger = minedSymbols.contains { $0.name == targetSymbol }
            if hasTrigger {
                let msg = "   ✓ 条件满足：本次挖出中有\(targetSymbol)，获得\(bonus)金币"
                print(msg)
                logCallback?(msg)
                return bonus
            } else {
                let msg = "   ✗ 条件不满足：本次挖出中没有\(targetSymbol)"
                print(msg)
                logCallback?(msg)
                return 0
            }
        } else {
            // 如果使用requireSymbol，检查符号池
            let hasRequired = symbolPool.contains { $0.name == targetSymbol }
            if hasRequired {
                let msg = "   ✓ 条件满足：符号池有\(targetSymbol)，获得\(bonus)金币"
                print(msg)
                logCallback?(msg)
                return bonus
            } else {
                let msg = "   ✗ 条件不满足：符号池没有\(targetSymbol)"
                print(msg)
                logCallback?(msg)
                return 0
            }
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
    private func processDiceBonus(symbol: Symbol, symbolPool: inout [Symbol], logCallback: ((String) -> Void)? = nil) -> Int {
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
        
        // 骰子被挖出后从符号池中移除
        symbolPool.removeAll { $0.name == symbol.name }
        eliminatedSymbolCount += 1
        let eliminateMsg = "   ✗ 骰子被消耗，从符号池中移除"
        print(eliminateMsg)
        logCallback?(eliminateMsg)
        
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

    // MARK: - 新增效果实现

    /// 全局buff：激活全局buff效果
    private func processGlobalBuff(symbol: Symbol, symbolPool: [Symbol], logCallback: ((String) -> Void)? = nil) -> Int {
        guard let buffType = symbol.effectParams["buffType"] as? String,
              let targetSymbols = symbol.effectParams["targetSymbols"] as? [String],
              let isPersistent = symbol.effectParams["isPersistent"] as? Bool else {
            return 0
        }

        let baseValueBonus = symbol.effectParams["baseValueBonus"] as? Int ?? 0
        let multiplier = symbol.effectParams["multiplier"] as? Double ?? 1.0

        applyGlobalBuff(buffType: buffType, targetSymbols: targetSymbols, baseValueBonus: baseValueBonus, multiplier: multiplier)

        let msg = "   🔥 激活全局buff: \(buffType)，目标\(targetSymbols.joined(separator: ","))"
        print(msg)
        logCallback?(msg)

        return 0
    }

    /// 治疗负面效果：抵消怪物负面效果
    private func processCureNegativeEffect(symbol: Symbol, symbolPool: [Symbol], logCallback: ((String) -> Void)? = nil) -> Int {
        guard let targetType = symbol.effectParams["targetType"] as? String else {
            return 0
        }

        // 移除一个指定类型的回合开始惩罚
        if let symbolNameToRemove = roundStartPenalties.first(where: { (_, penaltyData) in
            if let penaltyType = penaltyData["type"] as? String {
                return penaltyType == targetType
            }
            return false
        })?.key {
            roundStartPenalties.removeValue(forKey: symbolNameToRemove)
            let msg = "   💊 抵消负面效果: \(symbolNameToRemove)的\(targetType)负面效果"
            print(msg)
            logCallback?(msg)
        } else {
            let msg = "   ✗ 没有找到可抵消的\(targetType)负面效果"
            print(msg)
            logCallback?(msg)
        }

        return 0
    }

    /// 保护符号：保护特定符号不被消除
    private func processProtectSymbol(symbol: Symbol, symbolPool: [Symbol], logCallback: ((String) -> Void)? = nil) -> Int {
        guard let protectSymbol = symbol.effectParams["protectSymbol"] as? String else {
            return 0
        }

        // 这里只是记录保护状态，实际保护逻辑在消除时检查
        let msg = "   🛡️ 保护状态激活: \(protectSymbol)将被保护"
        print(msg)
        logCallback?(msg)

        return 0
    }

    /// 生成特定符号
    private func processSpawnSpecific(symbol: Symbol, symbolPool: inout [Symbol], logCallback: ((String) -> Void)? = nil) -> Int {
        guard let symbolName = symbol.effectParams["symbol"] as? String else {
            return 0
        }

        let eliminateSelf = symbol.effectParams["eliminateSelf"] as? Bool ?? false

        if let newSymbol = SymbolLibrary.getSymbol(byName: symbolName) {
            symbolPool.append(newSymbol)
            let msg = "   🎁 生成: \(newSymbol.icon) \(newSymbol.name)"
            print(msg)
            logCallback?(msg)

            if eliminateSelf {
                // 消除自身
                symbolPool.removeAll { $0.name == symbol.name }
                eliminatedSymbolCount += 1
                let eliminateMsg = "   ✗ 自身被消耗"
                print(eliminateMsg)
                logCallback?(eliminateMsg)
            }
        }

        return 0
    }

    /// 条件倍率：满足条件时倍率
    private func processConditionalMultiplier(symbol: Symbol, minedSymbols: [Symbol], logCallback: ((String) -> Void)? = nil) -> Int {
        guard let triggerSymbol = symbol.effectParams["triggerSymbol"] as? String,
              let multiplier = symbol.effectParams["multiplier"] as? Int else {
            return 0
        }

        let hasTrigger = minedSymbols.contains { $0.name == triggerSymbol }

        if hasTrigger {
            // 这里应该返回一个标记，让调用方知道要应用倍率
            // 由于架构限制，我们需要在GameViewModel中处理倍率逻辑
            let msg = "   ✨ 条件倍率触发: \(multiplier)倍基础价值"
            print(msg)
            logCallback?(msg)
        }

        return 0 // 倍率逻辑需要在外部处理
    }

    /// 群体倍率：对一组符号应用倍率
    private func processGroupMultiplier(symbol: Symbol, minedSymbols: [Symbol], logCallback: ((String) -> Void)? = nil) -> Int {
        guard let targetType = symbol.effectParams["targetType"] as? String,
              let multiplier = symbol.effectParams["multiplier"] as? Int else {
            return 0
        }

        let affectedCount = minedSymbols.filter { $0.types.contains(targetType) }.count

        if affectedCount > 0 {
            let msg = "   👥 群体倍率: \(affectedCount)个\(targetType)类型符号 \(multiplier)倍价值"
            print(msg)
            logCallback?(msg)
        }

        return 0 // 倍率逻辑需要在外部处理
    }

    /// 回合开始惩罚：注册回合开始惩罚
    private func processRoundStartPenalty(symbol: Symbol, logCallback: ((String) -> Void)? = nil) -> Int {
        guard let penalty = symbol.effectParams["penalty"] as? Int else {
            return 0
        }

        roundStartPenalties[symbol.name] = [
            "penalty": penalty,
            "type": symbol.types.first ?? "unknown"
        ]

        let msg = "   ⚠️ 回合开始惩罚注册: \(penalty)金币/回合"
        print(msg)
        logCallback?(msg)

        return 0
    }

    /// 消除配对奖励：消除两个特定符号
    private func processEliminatePairBonus(symbol: Symbol, minedSymbols: [Symbol], symbolPool: inout [Symbol], logCallback: ((String) -> Void)? = nil) -> Int {
        guard let targetSymbol = symbol.effectParams["targetSymbol"] as? String,
              let bonus = symbol.effectParams["bonus"] as? Int else {
            return 0
        }

        let hasTarget = minedSymbols.contains { $0.name == targetSymbol }

        if hasTarget {
            // 消除目标符号和自身
            var eliminated = false
            symbolPool.removeAll { sym in
                if sym.name == targetSymbol || sym.name == symbol.name {
                    eliminated = true
                    eliminatedSymbolCount += 1
                    return true
                }
                return false
            }

            if eliminated {
                let msg = "   ⚔️ 配对消除: \(targetSymbol)和\(symbol.name)，获得\(bonus)金币"
                print(msg)
                logCallback?(msg)
                return bonus
            }
        }

        return 0
    }

    /// 回合开始消除：注册回合开始消除效果
    private func processRoundStartEliminate(symbol: Symbol, logCallback: ((String) -> Void)? = nil) -> Int {
        guard let requireSymbol = symbol.effectParams["requireSymbol"] as? String,
              let targetSymbols = symbol.effectParams["targetSymbols"] as? [String] else {
            return 0
        }

        roundStartChecks[symbol.name] = [
            "checkType": "eliminate_zombies",
            "requireSymbol": requireSymbol,
            "targetSymbols": targetSymbols
        ]

        let msg = "   🥷 回合开始消除注册: 需要\(requireSymbol)时清除\(targetSymbols.joined(separator: ","))"
        print(msg)
        logCallback?(msg)

        return 0
    }

    /// 下回合奖励：添加下回合奖励
    private func processNextRoundBonus(symbol: Symbol, symbolPool: inout [Symbol], logCallback: ((String) -> Void)? = nil) -> Int {
        guard let bonus = symbol.effectParams["bonus"] as? Int else {
            return 0
        }

        let eliminateSelf = symbol.effectParams["eliminateSelf"] as? Bool ?? false

        addNextRoundBonus(symbolName: symbol.name, bonus: bonus, eliminateSelf: eliminateSelf)

        let msg = "   ⏰ 下回合奖励注册: \(bonus)金币"
        print(msg)
        logCallback?(msg)

        if eliminateSelf {
            symbolPool.removeAll { $0.name == symbol.name }
            eliminatedSymbolCount += 1
            let eliminateMsg = "   ✗ 立即消耗自身"
            print(eliminateMsg)
            logCallback?(eliminateMsg)
        }

        return 0
    }

    /// 双倍挖矿数量：增加挖矿数量
    private func processDoubleDigCount(symbol: Symbol, symbolPool: inout [Symbol], logCallback: ((String) -> Void)? = nil) -> Int {
        let eliminateSelf = symbol.effectParams["eliminateSelf"] as? Bool ?? false

        let msg = "   ⚡ 本次挖矿数量翻倍"
        print(msg)
        logCallback?(msg)

        if eliminateSelf {
            symbolPool.removeAll { $0.name == symbol.name }
            eliminatedSymbolCount += 1
            let eliminateMsg = "   ✗ 消耗自身"
            print(eliminateMsg)
            logCallback?(eliminateMsg)
        }

        return 0 // 挖矿数量翻倍需要在外部处理
    }

    /// 双倍下回合收益：下回合收益翻倍
    private func processDoubleNextReward(symbol: Symbol, symbolPool: inout [Symbol], logCallback: ((String) -> Void)? = nil) -> Int {
        let eliminateSelf = symbol.effectParams["eliminateSelf"] as? Bool ?? false

        // 注册下回合收益翻倍标记
        shouldDoubleNextReward = true
        
        let msg = "   💰 下回合收益翻倍（已注册）"
        print(msg)
        logCallback?(msg)

        if eliminateSelf {
            symbolPool.removeAll { $0.name == symbol.name }
            eliminatedSymbolCount += 1
            let eliminateMsg = "   ✗ 消耗自身"
            print(eliminateMsg)
            logCallback?(eliminateMsg)
        }

        return 0
    }
    
    /// 检查是否应该翻倍下回合收益
    func shouldDoubleReward() -> Bool {
        return shouldDoubleNextReward
    }
    
    /// 清除收益翻倍标记（在应用后调用）
    func clearDoubleRewardFlag() {
        shouldDoubleNextReward = false
    }

    /// 临时骰子奖励：添加临时骰子
    private func processTempDiceBonus(symbol: Symbol, symbolPool: inout [Symbol], logCallback: ((String) -> Void)? = nil) -> Int {
        guard let diceBonus = symbol.effectParams["diceBonus"] as? Int else {
            return 0
        }

        let eliminateSelf = symbol.effectParams["eliminateSelf"] as? Bool ?? false

        addTempDiceBonus(count: diceBonus)

        if eliminateSelf {
            symbolPool.removeAll { $0.name == symbol.name }
            eliminatedSymbolCount += 1
            let eliminateMsg = "   ✗ 消耗自身"
            print(eliminateMsg)
            logCallback?(eliminateMsg)
        }

        return 0
    }

    /// 回合开始buff：注册回合开始buff
    private func processRoundStartBuff(symbol: Symbol, logCallback: ((String) -> Void)? = nil) -> Int {
        guard let rounds = symbol.effectParams["rounds"] as? Int,
              let bonusPerRound = symbol.effectParams["bonusPerRound"] as? Int else {
            let msg = "   ⚠️ 回合开始buff参数错误: rounds=\(symbol.effectParams["rounds"] ?? "nil"), bonusPerRound=\(symbol.effectParams["bonusPerRound"] ?? "nil")"
            print(msg)
            logCallback?(msg)
            return 0
        }

        let gameOverAfter = symbol.effectParams["gameOverAfter"] as? Bool ?? false

        roundStartBuffs[symbol.name] = [
            "rounds": rounds,
            "bonusPerRound": bonusPerRound,
            "currentRound": 0,
            "gameOverAfter": gameOverAfter
        ]

        let msg = "   👑 回合开始buff注册: \(symbol.name) - \(rounds)回合，每回合+\(bonusPerRound)金币\(gameOverAfter ? "，结束后游戏结束" : "")"
        print(msg)
        logCallback?(msg)
        
        print("🔍 [调试] 已注册的回合开始buff: \(roundStartBuffs.keys.joined(separator: ", "))")

        return 0
    }

    /// 生成随机元素
    private func processSpawnRandomElement(symbol: Symbol, symbolPool: inout [Symbol], logCallback: ((String) -> Void)? = nil) -> Int {
        let excludeSelf = symbol.effectParams["excludeSelf"] as? Bool ?? false
        let elementBonus = symbol.effectParams["elementBonus"] as? Int ?? 0

        let elements = ["水元素", "火元素", "雷元素", "冰元素", "土元素"]
        var availableElements = elements

        if excludeSelf {
            // 从当前符号名称推断元素类型并排除
            if symbol.name.hasSuffix("元素") {
                let elementName = symbol.name
                availableElements.removeAll { $0 == elementName }
            }
        }

        if let randomElement = availableElements.randomElement(),
           let newSymbol = SymbolLibrary.getSymbol(byName: randomElement) {
            symbolPool.append(newSymbol)
            let msg = "   🌊 生成随机元素: \(newSymbol.icon) \(newSymbol.name)"
            print(msg)
            logCallback?(msg)
        }

        return 0
    }

    /// 条件自我消除：满足条件时消除自身
    private func processConditionalSelfEliminate(symbol: Symbol, symbolPool: inout [Symbol], logCallback: ((String) -> Void)? = nil) -> Int {
        guard let conditionType = symbol.effectParams["conditionType"] as? String,
              let bonus = symbol.effectParams["bonus"] as? Int else {
            return 0
        }

        var shouldEliminate = false

        switch conditionType {
        case "has_tool":
            shouldEliminate = symbolPool.contains { $0.types.contains("tool") }
        default:
            shouldEliminate = false
        }

        if shouldEliminate {
            if let index = symbolPool.firstIndex(where: { $0.name == symbol.name }) {
                symbolPool.remove(at: index)
                eliminatedSymbolCount += 1
                let msg = "   🗑️ 条件满足，消除自身，获得\(bonus)金币"
                print(msg)
                logCallback?(msg)
                return bonus
            }
        }

        return 0
    }

    /// 从列表随机生成
    private func processSpawnRandomFromList(symbol: Symbol, symbolPool: inout [Symbol], logCallback: ((String) -> Void)? = nil) -> Int {
        guard let symbols = symbol.effectParams["symbols"] as? [String] else {
            return 0
        }

        let eliminateSelf = symbol.effectParams["eliminateSelf"] as? Bool ?? false

        if let randomSymbolName = symbols.randomElement(),
           let newSymbol = SymbolLibrary.getSymbol(byName: randomSymbolName) {
            symbolPool.append(newSymbol)
            let msg = "   🎭 从列表随机生成: \(newSymbol.icon) \(newSymbol.name)"
            print(msg)
            logCallback?(msg)

            if eliminateSelf {
                symbolPool.removeAll { $0.name == symbol.name }
                eliminatedSymbolCount += 1
                let eliminateMsg = "   ✗ 消耗自身"
                print(eliminateMsg)
                logCallback?(eliminateMsg)
            }
        }

        return 0
    }

    /// 条件奖励并消除：条件满足时获得奖励并消除自身
    private func processConditionalBonusEliminate(symbol: Symbol, minedSymbols: [Symbol], symbolPool: inout [Symbol], logCallback: ((String) -> Void)? = nil) -> Int {
        guard let triggerSymbol = symbol.effectParams["triggerSymbol"] as? String,
              let bonus = symbol.effectParams["bonus"] as? Int else {
            return 0
        }

        let hasTrigger = minedSymbols.contains { $0.name == triggerSymbol }

        if hasTrigger {
            // 消除自身
            if let index = symbolPool.firstIndex(where: { $0.name == symbol.name }) {
                symbolPool.remove(at: index)
                eliminatedSymbolCount += 1
                let msg = "   🎁 条件满足，消除自身，获得\(bonus)金币"
                print(msg)
                logCallback?(msg)
                return bonus
            }
        }

        return 0
    }

    /// 转换符号类型：将一个随机符号替换为一个随机的type=material的符号
    private func processConvertSymbolType(symbol: Symbol, symbolPool: inout [Symbol], logCallback: ((String) -> Void)? = nil) -> Int {
        guard let targetType = symbol.effectParams["targetType"] as? String else {
            return 0
        }

        // 找到符号池中非自身的符号
        let availableSymbols = symbolPool.filter { $0.name != symbol.name }
        guard !availableSymbols.isEmpty else {
            let msg = "   ✗ 没有可替换的符号"
            print(msg)
            logCallback?(msg)
            return 0
        }
        
        // 随机选择一个要替换的符号
        let targetSymbol = availableSymbols.randomElement()!
        guard let targetIndex = symbolPool.firstIndex(where: { $0.id == targetSymbol.id }) else {
            return 0
        }
        
        // 从所有type包含targetType的符号中随机选择一个
        let materialSymbols = SymbolLibrary.getSymbols(byType: targetType)
        guard !materialSymbols.isEmpty else {
            let msg = "   ✗ 没有找到type='\(targetType)'的符号"
            print(msg)
            logCallback?(msg)
            return 0
        }
        
        // 使用权重随机选择一个material符号
        let configManager = SymbolConfigManager.shared
        guard let replacementSymbol = configManager.getRandomSymbol(fromPool: materialSymbols) else {
            return 0
        }
        
        // 创建新的符号实例（使用新的UUID，因为这是符号池中的新实例）
        let newSymbol = Symbol(
            id: UUID(),
            nameKey: replacementSymbol.nameKey,
            icon: replacementSymbol.icon,
            baseValue: replacementSymbol.baseValue,
            rarity: replacementSymbol.rarity,
            type: replacementSymbol.type,
            descriptionKey: replacementSymbol.descriptionKey,
            weight: replacementSymbol.weight,
            types: replacementSymbol.types,
            effectType: replacementSymbol.effectType,
            effectParams: replacementSymbol.effectParams
        )
        
        // 替换符号
        let originalSymbol = symbolPool[targetIndex]
        symbolPool[targetIndex] = newSymbol
        
        let msg = "   🔄 类型转换: \(originalSymbol.icon) \(originalSymbol.name) → \(newSymbol.icon) \(newSymbol.name) (type='\(targetType)')"
        print(msg)
        logCallback?(msg)

        return 0
    }

    /// 条件生成：满足条件时生成符号
    private func processConditionalSpawn(symbol: Symbol, minedSymbols: [Symbol], symbolPool: inout [Symbol], logCallback: ((String) -> Void)? = nil) -> Int {
        guard let triggerSymbol = symbol.effectParams["triggerSymbol"] as? String,
              let spawnSymbol = symbol.effectParams["spawnSymbol"] as? String else {
            return 0
        }

        let hasTrigger = minedSymbols.contains { $0.name == triggerSymbol }

        if hasTrigger {
            if let newSymbol = SymbolLibrary.getSymbol(byName: spawnSymbol) {
                symbolPool.append(newSymbol)
                let msg = "   🎁 条件生成: \(newSymbol.icon) \(newSymbol.name)"
                print(msg)
                logCallback?(msg)
            }
        }

        return 0
    }
}

