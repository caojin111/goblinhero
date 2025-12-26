//
//  SymbolEffectProcessor.swift
//  A004
//
//  符号效果处理器 - 处理所有符号的特殊效果
//

import Foundation

class SymbolEffectProcessor {
    // MARK: - 符号名称映射表（nameKey -> 中文名称，用于匹配）
    // 注意：这个映射表用于在代码中通过中文名称查找符号，避免依赖本地化
    private static let symbolNameKeyMap: [String: String] = [
        "儿童": "child",
        "商人": "merchant",
        "野蛮人": "barbarian",
        "农民": "farmer",
        "士兵": "soldier",
        "村长": "village_chief",
        "森林妖精": "forest_fairy",
        "暗月妖精": "dark_moon_fairy",
        "星光妖精": "starlight_fairy",
        "治疗师": "healer",
        "圣骑士": "paladin",
        "修女": "nun",
        "古树长老": "ancient_tree_elder",
        "盗贼": "thief",
        "公主": "princess",
        "吸血鬼": "vampire",
        "猎人": "hunter",
        "女忍者": "female_ninja",
        "男忍者": "male_ninja",
        "力量之神": "god_of_strength",
        "速之神": "god_of_speed",
        "丰收之神": "god_of_harvest",
        "幸运之神": "god_of_luck",
        "死神": "death",
        "水元素": "water_element",
        "火元素": "fire_element",
        "雷元素": "thunder_element",
        "冰元素": "ice_element",
        "土元素": "earth_element",
        "石头": "rock",
        "十字架": "cross",
        "死灵之书": "book_of_the_dead",
        "催眠摆": "hypnosis_pendulum",
        "龙火枪": "dragon_fire_gun",
        "符文护甲": "rune_armor",
        "黎明信使法杖": "dawn_messenger_staff",
        "圣水瓶": "holy_bottle",
        "契约卷轴": "contract_scroll",
        "手里剑": "shuriken",
        "日记": "diary",
        "戒指": "ring",
        "手机": "mobile_phone",
        "眼镜": "glasses",
        "领结": "tie",
        "勾玉": "magatama",
        "电池": "battery",
        "医疗包": "medical_kit",
        "硬币": "coin",
        "枕头": "pillow",
        "眼罩": "eye_mask",
        "符纸": "talisman_paper",
        "南瓜头": "pumpkin_head",
        "雪花": "snowflake",
        "鞭炮": "firecracker",
        "灯笼": "lantern",
        "玩具鸭": "toy_duck",
        "酒瓶": "wine_bottle",
        "公文包": "briefcase",
        "锄头": "hoe",
        "号角": "horn",
        "铁箱子": "iron_box",
        "银箱子": "silver_box",
        "铁钥匙": "iron_key",
        "银钥匙": "silver_key",
        "万能钥匙": "master_key",
        "花精": "flower_fairy",
        "狼人": "werewolf",
        "丧尸": "zombie",
        "独眼怪物": "one_eyed_monster",
        "哥莫拉": "gomorrah",
        "光线枪": "ray_gun",
        "外星头盔": "alien_helmet",
        "宇宙飞船": "spaceship",
        "精神控制器": "mind_controller",
        "流星": "meteorite",
        "骰子": "dice",
        "魔法袋": "magic_bag"
    ]
    
    /// 通过中文名称获取nameKey
    private static func getNameKey(fromChineseName name: String) -> String? {
        return symbolNameKeyMap[name]
    }
    
    /// 通过中文名称或nameKey查找符号
    private func findSymbol(byName name: String, in symbols: [Symbol]) -> Symbol? {
        // 先尝试直接使用nameKey匹配
        if let symbol = symbols.first(where: { $0.nameKey == name }) {
            return symbol
        }
        // 再尝试通过中文名称映射到nameKey
        if let nameKey = SymbolEffectProcessor.getNameKey(fromChineseName: name),
           let symbol = symbols.first(where: { $0.nameKey == nameKey }) {
            return symbol
        }
        // 最后尝试通过本地化名称匹配（向后兼容）
        return symbols.first(where: { $0.name == name })
    }
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
    private var shouldDoubleDigCount: Bool = false // 本次挖矿数量是否翻倍（速之神效果）
    private var extraSymbolChoices: Int = 0 // 额外符号选择次数（如速之神）

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

    func getGlobalBuffMultiplier(for symbolNameKey: String, symbolPool: [Symbol] = []) -> Double {
        var totalMultiplier = 1.0
        for (_, buffData) in globalBuffs {
            if let targetSymbols = buffData["targetSymbols"] as? [String],
               targetSymbols.contains(symbolNameKey),
               let multiplier = buffData["multiplier"] as? Double {
                totalMultiplier *= multiplier
            }
        }
        
        // 注意：正义必胜羁绊效果已改为获得龙之火铳，不再影响猎人权重
        
        return totalMultiplier
    }

    func getGlobalBuffBonus(for symbolNameKey: String) -> Int {
        var totalBonus = 0
        for (_, buffData) in globalBuffs {
            if let targetSymbols = buffData["targetSymbols"] as? [String],
               targetSymbols.contains(symbolNameKey),
               let bonus = buffData["baseValueBonus"] as? Int {
                totalBonus += bonus
            }
        }
        return totalBonus
    }

    /// 移除指定类型的全局buff，防止上一回合遗留
    func removeGlobalBuff(buffType: String) {
        globalBuffs.removeValue(forKey: buffType)
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
        shouldDoubleDigCount = false // 重置挖矿数量翻倍标记
        // 注意：shouldDoubleNextReward 不在回合开始时清除，而是在结算收益时清除
        print("🔄 [效果处理] 回合重置：独眼怪物计数器清空，消除计数器清零，临时奖励清空")
    }
    
    /// 检查是否应该翻倍挖矿数量
    func isDoubleDigCountEnabled() -> Bool {
        return shouldDoubleDigCount
    }
    
    /// 清除挖矿数量翻倍标记（在应用后调用）
    func clearDoubleDigCountFlag() {
        shouldDoubleDigCount = false
    }

    // MARK: - 回合开始处理
    func processRoundStart(symbolPool: inout [Symbol], currentRound: Int = 1) -> Int {
        var totalBonus = 0

        print("\n🌅 [回合开始] 开始处理回合开始效果")
        
        // 处理羁绊Buff效果
        let bondEffectProcessor = BondEffectProcessor()
        let bondResult = bondEffectProcessor.processBondBuffs(symbolPool: &symbolPool, currentRound: currentRound)
        totalBonus += bondResult.bonus
        
        if bondResult.shouldGameOver {
            print("💀 [羁绊Buff] 游戏强制结束")
            // 这里可以设置游戏结束标志，需要在GameViewModel中处理
        }
        print("🔍 [调试] 当前注册的回合开始buff数量: \(roundStartBuffs.count)")
        for (name, data) in roundStartBuffs {
            print("   - \(name): \(data)")
        }

        // 处理回合开始buff（如死神）
        // 注意：roundStartBuffs 的 key 现在是 nameKey，而不是本地化名称
        var buffsToRemove: [String] = []
        for (nameKey, buffData) in roundStartBuffs {
            if let bonusPerRound = buffData["bonusPerRound"] as? Int,
               let rounds = buffData["rounds"] as? Int,
               let buffCurrentRound = buffData["currentRound"] as? Int {

                // 获取符号的本地化名称用于显示
                let symbolName = getAllSymbols().first(where: { $0.nameKey == nameKey })?.name ?? nameKey

                print("🔍 [调试] 处理\(symbolName)(nameKey: \(nameKey))的buff: buff当前回合\(buffCurrentRound)/\(rounds), 游戏当前回合\(currentRound), 每回合奖励\(bonusPerRound)")

                // 使用buff的currentRound来判断，而不是游戏的currentRound
                if buffCurrentRound < rounds {
                    totalBonus += bonusPerRound
                    
                    // 正确更新字典：先获取，修改，再赋值
                    var updatedBuffData = buffData
                    updatedBuffData["currentRound"] = buffCurrentRound + 1
                    roundStartBuffs[nameKey] = updatedBuffData

                    let msg = "💀 \(symbolName)回合开始buff: 获得\(bonusPerRound)金币 (第\(buffCurrentRound + 1)/\(rounds)回合)"
                    print(msg)

                    if buffCurrentRound + 1 >= rounds {
                        // buff结束，检查是否需要结束游戏
                        if buffData["gameOverAfter"] as? Bool ?? false {
                            print("💀 游戏结束！\(symbolName)的\(rounds)回合buff已结束")
                            // 这里可以设置游戏结束标志
                        }
                        buffsToRemove.append(nameKey)
                    }
                } else {
                    print("🔍 [调试] \(symbolName)的buff已结束（\(buffCurrentRound) >= \(rounds)）")
                }
            } else {
                print("⚠️ [调试] \(nameKey)的buff数据格式错误: \(buffData)")
            }
        }
        
        // 移除已结束的buff
        for nameKey in buffsToRemove {
            roundStartBuffs.removeValue(forKey: nameKey)
            let symbolName = getAllSymbols().first(where: { $0.nameKey == nameKey })?.name ?? nameKey
            print("🗑️ [调试] 移除已结束的buff: \(symbolName)")
        }

        // 处理回合开始惩罚（如吸血鬼、狼人）
        // 注意：roundStartPenalties 的 key 现在是 nameKey
        for (nameKey, penaltyData) in roundStartPenalties {
            if let penalty = penaltyData["penalty"] as? Int {
                totalBonus += penalty // 惩罚是负数，所以加到总奖励中
                // 获取本地化名称用于显示
                let symbolName = getAllSymbols().first(where: { $0.nameKey == nameKey })?.name ?? nameKey
                let msg = "🧛 \(symbolName)回合开始惩罚: \(penalty)金币"
                print(msg)
            }
        }

        // 处理回合开始消除（如忍者）
        // 注意：roundStartChecks 的 key 现在是 nameKey
        for (nameKey, eliminateData) in roundStartChecks {
            if let checkType = eliminateData["checkType"] as? String,
               checkType == "eliminate_zombies" {

                if let requireSymbol = eliminateData["requireSymbol"] as? String,
                   let targetSymbols = eliminateData["targetSymbols"] as? [String] {

                    // 检查是否有需要的符号（使用nameKey匹配）
                    let hasRequired = findSymbol(byName: requireSymbol, in: symbolPool) != nil

                    if hasRequired {
                        var eliminatedCount = 0
                        for targetName in targetSymbols {
                            // 使用nameKey匹配
                            if let targetNameKey = SymbolEffectProcessor.getNameKey(fromChineseName: targetName) {
                                let toEliminate = symbolPool.filter { $0.nameKey == targetNameKey }
                            for symbol in toEliminate {
                                    if let index = symbolPool.firstIndex(where: { $0.nameKey == symbol.nameKey }) {
                                    symbolPool.remove(at: index)
                                    eliminatedCount += 1
                                    eliminatedSymbolCount += 1
                                    }
                                }
                            } else {
                                // 向后兼容：尝试通过本地化名称匹配
                                let toEliminate = symbolPool.filter { $0.name == targetName || $0.nameKey == targetName }
                                for symbol in toEliminate {
                                    if let index = symbolPool.firstIndex(where: { $0.nameKey == symbol.nameKey }) {
                                        symbolPool.remove(at: index)
                                        eliminatedCount += 1
                                        eliminatedSymbolCount += 1
                                    }
                                }
                            }
                        }

                        if eliminatedCount > 0 {
                            // 获取本地化名称用于显示
                            let symbolName = getAllSymbols().first(where: { $0.nameKey == nameKey })?.name ?? nameKey
                            let msg = "🥷 \(symbolName)回合开始消除: 清除\(eliminatedCount)个\(targetSymbols.joined(separator: ","))"
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

            // 使用nameKey匹配：花精的nameKey是flower_fairy
            let flowerFairies = symbolPool.filter { $0.nameKey == "flower_fairy" }
            if flowerFairies.count >= 3 {
                // 移除3个花精
                var removedCount = 0
                symbolPool.removeAll { symbol in
                    if symbol.nameKey == "flower_fairy" && removedCount < 3 {
                        removedCount += 1
                        return true
                    }
                    return false
                }

                // 添加一个森林妖精（nameKey: forest_fairy）
                if let forestElf = getAllSymbols().first(where: { $0.nameKey == "forest_fairy" }) {
                    symbolPool.append(forestElf)
                    synthesisPerformed = true
                    let msg = "🧚 花精合成: 3个花精 → 1个森林妖精"
                    print(msg)
                }
            }
        } while synthesisPerformed

        // 处理元素收集检查（要求5种不同的元素，而不是5个元素）
        // 使用nameKey匹配，而不是本地化名称
        let requiredElementKeys = Set(["water_element", "fire_element", "thunder_element", "ice_element", "earth_element"])
        
        // 从符号池中提取所有元素类型的符号nameKey，使用Set去重确保只计算不同的元素类型
        let collectedElementKeys = Set(symbolPool.filter { requiredElementKeys.contains($0.nameKey) }.map { $0.nameKey })
        
        // 检查是否集齐了全部5种不同的元素
        if collectedElementKeys.count == 5 && collectedElementKeys == requiredElementKeys {
            // 收集齐全五种不同元素，获得100金币
            totalBonus += 100
            let msg = "✨ 五元素收集完成（5种不同元素）: 获得100金币"
            print(msg)
        } else {
            // 调试信息：显示当前收集到的元素
            if collectedElementKeys.count > 0 {
                // 将nameKeys转换为本地化名称用于显示
                let collectedElementNames = collectedElementKeys.compactMap { nameKey in
                    getAllSymbols().first(where: { $0.nameKey == nameKey })?.name
                }
                let msg = "🔍 [元素收集] 当前收集到\(collectedElementKeys.count)种元素: \(collectedElementNames.sorted().joined(separator: ", "))"
                print(msg)
            }
        }

        // **新功能：检查是否需要游戏结束（死神的眷顾）**
        var shouldGameOver = false
        for (symbolName, buffData) in roundStartBuffs {
            if let rounds = buffData["rounds"] as? Int,
               let currentRound = buffData["currentRound"] as? Int,
               let gameOverAfter = buffData["gameOverAfter"] as? Bool,
               gameOverAfter && currentRound >= rounds {
                shouldGameOver = true
                print("💀 [游戏结束] \(symbolName)的\(rounds)回合buff已结束，游戏强制结束")
            }
        }

        let summary = "🌅 [回合开始] 总效果: \(totalBonus > 0 ? "+" : "")\(totalBonus) 金币"
        print(summary)
        
        // 如果应该结束游戏，返回一个特殊值或设置标志
        // 注意：实际游戏结束逻辑需要在GameViewModel中处理
        if shouldGameOver {
            // 可以通过返回一个很大的负数或特殊值来标记
            // 或者在这里设置一个标志，让GameViewModel检查
        }

        return totalBonus
    }
    
    /// 检查是否应该结束游戏（用于死神的眷顾）
    func shouldEndGame() -> Bool {
        for (symbolName, buffData) in roundStartBuffs {
            if let rounds = buffData["rounds"] as? Int,
               let currentRound = buffData["currentRound"] as? Int,
               let gameOverAfter = buffData["gameOverAfter"] as? Bool,
               gameOverAfter && currentRound >= rounds {
                return true
            }
        }
        return false
    }

    // MARK: - 临时骰子奖励
    func getTempDiceBonus() -> Int {
        return tempDiceBonus
    }

    func addTempDiceBonus(count: Int) {
        tempDiceBonus += count
        print("🎲 [临时骰子] 获得\(count)个临时骰子，本回合有效")
    }
    
    // MARK: - 额外符号选择
    func addExtraSymbolChoice(count: Int = 1) {
        extraSymbolChoices += count
        print("🎯 [额外选择] 增加 \(count) 次符号选择机会，当前累计：\(extraSymbolChoices)")
    }
    
    func consumeExtraSymbolChoices() -> Int {
        let count = extraSymbolChoices
        extraSymbolChoices = 0
        if count > 0 {
            print("🎯 [额外选择] 消耗额外符号选择次数：\(count)")
        }
        return count
    }

    // MARK: - 下回合奖励
    func addNextRoundBonus(symbolName: String, bonus: Int, eliminateSelf: Bool = false) {
        // 注意：symbolName 可能是本地化名称或nameKey，需要转换为nameKey
        let nameKey: String
        if let key = SymbolEffectProcessor.getNameKey(fromChineseName: symbolName) {
            nameKey = key
        } else {
            // 如果已经是nameKey，直接使用
            nameKey = symbolName
        }
        nextRoundBonuses[nameKey] = [
            "bonus": bonus,
            "eliminateSelf": eliminateSelf,
            "used": false
        ]
    }

    func processNextRoundBonuses(symbolPool: inout [Symbol]) -> Int {
        var totalBonus = 0

        for (nameKey, bonusData) in nextRoundBonuses {
            if let bonus = bonusData["bonus"] as? Int,
               let eliminateSelf = bonusData["eliminateSelf"] as? Bool,
               let used = bonusData["used"] as? Bool,
               !used {

                totalBonus += bonus
                nextRoundBonuses[nameKey]!["used"] = true

                // 获取本地化名称用于显示
                let symbolName = getAllSymbols().first(where: { $0.nameKey == nameKey })?.name ?? nameKey
                let msg = "🔥 \(symbolName)下回合奖励生效: \(bonus > 0 ? "+" : "")\(bonus)金币"
                print(msg)

                if eliminateSelf {
                    // 移除该符号（使用nameKey匹配）
                    symbolPool.removeAll { $0.nameKey == nameKey }
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
        
        print("🔍 [效果处理] processMinedSymbols被调用: enableEffects=\(enableEffects), minedSymbols.count=\(minedSymbols.count)")
        
        guard enableEffects else {
            let msg = "⚠️ 效果已禁用"
            print(msg)
            logCallback?(msg)
            return 0
        }
        
        guard !minedSymbols.isEmpty else {
            print("⚠️ [效果处理] minedSymbols为空，跳过处理")
            return 0
        }
        
        // 调试：打印所有挖出的符号的effectType
        print("🔍 [效果处理] 挖出的符号列表:")
        for symbol in minedSymbols {
            print("   - \(symbol.name) (nameKey: \(symbol.nameKey)): effectType=\(symbol.effectType), effectParams=\(symbol.effectParams)")
        }
        
        let header = "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        let title = "🎯 [效果处理] 开始处理\(minedSymbols.count)个符号的效果"
        let queue = "📋 [挖出队列] \(minedSymbols.map { "\($0.name)(\($0.nameKey))" }.joined(separator: " → "))"
        
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
            let processing = "[\(index + 1)/\(minedSymbols.count)] 🔸 处理: \(symbol.name) (nameKey: \(symbol.nameKey))"
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
        print("🔍 [效果处理] 处理符号: \(symbol.name) (nameKey: \(symbol.nameKey)), effectType: \(symbol.effectType)")
        print("🔍 [效果处理] effectParams: \(symbol.effectParams)")
        
        // 优先处理根据 nameKey 定制的新版本效果（覆盖 CSV 中的旧 effectType）
        if let customResult = processCustomEffectByName(symbol: symbol, minedSymbols: minedSymbols, symbolPool: &symbolPool, logCallback: logCallback) {
            return customResult
        }
        
        // 检查effectType是否为空或无效
        if symbol.effectType.isEmpty {
            print("⚠️ [效果处理] 警告：符号 \(symbol.name) 的 effectType 为空！")
            logCallback?("⚠️ [效果处理] 警告：符号 \(symbol.name) 的 effectType 为空！")
        }
        
        switch symbol.effectType {
        case "none":
            print("   ℹ️ 无效果")
            return 0

        case "conditional_bonus":
            return processConditionalBonus(symbol: symbol, minedSymbols: minedSymbols, symbolPool: symbolPool, logCallback: logCallback)

        case "count_bonus":
            return processCountBonus(symbol: symbol, symbolPool: symbolPool, logCallback: logCallback)

        case "mixed_count_bonus":
            return processMixedCountBonus(symbol: symbol, symbolPool: symbolPool, logCallback: logCallback)

        case "eliminate_bonus":
            return processEliminateBonus(symbol: symbol, minedSymbols: minedSymbols, symbolPool: &symbolPool, logCallback: logCallback)

        case "eliminate_multiple":
            return processEliminateMultiple(symbol: symbol, symbolPool: &symbolPool, logCallback: logCallback)

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

        case "eliminate_trading_symbol_bonus":
            return processEliminateTradingSymbolBonus(symbol: symbol, symbolPool: &symbolPool, logCallback: logCallback)

        case "eliminate_random_human":
            return processEliminateRandomHuman(symbol: symbol, symbolPool: &symbolPool, logCallback: logCallback)

        default:
            let msg = "   ⚠️ 未知效果类型: \(symbol.effectType)"
            print(msg)
            logCallback?(msg)
            return 0
        }
    }
    
    /// 新版符号效果覆盖：依据 nameKey 实现描述中的新逻辑
    private func processCustomEffectByName(symbol: Symbol,
                                           minedSymbols: [Symbol],
                                           symbolPool: inout [Symbol],
                                           logCallback: ((String) -> Void)?) -> Int? {
        switch symbol.nameKey {
        // 基础生成/消除类
        case "child":
            spawnSpecific("nun", symbolPool: &symbolPool, count: 1, logCallback: logCallback)
            logCallback?("   ✓ 儿童：生成修女")
            return 0
        case "merchant":
            // 消除稀有度最高的一个材料符号，基础奖励：基础价值+50
            let materials = symbolPool.enumerated().filter { $0.element.types.contains("material") }
            if let target = materials.max(by: { rarityRank($0.element.rarity) < rarityRank($1.element.rarity) || ($0.element.rarity == $1.element.rarity && $0.element.baseValue < $1.element.baseValue) }) {
                symbolPool.remove(at: target.offset)
                let baseReward = target.element.baseValue + 50
                var reward = baseReward
                
                // 检查奸商羁绊是否激活（商人+硬币+勾玉）
                let bondBuffs = BondBuffConfigManager.shared.getActiveBondBuffs(symbolPool: symbolPool)
                let hasMerchantBond = bondBuffs.contains { $0.nameKey == "merchant_trading_bond" }
                
                if hasMerchantBond {
                    let bondReward = target.element.baseValue * 5
                    reward += bondReward
                    logCallback?("   ✓ 商人：消除材料 \(target.element.name) 稀有度\(target.element.rarity) 基础\(target.element.baseValue) → 基础奖励 \(baseReward) + 羁绊奖励 \(bondReward) = 总奖励 \(reward)")
                } else {
                    logCallback?("   ✓ 商人：消除材料 \(target.element.name) 稀有度\(target.element.rarity) 基础\(target.element.baseValue) → 奖励 \(reward)")
                }
                return reward
            } else {
                logCallback?("   ⚠️ 商人：未找到材料符号，未获得奖励")
                return 0
            }
        case "barbarian":
            let alien = symbolPool.filter { $0.types.contains("alien") }.count
            let monster = symbolPool.filter { $0.types.contains("monster") }.count
            let bonus = (-5 * alien) + (20 * monster)
            logCallback?("   ✓ 野蛮人：alien \(alien) 个，monster \(monster) 个，金币变化 \(bonus)")
            return bonus
        case "farmer":
            spawnRandomByType("tool", count: 5, symbolPool: &symbolPool, logCallback: logCallback)
            logCallback?("   ✓ 农民：生成5个随机#tool")
            return 0
        case "village_chief":
            spawnRandomByType("human", count: 5, symbolPool: &symbolPool, logCallback: logCallback)
            logCallback?("   ✓ 村长：生成5个随机#human +10金币")
            return 10
        case "healer":
            ["holy_bottle", "battery", "medical_kit"].forEach {
                spawnSpecific($0, symbolPool: &symbolPool, count: 1, logCallback: logCallback)
            }
            logCallback?("   ✓ 治疗师：生成圣水瓶/电池/医疗包各1")
            return 0
        case "paladin":
            spawnRandomByType("human", count: 3, symbolPool: &symbolPool, logCallback: logCallback)
            let monsters = symbolPool.enumerated().filter { $0.element.types.contains("monster") }
            let bonus = monsters.count * 100
            // 删除所有怪物
            for idx in monsters.map(\.offset).sorted(by: >) {
                symbolPool.remove(at: idx)
            }
            logCallback?("   ✓ 圣骑士：生成3人类，清除怪物\(monsters.count)个，金币+\(bonus)")
            return bonus
        case "nun":
            spawnSpecific("cross", symbolPool: &symbolPool, count: 1, logCallback: logCallback)
            logCallback?("   ✓ 修女：生成十字架")
            return 0
        case "soldier":
            // 获得一个符文铠甲或外星头盔（随机）
            spawnOneOf(["rune_armor", "alien_helmet"], symbolPool: &symbolPool, logCallback: logCallback)
            logCallback?("   ✓ 士兵：获得一个符文铠甲或外星头盔")
            return 0
        case "thief":
            spawnMissingByType("tool", count: 2, symbolPool: &symbolPool, logCallback: logCallback)
            logCallback?("   ✓ 盗贼：生成2个未拥有的#tool")
            return 0
        case "princess":
            let humans = Set(symbolPool.filter { $0.types.contains("human") }.map { $0.nameKey })
            if humans.count >= 5 {
                spawnSpecific("paladin", symbolPool: &symbolPool, count: 1, logCallback: logCallback)
                logCallback?("   ✓ 公主：人类≥5，生成圣骑士")
            } else {
                logCallback?("   ✗ 公主：人类不足5，不触发")
            }
            return 0
        case "vampire":
            let humans = symbolPool.enumerated().filter { $0.element.types.contains("human") }
            let removeCount = min(5, humans.count)
            humans.map(\.offset).sorted(by: >).prefix(removeCount).forEach { symbolPool.remove(at: $0) }
            spawnRandomByType("material", count: 10, symbolPool: &symbolPool, logCallback: logCallback)
            logCallback?("   ✓ 吸血鬼：消除\(removeCount)人类，生成10个材料")
            return 0
        case "hunter":
            // 检查本次挖出的符号中是否有吸血鬼
            let hasVampire = minedSymbols.contains { $0.nameKey == "vampire" }
            if hasVampire {
                spawnRandomByType("equipment", count: 2, symbolPool: &symbolPool, logCallback: logCallback)
                // 消除符号池中的吸血鬼和自身
                symbolPool.removeAll { $0.nameKey == "vampire" || $0.id == symbol.id }
                logCallback?("   ✓ 猎人：本次挖出中有吸血鬼，生成2装备，消除吸血鬼与自身，金币+200")
                return 200
            } else {
                logCallback?("   ✗ 猎人：本次挖出中没有吸血鬼，效果不触发")
                return 0
            }
        case "pumpkin_head":
            spawnSpecific("child", symbolPool: &symbolPool, count: 1, logCallback: logCallback)
            return 0
        case "snowflake":
            spawnSpecific("farmer", symbolPool: &symbolPool, count: 1, logCallback: logCallback)
            return 0
        case "firecracker":
            spawnSpecific("horn", symbolPool: &symbolPool, count: 1, logCallback: logCallback)
            return 0
        case "lantern":
            spawnSpecific("merchant", symbolPool: &symbolPool, count: 1, logCallback: logCallback)
            return 0
        case "toy_duck":
            spawnRandomByType("tool", count: 1, symbolPool: &symbolPool, logCallback: logCallback)
            return 0
        case "wine_bottle":
            spawnSpecific("barbarian", symbolPool: &symbolPool, count: 1, logCallback: logCallback)
            return 0
        case "briefcase":
            spawnSpecific("village_chief", symbolPool: &symbolPool, count: 1, logCallback: logCallback)
            return 0
        case "magatama":
            // 只对 normal（common）稀有度的符号应用基础价值+5
            let normalSymbols = SymbolLibrary.getSymbols(byRarity: .common)
            let normalNameKeys = normalSymbols.map { $0.nameKey }
            applyGlobalBuff(buffType: "base_value_bonus_normal", targetSymbols: normalNameKeys, baseValueBonus: 5, multiplier: nil)
            logCallback?("   ✓ 勾玉：所有普通稀有度符号基础价值+5")
            return 0
        // 装备/材料类
        case "dragon_fire_gun":
            let monsters = symbolPool.enumerated().filter { $0.element.types.contains("monster") }
            if let target = monsters.randomElement() {
                symbolPool.remove(at: target.offset)
                logCallback?("   ✓ 龙火枪：消灭怪物 \(target.element.name)")
            } else {
                logCallback?("   ⚠️ 龙火枪：无怪物可消灭")
            }
            return 50
        case "rune_armor":
            spawnRandomByType("classic tale", count: 2, symbolPool: &symbolPool, logCallback: logCallback)
            return 0
        case "dawn_messenger_staff":
            spawnSpecific("princess", symbolPool: &symbolPool, count: 1, logCallback: logCallback)
            return 0
        case "holy_bottle":
            spawnSpecific("dice", symbolPool: &symbolPool, count: 1, logCallback: logCallback)
            return 0
        case "ring", "mobile_phone", "glasses", "tie":
            spawnRandomByType("cozy life", count: 1, symbolPool: &symbolPool, logCallback: logCallback)
            return 0
        case "coin":
            // 自消
            if let idx = symbolPool.firstIndex(where: { $0.id == symbol.id }) {
                symbolPool.remove(at: idx)
            }
            spawnRandomByType("material", count: 2, symbolPool: &symbolPool, logCallback: logCallback)
            return 0
        case "pillow", "eye_mask":
            // 消除两个非 cozy life
            let targets = symbolPool.enumerated().filter { !$0.element.types.contains("cozy life") }.prefix(2)
            for idx in targets.map(\.offset).sorted(by: >) { symbolPool.remove(at: idx) }
            logCallback?("   ✓ \(symbol.name)：消除非cozy life \(targets.count) 个")
            return 0
        case "medical_kit":
            spawnSpecific("healer", symbolPool: &symbolPool, count: 1, logCallback: logCallback)
            return 0
        case "shuriken":
            let hasNinja = symbolPool.contains { $0.nameKey == "female_ninja" || $0.nameKey == "male_ninja" }
            return hasNinja ? 30 : 0
        case "diary":
            if let idx = symbolPool.firstIndex(where: { $0.id == symbol.id }) {
                symbolPool.remove(at: idx)
            }
            spawnSpecific("vampire", symbolPool: &symbolPool, count: 1, logCallback: logCallback)
            return 0
        case "talisman_paper":
            // 消除狼人和自身
            symbolPool.removeAll { $0.nameKey == "werewolf" || $0.id == symbol.id }
            return 100
        // 神/怪物等
        case "god_of_speed":
            // 额外符号选择
            addExtraSymbolChoice(count: 1)
            if let idx = symbolPool.firstIndex(where: { $0.id == symbol.id }) { symbolPool.remove(at: idx) }
            logCallback?("   ✓ 速之神：额外一次符号选择")
            return 0
        case "death":
            // 消除符号池一半
            let half = symbolPool.count / 2
            if half > 0 {
                for _ in 0..<half { symbolPool.removeFirst() }
            }
            logCallback?("   ✓ 死神：消除一半符号 \(half) 个")
            return 0
        case "ray_gun", "alien_helmet", "spaceship":
            spawnRandomByType("alien", count: 1, symbolPool: &symbolPool, logCallback: logCallback)
            return 0
        case "mind_controller":
            if let idx = symbolPool.indices.randomElement() {
                // 将随机符号替换为一个随机#monster符号
                let monsters = SymbolLibrary.getSymbols(byType: "monster")
                if let newSym = monsters.randomElement() {
                    symbolPool[idx] = newSym
                    logCallback?("   ✓ 精神控制器：将符号转化为 \(newSym.name)")
                }
            }
            return 0
        case "flower_fairy":
            let flowers = symbolPool.enumerated().filter { $0.element.nameKey == "flower_fairy" }
            let removeCount = min(3, flowers.count)
            flowers.map(\.offset).sorted(by: >).prefix(removeCount).forEach { symbolPool.remove(at: $0) }
            if removeCount == 3 { spawnSpecific("forest_fairy", symbolPool: &symbolPool, count: 1, logCallback: logCallback) }
            return 0
        case "werewolf":
            let humans = symbolPool.enumerated().filter { $0.element.types.contains("human") }
            let removeCount = min(2, humans.count)
            humans.map(\.offset).sorted(by: >).prefix(removeCount).forEach { symbolPool.remove(at: $0) }
            spawnRandomByType("tool", count: 10, symbolPool: &symbolPool, logCallback: logCallback)
            logCallback?("   ✓ 狼人：消除人类\(removeCount)，生成10个tool")
            return 0
        case "gomorrah":
            if let idx = symbolPool.indices.randomElement() {
                symbolPool.remove(at: idx)
                logCallback?("   ✓ 哥莫拉：随机消除1符号")
            }
            return 50
        case "god_of_luck":
            if let idx = symbolPool.firstIndex(where: { $0.id == symbol.id }) { symbolPool.remove(at: idx) }
            tempDiceBonus += 1
            logCallback?("   ✓ 幸运之神：本回合临时+1骰子")
            return 0
        case "god_of_strength":
            // 力之神效果：下回合奖励+300，被挖出后从符号池移除
            // 直接调用 processNextRoundBonus 确保效果生效
            print("🔍 [力之神] 检测到力之神符号，effectType=\(symbol.effectType), effectParams=\(symbol.effectParams)")
            return processNextRoundBonus(symbol: symbol, symbolPool: &symbolPool, logCallback: logCallback)
        case "artwork":
            spawnSpecific("merchant", symbolPool: &symbolPool, count: 5, logCallback: logCallback)
            logCallback?("   ✓ 艺术品：生成5个商人")
            return 0
        default:
            return nil
        }
    }
    
    // 稀有度比较辅助
    private func rarityRank(_ rarity: SymbolRarity) -> Int {
        switch rarity {
        case .common: return 1
        case .rare: return 2
        case .epic: return 3
        case .legendary: return 4
        }
    }
    
    // MARK: - 辅助生成/消除
    private func spawnSpecific(_ nameKey: String, symbolPool: inout [Symbol], count: Int, logCallback: ((String) -> Void)?) {
        // 支持中文名称映射到nameKey
        let resolvedKey = SymbolEffectProcessor.getNameKey(fromChineseName: nameKey) ?? nameKey
        for _ in 0..<count {
            if let sym = SymbolLibrary.getSymbol(byName: resolvedKey) {
                symbolPool.append(sym)
            }
        }
    }
    
    private func spawnRandomByType(_ type: String, count: Int, symbolPool: inout [Symbol], logCallback: ((String) -> Void)?) {
        let candidates = SymbolLibrary.getSymbols(byType: type)
        guard !candidates.isEmpty else { return }
        for _ in 0..<count {
            if let sym = candidates.randomElement() {
                symbolPool.append(sym)
            }
        }
    }
    
    private func spawnOneOf(_ nameKeys: [String], symbolPool: inout [Symbol], logCallback: ((String) -> Void)?) {
        if let pick = nameKeys.randomElement(), let sym = SymbolLibrary.getSymbol(byName: pick) {
            symbolPool.append(sym)
            let msg = "   🎁 生成: \(sym.icon) \(sym.name)"
            print(msg)
            logCallback?(msg)
        }
    }
    
    private func spawnMissingByType(_ type: String, count: Int, symbolPool: inout [Symbol], logCallback: ((String) -> Void)?) {
        let owned = Set(symbolPool.map { $0.nameKey })
        let candidates = SymbolLibrary.getSymbols(byType: type).filter { !owned.contains($0.nameKey) }
        for sym in candidates.prefix(count) {
            symbolPool.append(sym)
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
                // 手里剑：如果符号池里有女忍者或男忍者（使用nameKey匹配）
                let hasNinja = symbolPool.contains { $0.nameKey == "female_ninja" || $0.nameKey == "male_ninja" }
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
        
        // 如果使用triggerSymbol，检查本次挖出的符号（使用nameKey匹配）
        if triggerSymbol != nil {
            let hasTrigger = findSymbol(byName: targetSymbol, in: minedSymbols) != nil
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
            // 如果使用requireSymbol，检查符号池（使用nameKey匹配）
            let hasRequired = findSymbol(byName: targetSymbol, in: symbolPool) != nil
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
        
        // 支持nameFilter：如果指定了nameFilter，只统计特定名称的符号
        let nameFilter = symbol.effectParams["nameFilter"] as? String
        let excludeSelf = symbol.effectParams["excludeSelf"] as? Bool ?? false
        
        let filteredSymbols: [Symbol]
        if let nameFilter = nameFilter {
            // 使用nameFilter：只统计特定名称的符号（使用nameKey匹配）
            if let nameKey = SymbolEffectProcessor.getNameKey(fromChineseName: nameFilter) {
                filteredSymbols = symbolPool.filter { $0.nameKey == nameKey }
            } else {
                // 向后兼容：尝试通过本地化名称匹配
                filteredSymbols = symbolPool.filter { $0.name == nameFilter }
            }
        } else {
            // 使用countType：统计类型
            filteredSymbols = symbolPool.filter { $0.types.contains(countType) }
        }
        
        // 如果excludeSelf为true，排除自身
        let count = excludeSelf ? filteredSymbols.filter { $0.name != symbol.name }.count : filteredSymbols.count
        let bonus = count * bonusPerCount
        
        if count > 0 {
            let filterDesc = nameFilter != nil ? nameFilter! : countType
            let msg = "   ✓ 符号池有\(count)个\(filterDesc)，获得\(bonus)金币"
            print(msg)
            logCallback?(msg)
        } else {
            let filterDesc = nameFilter != nil ? nameFilter! : countType
            let msg = "   ✗ 符号池没有\(filterDesc)"
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
            // 使用nameKey匹配
            if let index = symbolPool.firstIndex(where: { $0.nameKey == targetSymbol.nameKey }) {
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
    
    /// 消除多个：消除符号池中所有指定名称的符号并获得奖励
    private func processEliminateMultiple(symbol: Symbol, symbolPool: inout [Symbol], logCallback: ((String) -> Void)? = nil) -> Int {
        guard let targetSymbols = symbol.effectParams["targetSymbols"] as? [String],
              let bonus = symbol.effectParams["bonus"] as? Int else {
            return 0
        }
        
        var eliminatedCount = 0
        var totalBonus = 0
        
        // 消除所有匹配的符号（使用nameKey匹配）
        for targetName in targetSymbols {
            let beforeCount = symbolPool.count
            // 先找到目标符号的nameKey
            if let targetNameKey = SymbolEffectProcessor.getNameKey(fromChineseName: targetName) {
                symbolPool.removeAll { $0.nameKey == targetNameKey }
            } else {
                // 向后兼容：尝试通过本地化名称匹配
                symbolPool.removeAll { $0.name == targetName }
            }
            let afterCount = symbolPool.count
            let count = beforeCount - afterCount
            
            if count > 0 {
                eliminatedCount += count
                eliminatedSymbolCount += count
                let msg = "   🗑️ 消除\(count)个: \(targetName)"
                print(msg)
                logCallback?(msg)
            }
        }
        
        // 计算总奖励（每个符号获得bonus，或者总共获得bonus）
        // 根据CSV描述，应该是总共获得bonus，而不是每个符号bonus
        if eliminatedCount > 0 {
            totalBonus = bonus
            let msg = "   ✓ 消除\(eliminatedCount)个符号，获得\(totalBonus)金币"
            print(msg)
            logCallback?(msg)
        } else {
            let msg = "   ✗ 符号池没有可消除的符号: \(targetSymbols.joined(separator: ", "))"
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
        
        // 使用nameKey匹配
        let hasTrigger = findSymbol(byName: triggerSymbol, in: symbolPool) != nil
        
        if hasTrigger {
            // 从符号池移除自己（使用nameKey匹配）
            if let index = symbolPool.firstIndex(where: { $0.nameKey == symbol.nameKey }) {
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
        
        // 检查符号池是否有目标符号（使用nameKey匹配）
        // 注意：这个效果需要先检查条件（如符号池里有"哥莫拉"），然后消除目标
        // 这里简化处理：直接检查并消除目标符号
        if let targetSymbolObj = findSymbol(byName: targetSymbol, in: symbolPool),
           let index = symbolPool.firstIndex(where: { $0.nameKey == targetSymbolObj.nameKey }) {
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
                // 生成符号（支持中文名称，先转换为nameKey）
                let resolvedNameKey = SymbolEffectProcessor.getNameKey(fromChineseName: symbolName) ?? symbolName
                if let newSymbol = SymbolLibrary.getSymbol(byName: resolvedNameKey) {
                    symbolPool.append(newSymbol)
                    let msg = "   🎲 随机生成: \(newSymbol.icon) \(newSymbol.name) (概率\(Int(probability * 100))%)"
                    print(msg)
                    logCallback?(msg)
                } else {
                    let errorMsg = "   ✗ 随机生成失败: 无法找到符号 '\(symbolName)' (解析为: \(resolvedNameKey))"
                    print(errorMsg)
                    logCallback?(errorMsg)
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
        
        // 支持中文名称，先转换为nameKey
        let resolvedNameKey = SymbolEffectProcessor.getNameKey(fromChineseName: symbolName) ?? symbolName
        if let newSymbol = SymbolLibrary.getSymbol(byName: resolvedNameKey) {
            for _ in 0..<count {
                symbolPool.append(newSymbol)
            }
            let msg = "   🎁 生成\(count)个: \(newSymbol.icon) \(newSymbol.name)"
            print(msg)
            logCallback?(msg)
        } else {
            let errorMsg = "   ✗ 批量生成失败: 无法找到符号 '\(symbolName)' (解析为: \(resolvedNameKey))"
            print(errorMsg)
            logCallback?(errorMsg)
        }
        
        return 0
    }
    
    /// 解锁奖励：消除指定符号并获得奖励
    private func processUnlockBonus(symbol: Symbol, symbolPool: inout [Symbol], logCallback: ((String) -> Void)? = nil) -> Int {
        guard let unlockSymbol = symbol.effectParams["unlockSymbol"] as? String,
              let bonus = symbol.effectParams["bonus"] as? Int else {
            return 0
        }
        
        // 使用nameKey匹配
        if let unlockSymbolObj = findSymbol(byName: unlockSymbol, in: symbolPool),
           let index = symbolPool.firstIndex(where: { $0.nameKey == unlockSymbolObj.nameKey }) {
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
           let index = symbolPool.firstIndex(where: { $0.nameKey == bestBox.nameKey }) {
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
        
        // 计算丧尸数量奖励（使用nameKey匹配）
        let zombieCount = symbolPool.filter { symbol in
            if let nameKey = SymbolEffectProcessor.getNameKey(fromChineseName: countType) {
                return symbol.nameKey == nameKey
            }
            return symbol.name == countType || symbol.nameKey == countType
        }.count
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
           let index = symbolPool.firstIndex(where: { $0.nameKey == randomSymbol.nameKey }) {
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
        
        // 支持onceOnly：如果为true，只计算一次（需要检查是否已经计算过）
        let onceOnly = symbol.effectParams["onceOnly"] as? Bool ?? false
        
        // 检查本次挖出是否有所有组合符号（使用nameKey匹配）
        let hasAllCombo = comboSymbols.allSatisfy { targetName in
            findSymbol(byName: targetName, in: minedSymbols) != nil
        }
        
        // 如果onceOnly为true，需要检查是否已经计算过（这里简化处理，实际应该用状态追踪）
        // 注意：onceOnly的效果应该在本次挖出中只触发一次，如果多个符号都有这个效果，只计算一次
        if hasAllCombo {
            let msg = "   ✨ 组合成功！与\(comboSymbols.joined(separator: "、"))同时挖出，获得\(bonus)金币\(onceOnly ? "（仅计算一次）" : "")"
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
        
        // 骰子被挖出后从符号池中移除（使用nameKey匹配，确保正确移除）
        let beforeCount = symbolPool.count
        print("🎲 [骰子消除] 移除前符号池数量: \(beforeCount), 查找nameKey: \(symbol.nameKey)")
        print("🎲 [骰子消除] 符号池中的骰子符号: \(symbolPool.filter { $0.nameKey == symbol.nameKey }.map { "\($0.name)(\($0.nameKey))" })")
        
        symbolPool.removeAll { $0.nameKey == symbol.nameKey }
        let afterCount = symbolPool.count
        let removedCount = beforeCount - afterCount
        
        if removedCount > 0 {
            eliminatedSymbolCount += removedCount
            let eliminateMsg = "   ✗ 骰子被消耗，从符号池中移除了\(removedCount)个骰子符号"
        print(eliminateMsg)
        logCallback?(eliminateMsg)
        } else {
            let warningMsg = "   ⚠️ 警告：未能从符号池中找到并移除骰子符号（nameKey: \(symbol.nameKey), 符号池数量: \(beforeCount)）"
            print(warningMsg)
            logCallback?(warningMsg)
            // 打印符号池中所有符号的nameKey用于调试
            print("🎲 [调试] 符号池中所有符号的nameKey: \(symbolPool.map { $0.nameKey })")
        }
        
        return 0
    }
    
    /// 随机数量生成（魔法袋：消除自身，随机生成3~5个随机符号到符号池）
    private func processSpawnRandomMultiple(symbol: Symbol, symbolPool: inout [Symbol], logCallback: ((String) -> Void)? = nil) -> Int {
        guard let minCount = symbol.effectParams["minCount"] as? Int,
              let maxCount = symbol.effectParams["maxCount"] as? Int else {
            return 0
        }

        // 消除自身（魔法袋）
        if let index = symbolPool.firstIndex(where: { $0.id == symbol.id }) {
            symbolPool.remove(at: index)
            eliminatedSymbolCount += 1
            let eliminateMsg = "   ✗ \(symbol.name)被消耗，从符号池中移除"
            print(eliminateMsg)
            logCallback?(eliminateMsg)
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
        guard let buffType = symbol.effectParams["buffType"] as? String else {
            return 0
        }
        
        // 支持不同类型的全局buff
        if buffType == "weight_multiplier" {
            // 权重倍数buff（如十字架的猎人权重翻倍）
            guard let targetSymbol = symbol.effectParams["targetSymbol"] as? String,
                  let multiplier = symbol.effectParams["multiplier"] as? Double else {
                return 0
            }
            
            // 权重倍数buff已经在SymbolConfigManager.getRandomSymbol中处理
            // 这里只需要记录日志
            let msg = "   ⚖️ 激活权重倍数buff: \(targetSymbol)权重×\(multiplier)"
            print(msg)
            logCallback?(msg)
            return 0
        } else {
            // 其他类型的全局buff（如基础价值加成）
            guard let targetSymbols = symbol.effectParams["targetSymbols"] as? [String],
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
            print("⚠️ [效果处理] spawn_specific: 未找到symbol参数")
            return 0
        }

        let eliminateSelf = symbol.effectParams["eliminateSelf"] as? Bool ?? false

        // 先尝试通过中文名称查找，如果失败则尝试通过nameKey映射
        var newSymbol: Symbol?
        if let foundSymbol = SymbolLibrary.getSymbol(byName: symbolName) {
            newSymbol = foundSymbol
        } else if let nameKey = SymbolEffectProcessor.getNameKey(fromChineseName: symbolName),
                  let foundSymbol = SymbolLibrary.getSymbol(byName: nameKey) {
            newSymbol = foundSymbol
            print("🔍 [效果处理] 通过中文名称映射找到符号: \(symbolName) -> \(nameKey)")
        } else {
            print("❌ [效果处理] spawn_specific: 无法找到符号 '\(symbolName)'")
            logCallback?("   ❌ 无法生成符号: \(symbolName)")
            return 0
        }

        if let newSymbol = newSymbol {
            symbolPool.append(newSymbol)
            let msg = "   🎁 生成: \(newSymbol.icon) \(newSymbol.name)"
            print(msg)
            logCallback?(msg)

            if eliminateSelf {
                // 消除自身
                // 使用nameKey匹配
            symbolPool.removeAll { $0.nameKey == symbol.nameKey }
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

        // 使用nameKey匹配
        let hasTrigger = findSymbol(byName: triggerSymbol, in: minedSymbols) != nil

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

        // 使用nameKey作为key，而不是本地化名称
        roundStartPenalties[symbol.nameKey] = [
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

        // 使用nameKey匹配
        let targetSymbolObj = findSymbol(byName: targetSymbol, in: minedSymbols)
        let hasTarget = targetSymbolObj != nil

        if hasTarget {
            // 消除目标符号和自身（使用nameKey匹配）
            var eliminated = false
            symbolPool.removeAll { sym in
                if let targetObj = targetSymbolObj, (sym.nameKey == targetObj.nameKey || sym.nameKey == symbol.nameKey) {
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

        // 使用nameKey作为key，而不是本地化名称
        roundStartChecks[symbol.nameKey] = [
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

        // 使用nameKey而不是本地化名称
        addNextRoundBonus(symbolName: symbol.nameKey, bonus: bonus, eliminateSelf: eliminateSelf)

        let msg = "   ⏰ 下回合奖励注册: \(bonus)金币"
        print(msg)
        logCallback?(msg)

        if eliminateSelf {
            // 使用nameKey匹配
            symbolPool.removeAll { $0.nameKey == symbol.nameKey }
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

        // **重要：如果标记已经存在，说明之前已经设置过，不应该重复设置**
        if shouldDoubleDigCount {
            let msg = "   ⚠️ 速之神效果标记已存在，跳过重复设置（确保只生效一次）"
        print(msg)
        logCallback?(msg)
        } else {
            // 设置挖矿数量翻倍标记（只设置一次）
            shouldDoubleDigCount = true
            let msg = "   ⚡ 本次挖矿数量翻倍（速之神效果）- 标记已设置，将在下次掷骰子时生效"
            print(msg)
            logCallback?(msg)
        }

        if eliminateSelf {
            // 使用nameKey匹配
            symbolPool.removeAll { $0.nameKey == symbol.nameKey }
            eliminatedSymbolCount += 1
            let eliminateMsg = "   ✗ 消耗自身"
            print(eliminateMsg)
            logCallback?(eliminateMsg)
        }

        return 0 // 挖矿数量翻倍在GameViewModel中处理
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
            // 使用nameKey匹配
            symbolPool.removeAll { $0.nameKey == symbol.nameKey }
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
            // 使用nameKey匹配
            symbolPool.removeAll { $0.nameKey == symbol.nameKey }
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

        // 使用nameKey作为key，而不是本地化名称
        roundStartBuffs[symbol.nameKey] = [
            "rounds": rounds,
            "bonusPerRound": bonusPerRound,
            "currentRound": 0,
            "gameOverAfter": gameOverAfter
        ]

        let msg = "   👑 回合开始buff注册: \(symbol.name) (nameKey: \(symbol.nameKey)) - \(rounds)回合，每回合+\(bonusPerRound)金币\(gameOverAfter ? "，结束后游戏结束" : "")"
        print(msg)
        logCallback?(msg)
        
        print("🔍 [调试] 已注册的回合开始buff: \(roundStartBuffs.keys.joined(separator: ", "))")

        return 0
    }

    /// 生成随机元素
    private func processSpawnRandomElement(symbol: Symbol, symbolPool: inout [Symbol], logCallback: ((String) -> Void)? = nil) -> Int {
        let excludeSelf = symbol.effectParams["excludeSelf"] as? Bool ?? false

        // 使用nameKey而不是本地化名称
        let elementNameKeys = ["water_element", "fire_element", "thunder_element", "ice_element", "earth_element"]
        var availableElementKeys = elementNameKeys

        if excludeSelf {
            // 排除自身（使用nameKey匹配）
            availableElementKeys.removeAll { $0 == symbol.nameKey }
        }

        if let randomElementKey = availableElementKeys.randomElement(),
           let newSymbol = SymbolLibrary.getSymbol(byName: randomElementKey) ?? getAllSymbols().first(where: { $0.nameKey == randomElementKey }) {
            symbolPool.append(newSymbol)
            let msg = "   🌊 生成随机元素: \(newSymbol.name) (nameKey: \(newSymbol.nameKey))"
            print(msg)
            logCallback?(msg)
        } else {
            let msg = "   ⚠️ 无法生成随机元素（可用元素: \(availableElementKeys.joined(separator: ", "))）"
            print(msg)
            logCallback?(msg)
        }

        return 0
    }
    
    /// 辅助方法：获取所有符号（用于内部查找）
    private func getAllSymbols() -> [Symbol] {
        return SymbolLibrary.allSymbols
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
            // 使用nameKey匹配
            if let index = symbolPool.firstIndex(where: { $0.nameKey == symbol.nameKey }) {
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
            print("⚠️ [效果处理] spawn_random_from_list: 未找到symbols参数")
            logCallback?("   ❌ 无法生成符号：缺少symbols参数")
            return 0
        }

        let eliminateSelf = symbol.effectParams["eliminateSelf"] as? Bool ?? false

        print("🔍 [效果处理] spawn_random_from_list: 符号列表: \(symbols), eliminateSelf: \(eliminateSelf)")

        // 使用nameKey匹配
        if let randomSymbolName = symbols.randomElement() {
            print("🔍 [效果处理] 随机选择符号名称: \(randomSymbolName)")
            
            let newSymbol: Symbol?
            if let nameKey = SymbolEffectProcessor.getNameKey(fromChineseName: randomSymbolName) {
                print("🔍 [效果处理] 通过中文名称映射找到nameKey: \(randomSymbolName) -> \(nameKey)")
                newSymbol = getAllSymbols().first(where: { $0.nameKey == nameKey })
            } else {
                print("🔍 [效果处理] 尝试直接通过名称查找: \(randomSymbolName)")
                newSymbol = SymbolLibrary.getSymbol(byName: randomSymbolName)
            }
            
            if let newSymbol = newSymbol {
                symbolPool.append(newSymbol)
                let msg = "   🎭 从列表随机生成: \(newSymbol.name) (nameKey: \(newSymbol.nameKey))"
                print(msg)
                logCallback?(msg)

                if eliminateSelf {
                    // 使用nameKey匹配
                    let beforeCount = symbolPool.count
                    symbolPool.removeAll { $0.nameKey == symbol.nameKey }
                    let afterCount = symbolPool.count
                    eliminatedSymbolCount += 1
                    let eliminateMsg = "   ✗ 消耗自身 (移除前: \(beforeCount), 移除后: \(afterCount))"
                    print(eliminateMsg)
                    logCallback?(eliminateMsg)
                }
            } else {
                print("❌ [效果处理] spawn_random_from_list: 无法找到符号 '\(randomSymbolName)'")
                logCallback?("   ❌ 无法生成符号: \(randomSymbolName)")
            }
        } else {
            print("⚠️ [效果处理] spawn_random_from_list: symbols列表为空")
            logCallback?("   ❌ 符号列表为空")
        }

        return 0
    }

    /// 条件奖励并消除：条件满足时获得奖励并消除自身
    private func processConditionalBonusEliminate(symbol: Symbol, minedSymbols: [Symbol], symbolPool: inout [Symbol], logCallback: ((String) -> Void)? = nil) -> Int {
        guard let triggerSymbol = symbol.effectParams["triggerSymbol"] as? String,
              let bonus = symbol.effectParams["bonus"] as? Int else {
            return 0
        }

        // 使用nameKey匹配
        let hasTrigger = findSymbol(byName: triggerSymbol, in: minedSymbols) != nil

        if hasTrigger {
            // 消除自身
            // 使用nameKey匹配
            if let index = symbolPool.firstIndex(where: { $0.nameKey == symbol.nameKey }) {
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

        // 使用nameKey匹配
        let hasTrigger = findSymbol(byName: triggerSymbol, in: minedSymbols) != nil
        let eliminateSelf = symbol.effectParams["eliminateSelf"] as? Bool ?? false
        let allowFallback = symbol.effectParams["allowFallback"] as? Bool ?? false

        if hasTrigger {
            // 尝试生成指定符号（使用nameKey匹配）
            let newSymbol: Symbol?
            if let nameKey = SymbolEffectProcessor.getNameKey(fromChineseName: spawnSymbol) {
                newSymbol = getAllSymbols().first(where: { $0.nameKey == nameKey })
            } else {
                newSymbol = SymbolLibrary.getSymbol(byName: spawnSymbol)
            }
            
            if let newSymbol = newSymbol {
                symbolPool.append(newSymbol)
                let msg = "   🎁 条件生成: \(newSymbol.icon) \(newSymbol.name)"
                print(msg)
                logCallback?(msg)
                
                if eliminateSelf {
                    // 消除自身
                    // 使用nameKey匹配
            symbolPool.removeAll { $0.nameKey == symbol.nameKey }
                    eliminatedSymbolCount += 1
                    let eliminateMsg = "   ✗ 消耗自身"
                    print(eliminateMsg)
                    logCallback?(eliminateMsg)
                }
            } else if allowFallback {
                // 如果允许回退且目标符号不存在，尝试生成其他元素
                let elementNames = ["水元素", "火元素", "雷元素", "冰元素", "土元素"]
                if let fallbackElement = elementNames.randomElement(),
                   let fallbackSymbol = SymbolLibrary.getSymbol(byName: fallbackElement) {
                    symbolPool.append(fallbackSymbol)
                    let msg = "   🎁 条件生成（回退）: \(fallbackSymbol.icon) \(fallbackSymbol.name)（原目标\(spawnSymbol)不存在）"
                    print(msg)
                    logCallback?(msg)
                    
                    if eliminateSelf {
                        // 使用nameKey匹配
            symbolPool.removeAll { $0.nameKey == symbol.nameKey }
                        eliminatedSymbolCount += 1
                        let eliminateMsg = "   ✗ 消耗自身"
                        print(eliminateMsg)
                        logCallback?(eliminateMsg)
                    }
                } else {
                    let msg = "   ✗ 无法生成符号（目标\(spawnSymbol)不存在且回退失败）"
                    print(msg)
                    logCallback?(msg)
                }
            } else {
                let msg = "   ✗ 无法生成符号: \(spawnSymbol)不存在"
                print(msg)
                logCallback?(msg)
            }
        }

        return 0
    }

    /// 消除交易符号奖励：消除1个勾玉或硬币，获得奖励
    private func processEliminateTradingSymbolBonus(symbol: Symbol, symbolPool: inout [Symbol], logCallback: ((String) -> Void)? = nil) -> Int {
        guard let targetSymbols = symbol.effectParams["targetSymbols"] as? [String],
              let bonus = symbol.effectParams["bonus"] as? Int else {
            return 0
        }

        // 找到符号池中第一个匹配的符号（勾玉或硬币）
        var eliminated = false
        // 使用nameKey匹配
        for targetName in targetSymbols {
            if let targetSymbolObj = findSymbol(byName: targetName, in: symbolPool),
               let index = symbolPool.firstIndex(where: { $0.nameKey == targetSymbolObj.nameKey }) {
                let removed = symbolPool.remove(at: index)
                eliminatedSymbolCount += 1
                eliminated = true
                let msg = "   💰 消除交易符号: \(removed.icon) \(removed.name)，获得\(bonus)金币"
                print(msg)
                logCallback?(msg)
                break
            }
        }

        if eliminated {
            return bonus
        } else {
            let msg = "   ✗ 符号池没有勾玉或硬币可消除"
            print(msg)
            logCallback?(msg)
            return 0
        }
    }

    /// 消除随机人类：消灭一个随机人类
    private func processEliminateRandomHuman(symbol: Symbol, symbolPool: inout [Symbol], logCallback: ((String) -> Void)? = nil) -> Int {
        guard let targetType = symbol.effectParams["targetType"] as? String else {
            return 0
        }

        // 找到符号池中所有人类类型的符号
        let humans = symbolPool.filter { $0.types.contains(targetType) }
        
        guard !humans.isEmpty else {
            let msg = "   ✗ 符号池没有人类可消灭"
            print(msg)
            logCallback?(msg)
            return 0
        }

        // 随机选择一个人类并消除
        if let randomHuman = humans.randomElement(),
           let index = symbolPool.firstIndex(where: { $0.id == randomHuman.id }) {
            let removed = symbolPool.remove(at: index)
            eliminatedSymbolCount += 1
            let msg = "   🧟 消灭随机人类: \(removed.icon) \(removed.name)"
            print(msg)
            logCallback?(msg)
        }

        return 0
    }
}

