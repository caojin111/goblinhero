//
//  BondEffectProcessor.swift
//  A004
//
//  羁绊效果处理器 - 处理羁绊Buff的效果
//

import Foundation

class BondEffectProcessor {
    // MARK: - 状态追踪
    private var activeBondBuffs: Set<String> = [] // 当前激活的羁绊Buff ID集合
    
    /// 处理羁绊Buff效果（在回合开始时调用）
    /// - Parameter isRoundStart: 是否为回合开始调用（true表示回合开始，false表示其他时机）
    func processBondBuffs(symbolPool: inout [Symbol], currentRound: Int, isRoundStart: Bool = false) -> (bonus: Int, shouldGameOver: Bool) {
        let bondBuffs = BondBuffConfigManager.shared.getActiveBondBuffs(symbolPool: symbolPool)
        // 记录类型计数羁绊激活情况，供其他流程使用
        BondBuffRuntime.shared.activeTypeBonds = bondBuffs
            .filter { $0.requiredType != nil }
            .map { $0.nameKey }
        var totalBonus = 0
        var shouldGameOver = false
        
        print("\n🔗 [羁绊Buff] 开始处理\(bondBuffs.count)个激活的羁绊Buff (isRoundStart: \(isRoundStart))")
        
        for bondBuff in bondBuffs {
            let effect = processBondBuffEffect(bondBuff: bondBuff, symbolPool: &symbolPool, currentRound: currentRound, isRoundStart: isRoundStart)
            totalBonus += effect.bonus
            if effect.shouldGameOver {
                shouldGameOver = true
            }
        }
        
        if totalBonus != 0 {
            print("🔗 [羁绊Buff] 总效果: \(totalBonus > 0 ? "+" : "")\(totalBonus) 金币")
        }
        
        return (bonus: totalBonus, shouldGameOver: shouldGameOver)
    }
    
    /// 处理单个羁绊Buff的效果
    private func processBondBuffEffect(bondBuff: BondBuff, symbolPool: inout [Symbol], currentRound: Int, isRoundStart: Bool = false) -> (bonus: Int, shouldGameOver: Bool) {
        // 根据羁绊的nameKey来处理不同的效果
        // nameKey可能是 "merchant_trading_bond" 或 "bonds.merchant_trading_bond.name" 格式
        let nameKey = bondBuff.nameKey.contains(".") ? 
            String(bondBuff.nameKey.split(separator: ".").dropLast().last ?? "") : 
            bondBuff.nameKey
        
        switch nameKey {
        // ---------- 类型计数羁绊（可叠加） ----------
        case "human_3_bond":
            // 每回合获得1个随机人类（排除圣骑士）
            // 注意：只在回合开始时触发，不在每次转动时触发
            if isRoundStart && symbolPool.filter({ $0.types.contains("human") }).count >= 3 {
                let humanCandidates = SymbolLibrary.getSymbols(byType: "human").filter { $0.nameKey != "paladin" }
                if let human = humanCandidates.randomElement() {
                    symbolPool.append(human)
                    print("👥 [羁绊] 人类3：回合开始时生成随机人类 \(human.name)")
                }
            }
            return (0, false)
        case "human_5_bond":
            // 人类基础价值+5（全局加成由效果处理器统一应用，留给上层处理或在收益计算时读取）
            print("👥 [羁绊] 人类5：基础价值+5（需全局加成支持）")
            return (0, false)
        case "human_10_bond":
            // 符号池每有1个人类，每回合额外获得5金币
            let humanCount = symbolPool.filter { $0.types.contains("human") }.count
            let bonus = humanCount * 5
            if bonus > 0 {
                print("👥 [羁绊] 人类10：符号池有\(humanCount)个人类，每回合额外+\(bonus)金币")
                return (bonus, false)
            }
            return (0, false)
            
        case "material_2_bond":
            // 每回合自动熔合2个normal材料为rare（第一回合不触发）
            if currentRound == 1 {
                print("🧪 [羁绊] 材料2：第一回合跳过合成")
                return (0, false)
            }
            let normals = symbolPool.enumerated().filter { $0.element.types.contains("material") && $0.element.rarity == .common }
            if normals.count >= 2 {
                // 移除两个normal
                let remove = normals.prefix(2).map(\.offset).sorted(by: >)
                remove.forEach { symbolPool.remove(at: $0) }
                // 添加一个rare材料（随机）
                if let rareMat = SymbolLibrary.getSymbols(byType: "material").filter({ $0.rarity == .rare }).randomElement() {
                    symbolPool.append(rareMat)
                    print("🧪 [羁绊] 材料2：合成1个稀有材料 \(rareMat.name)")
                }
            }
            return (0, false)
        case "material_4_bond":
            // 每回合自动熔合2个rare材料为epic
            let rares = symbolPool.enumerated().filter { $0.element.types.contains("material") && $0.element.rarity == .rare }
            if rares.count >= 2 {
                let remove = rares.prefix(2).map(\.offset).sorted(by: >)
                remove.forEach { symbolPool.remove(at: $0) }
                if let epicMat = SymbolLibrary.getSymbols(byType: "material").filter({ $0.rarity == .epic }).randomElement() {
                    symbolPool.append(epicMat)
                    print("🧪 [羁绊] 材料4：合成1个史诗材料 \(epicMat.name)")
                }
            }
            return (0, false)
        case "cozylife_3_bond":
            // 空格收益+3：在收益计算处处理，这里记录激活
            print("🏠 [羁绊] cozy life 3：空格收益+3（收益计算时应用）")
            return (0, false)
        case "cozylife_6_bond":
            // 空格收益+10
            print("🏠 [羁绊] cozy life 6：空格收益+10（收益计算时应用）")
            return (0, false)
        case "tools_2_bond":
            // 掷出1再转一次（掷骰逻辑中处理）
            print("🔧 [羁绊] tools 2：掷出1再转一次（掷骰逻辑中实现）")
            return (0, false)
        case "tools_4_bond":
            // 掷出6挖开未翻矿石（掷骰逻辑中处理）
            print("🔧 [羁绊] tools 4：掷出6挖开未翻矿石（掷骰逻辑中实现）")
            return (0, false)
        case "classictale_2_bond":
            // 随机一处特殊格子，收益翻倍，简易光效标记（标记逻辑留到棋盘层实现）
            print("📜 [羁绊] classic tale 2：标记特殊格子收益翻倍（需棋盘层标记）")
            return (0, false)
        case "classictale_4_bond":
            // 四角挖出 +50（在挖掘逻辑中处理）
            print("📜 [羁绊] classic tale 4：四角挖出+50（挖掘时处理）")
            return (0, false)
        case "classictale_6_bond":
            // 中心挖出 +100
            print("📜 [羁绊] classic tale 6：中心挖出+100（挖掘时处理）")
            return (0, false)
        case "merchant_trading_bond":
            // 奸商：被商人消除的符号获得其基础价值*2的金币（在商人消除符号时处理，这里不需要处理）
            return processMerchantTradingBond()
            
        case "vampire_curse_bond":
            // 吸血鬼的诅咒：如果吸血鬼与领结同时存在，每回合减少50金币
            return processVampireCurseBond(symbolPool: symbolPool)
            
        case "death_blessing_bond":
            // 死神的眷顾：接下来5个回合每回合获得1000金币，5个回合后游戏强制结束
            return processDeathBlessingBond(currentRound: currentRound)
            
        case "wolf_hunter_bond":
            // 捕狼队：如果狼人与锄头同时存在，每回合减少20金币
            return processWolfHunterBond(symbolPool: symbolPool)
            
        case "element_master_bond":
            // 元素掌握者：如果拥有全部五种元素，每回合获得100金币
            return processElementMasterBond(symbolPool: symbolPool)
            
        case "justice_bond":
            // 正义必胜：如果十字架和修女同时存在，获得一个龙之火铳（如果未拥有）
            return processJusticeBond(symbolPool: &symbolPool)
            
        case "apocalypse_bond":
            // 世界末日：如果哥莫拉、丧尸、狼人、吸血鬼同时存在，下回合开始时随机消灭一半符号，获得2000金币
            return processApocalypseBond(symbolPool: &symbolPool)
            
        case "human_extinction_bond":
            // 人类灭绝：如果光线枪、外星头盔、宇宙飞船、精神控制器同时存在，下回合开始时消灭5个人类，获得100金币
            return processHumanExtinctionBond(symbolPool: &symbolPool)
            
        case "raccoon_city_bond":
            // 浣熊市：每次挖矿前感染一个人类变成丧尸。每有一个丧尸，额外金币增加20
            return processRaccoonCityBond(symbolPool: &symbolPool)
            
        case "dark_forest_3_bond":
            // 黑暗森林-3：每回合获得一个魔法袋
            return processDarkForest3Bond(symbolPool: &symbolPool)
            
        default:
            print("⚠️ [羁绊Buff] 未知的羁绊Buff: \(bondBuff.nameKey)")
            return (bonus: 0, shouldGameOver: false)
        }
    }
    
    // MARK: - 各个羁绊效果实现
    
    private func processMerchantTradingBond() -> (bonus: Int, shouldGameOver: Bool) {
        // 奸商羁绊效果：被商人消除的符号获得其基础价值*2的金币
        // 这个效果在 SymbolEffectProcessor 中商人消除符号时处理，这里不需要额外处理
        print("💰 [羁绊Buff] 奸商羁绊已激活：被商人消除的符号将获得其基础价值*2的金币")
        return (bonus: 0, shouldGameOver: false)
    }
    
    private func processVampireCurseBond(symbolPool: [Symbol]) -> (bonus: Int, shouldGameOver: Bool) {
        // 检查是否有吸血鬼和领结（使用nameKey匹配）
        let hasVampire = symbolPool.contains { $0.nameKey == "vampire" }
        let hasTie = symbolPool.contains { $0.nameKey == "tie" }
        
        if hasVampire && hasTie {
            print("🧛 [羁绊Buff] 吸血鬼的诅咒：-50金币")
            return (bonus: -50, shouldGameOver: false)
        }
        return (bonus: 0, shouldGameOver: false)
    }
    
    private func processDeathBlessingBond(currentRound: Int) -> (bonus: Int, shouldGameOver: Bool) {
        // 死神的眷顾：接下来5个回合每回合获得1000金币，5个回合后游戏强制结束
        // 这个效果应该在死神符号被挖出时注册到roundStartBuffs
        // 这里检查是否应该结束游戏（如果已经过了5个回合）
        // 注意：实际回合奖励在SymbolEffectProcessor的roundStartBuffs中处理
        // 这里只检查是否需要结束游戏
        
        // 检查死神是否在符号池中，如果在，说明buff已注册
        // 实际游戏结束逻辑需要在GameViewModel中根据roundStartBuffs的状态来判断
        print("💀 [羁绊Buff] 死神的眷顾：每回合+1000金币（已注册）")
        return (bonus: 0, shouldGameOver: false) // 游戏结束逻辑在SymbolEffectProcessor中处理
    }
    
    private func processWolfHunterBond(symbolPool: [Symbol]) -> (bonus: Int, shouldGameOver: Bool) {
        // 检查是否有狼人和锄头（使用nameKey匹配）
        let hasWerewolf = symbolPool.contains { $0.nameKey == "werewolf" }
        let hasHoe = symbolPool.contains { $0.nameKey == "hoe" }
        
        if hasWerewolf && hasHoe {
            print("🐺 [羁绊Buff] 捕狼队：-20金币")
            return (bonus: -20, shouldGameOver: false)
        }
        return (bonus: 0, shouldGameOver: false)
    }
    
    private func processElementMasterBond(symbolPool: [Symbol]) -> (bonus: Int, shouldGameOver: Bool) {
        // 检查是否拥有全部五种元素
        let requiredElements = Set(["水元素", "火元素", "雷元素", "冰元素", "土元素"])
        let collectedElements = Set(symbolPool.filter { requiredElements.contains($0.name) }.map { $0.name })
        
        if collectedElements.count == 5 && collectedElements == requiredElements {
            print("✨ [羁绊Buff] 元素掌握者：+100金币")
            return (bonus: 100, shouldGameOver: false)
        }
        return (bonus: 0, shouldGameOver: false)
    }
    
    private func processJusticeBond(symbolPool: inout [Symbol]) -> (bonus: Int, shouldGameOver: Bool) {
        // 检查是否已拥有龙之火铳
        let hasDragonFireGun = symbolPool.contains { $0.nameKey == "dragon_fire_gun" }
        
        if !hasDragonFireGun {
            // 如果未拥有，则添加一个龙之火铳
            if let dragonFireGun = SymbolLibrary.getSymbol(byName: "dragon_fire_gun") {
                symbolPool.append(dragonFireGun)
                print("⚖️ [羁绊Buff] 正义必胜：获得龙之火铳")
            } else {
                print("⚠️ [羁绊Buff] 正义必胜：无法找到龙之火铳符号")
            }
        } else {
            print("⚖️ [羁绊Buff] 正义必胜：已拥有龙之火铳，无需添加")
        }
        
        return (bonus: 0, shouldGameOver: false)
    }
    
    private func processApocalypseBond(symbolPool: inout [Symbol]) -> (bonus: Int, shouldGameOver: Bool) {
        // 检查是否有哥莫拉、丧尸、狼人、吸血鬼（使用nameKey匹配）
        let requiredNameKeys = Set(["gomorrah", "zombie", "werewolf", "vampire"])
        let hasAll = requiredNameKeys.allSatisfy { nameKey in
            symbolPool.contains { $0.nameKey == nameKey }
        }
        
        if hasAll {
            // 随机消灭一半符号
            let halfCount = symbolPool.count / 2
            var eliminatedCount = 0
            var indicesToRemove: [Int] = []
            
            // 随机选择要消除的符号索引
            var availableIndices = Array(0..<symbolPool.count)
            for _ in 0..<halfCount {
                if let randomIndex = availableIndices.randomElement(),
                   let arrayIndex = availableIndices.firstIndex(of: randomIndex) {
                    indicesToRemove.append(randomIndex)
                    availableIndices.remove(at: arrayIndex)
                    eliminatedCount += 1
                }
            }
            
            // 按索引从大到小排序，避免删除时索引错乱
            indicesToRemove.sort(by: >)
            for index in indicesToRemove {
                symbolPool.remove(at: index)
            }
            
            print("🌍 [羁绊Buff] 世界末日：消灭\(eliminatedCount)个符号，+500金币")
            return (bonus: 500, shouldGameOver: false)
        }
        return (bonus: 0, shouldGameOver: false)
    }
    
    private func processHumanExtinctionBond(symbolPool: inout [Symbol]) -> (bonus: Int, shouldGameOver: Bool) {
        // 检查是否有光线枪、外星头盔、宇宙飞船、精神控制器（使用nameKey匹配）
        let requiredNameKeys = Set(["ray_gun", "alien_helmet", "spaceship", "mind_controller"])
        let hasAll = requiredNameKeys.allSatisfy { nameKey in
            symbolPool.contains { $0.nameKey == nameKey }
        }
        
        if hasAll {
            // 消灭5个随机人类
            let humans = symbolPool.enumerated().filter { (_, symbol) in
                symbol.types.contains("human")
            }
            
            let eliminateCount = min(5, humans.count)
            if eliminateCount > 0 {
                // 随机选择5个人类（如果不足5个，则全部消灭）
                let selectedHumans = Array(humans.shuffled().prefix(eliminateCount))
                // 按索引从大到小排序，确保删除时索引不会错乱
                let sortedIndices = selectedHumans.map { $0.offset }.sorted(by: >)
                for index in sortedIndices {
                    symbolPool.remove(at: index)
                }
                print("👽 [羁绊Buff] 人类灭绝：消灭\(eliminateCount)个人类，+100金币")
                return (bonus: 100, shouldGameOver: false)
            }
        }
        return (bonus: 0, shouldGameOver: false)
    }
    
    private func processRaccoonCityBond(symbolPool: inout [Symbol]) -> (bonus: Int, shouldGameOver: Bool) {
        // 每次挖矿前感染一个人类变成丧尸
        // 这个效果应该在挖矿前触发，不是在回合开始时
        // 每有一个丧尸，额外金币增加20（这个在计算收益时应用）
        
        // 感染一个人类
        if let humanIndex = symbolPool.firstIndex(where: { $0.types.contains("human") }) {
            if let zombie = SymbolLibrary.getSymbol(byName: "丧尸") {
                symbolPool[humanIndex] = zombie
                print("🧟 [羁绊Buff] 浣熊市：感染1个人类变成丧尸")
            }
        }
        
        // 计算丧尸数量奖励（这个应该在计算收益时应用，这里只返回0）
        return (bonus: 0, shouldGameOver: false)
    }
    
    private func processDarkForest3Bond(symbolPool: inout [Symbol]) -> (bonus: Int, shouldGameOver: Bool) {
        // 黑暗森林-3：每回合获得一个魔法袋
        guard let magicBag = SymbolLibrary.getSymbol(byName: "魔法袋") else {
            print("⚠️ [羁绊Buff] 黑暗森林-3：找不到魔法袋符号")
            return (bonus: 0, shouldGameOver: false)
        }
        
        symbolPool.append(magicBag)
        print("🌲 [羁绊Buff] 黑暗森林-3：每回合获得1个魔法袋")
        return (bonus: 0, shouldGameOver: false)
    }
}
