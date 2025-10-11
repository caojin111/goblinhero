//
//  GameViewModel.swift
//  A004
//
//  游戏核心逻辑控制器
//

import Foundation
import SwiftUI

class GameViewModel: ObservableObject {
    // MARK: - 配置管理器
    private let configManager = GameConfigManager.shared
    
    // MARK: - 游戏状态
    @Published var currentCoins: Int = 10 // 初始金币
    @Published var totalEarnings: Int = 0 // 本轮总收益
    @Published var currentRound: Int = 1 // 当前回合
    @Published var spinsRemaining: Int = 10 // 剩余旋转次数
    @Published var rentAmount: Int = 50 // 当前房租
    @Published var gamePhase: GamePhase = .selectingSymbol
    
    // MARK: - 哥布林相关
    @Published var selectedGoblin: Goblin? = nil // 当前选择的哥布林
    @Published var unlockedGoblinIds: Set<Int> // 已解锁的哥布林ID
    @Published var showGoblinSelection: Bool = false // 显示哥布林选择界面
    @Published var goblinSelectionCompleted: Bool = false // 哥布林选择是否完成
    
    // MARK: - 符号池
    @Published var symbolPool: [Symbol] = [] // 玩家拥有的符号池
    @Published var slotMachine: [SlotCell] = [] // 老虎机格子（20个）
    @Published var availableSymbols: [Symbol] = [] // 可选择的符号
    
    // MARK: - 道具
    @Published var items: [Item] = []
    
    // MARK: - UI状态
    @Published var isSpinning: Bool = false
    @Published var showSymbolSelection: Bool = false
    @Published var showGameOver: Bool = false
    @Published var gameOverMessage: String = ""
    @Published var showEarningsTip: Bool = false
    @Published var earningsTipText: String = ""
    @Published var showGoblinBuffTip: Bool = false // 显示哥布林buff气泡
    @Published var showSymbolBuffTip: Bool = false // 显示符号buff气泡
    @Published var selectedSymbolForTip: Symbol? = nil // 当前选中查看的符号
    
    // MARK: - 掷骰子挖矿状态
    @Published var diceResult: Int = 0 // 骰子结果
    @Published var currentRoundMinedCells: [Int] = [] // 本次挖到的格子索引
    @Published var showDiceAnimation: Bool = false // 是否显示骰子动画
    
    // MARK: - 气泡定时器
    private var goblinTipTimer: DispatchWorkItem?
    private var symbolTipTimer: DispatchWorkItem?
    
    // MARK: - 常量
    private let slotCount = 25 // 老虎机格子数量（5x5棋盘）
    private let symbolChoiceCount = 3 // 每次可选符号数量
    
    init() {
        print("🎮 [游戏初始化] 开始初始化游戏")
        
        // 从配置文件加载默认解锁的哥布林
        self.unlockedGoblinIds = GoblinConfigManager.shared.getDefaultUnlockedIds()
        print("🎭 [哥布林配置] 默认解锁哥布林: \(unlockedGoblinIds)")
        
        loadGameSettings()
        // 不立即开始游戏，等待选择哥布林
        goblinSelectionCompleted = false
        showGoblinSelection = false
    }
    
    /// 加载游戏设置
    private func loadGameSettings() {
        let gameSettings = configManager.getGameSettings()
        currentCoins = gameSettings.initialCoins
        spinsRemaining = gameSettings.spinsPerRound
        rentAmount = configManager.getRentAmount(for: currentRound)
        
        print("🎮 [配置] 初始金币: \(currentCoins), 每回合旋转: \(spinsRemaining), 初始房租: \(rentAmount)")
    }
    
    // MARK: - 游戏流程控制
    
    /// 显示哥布林选择（游戏最开始）
    func showGoblinSelectionView() {
        print("🎭 [游戏流程] 显示哥布林选择界面")
        showGoblinSelection = true
    }
    
    /// 哥布林选择完成，开始游戏
    func onGoblinSelected() {
        guard let goblin = selectedGoblin else { return }
        print("🎭 [游戏流程] 哥布林选择完成: \(goblin.name)")
        goblinSelectionCompleted = true
        showGoblinSelection = false
        
        // 开始新游戏
        startNewGame()
    }
    
    /// 开始新游戏
    func startNewGame() {
        print("🎮 [新游戏] 初始化游戏状态")
        loadGameSettings()
        totalEarnings = 0
        currentRound = 1
        gamePhase = .selectingSymbol
        showGameOver = false
        
        // 初始化符号池（随机选择3个符号）
        symbolPool = SymbolLibrary.startingSymbols
        print("🎮 [新游戏] 随机初始符号池: \(symbolPool.map { $0.name })")
        
        // 初始化老虎机
        initializeSlotMachine()
        
        // 显示初始符号选择
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.showInitialSymbolSelection()
        }
    }
    
    /// 初始化老虎机格子（生成符号但都被矿石覆盖）
    private func initializeSlotMachine() {
        slotMachine = (0..<slotCount).map { _ in SlotCell(symbol: nil, isMined: false) }
        // 生成符号（都被矿石覆盖）
        generateSlotResults()
        print("🎰 [老虎机] 初始化 \(slotCount) 个格子，所有格子被矿石覆盖")
    }
    
    /// 掷骰子挖矿
    func rollDice() {
        guard !isSpinning else { return }
        
        print("🎲 [掷骰子] 开始掷骰子 - 回合 \(currentRound), 剩余次数 \(spinsRemaining)")
        
        isSpinning = true
        gamePhase = .spinning
        totalEarnings = 0
        currentRoundMinedCells = []
        
        // 生成骰子结果（1-6）
        diceResult = Int.random(in: 1...6)
        print("🎲 [掷骰子] 骰子点数: \(diceResult)")
        
        // 显示骰子动画
        showDiceAnimation = true
        
        // 模拟骰子滚动动画（0.8秒旋转 + 0.5秒显示结果）
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.3) {
            // 隐藏骰子动画
            self.showDiceAnimation = false
        }
        
        // 1.5秒后执行挖矿
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            // 挖矿
            self.mineRandomCells(count: self.diceResult)
            self.calculateEarnings()
            self.isSpinning = false
            self.gamePhase = .result
            
            print("💰 [收益] 本次挖矿获得: \(self.totalEarnings) 金币")
            
            // 增加金币
            self.currentCoins += self.totalEarnings
            self.spinsRemaining -= 1
            
            // 显示收益气泡提示
            let minedCount = self.currentRoundMinedCells.count
            let wastedCount = self.diceResult - minedCount
            
            if wastedCount > 0 {
                self.showEarningsTip(text: "💵 +\(self.totalEarnings) 金币\n⚠️ 浪费 \(wastedCount) 次挖矿")
            } else {
                self.showEarningsTip(text: "💵 +\(self.totalEarnings) 金币")
            }
            
            // 检查是否需要支付房租
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                self.checkRentPayment()
            }
        }
    }
    
    /// 随机挖开格子（只在未开采的矿石上挖，不够则浪费）
    private func mineRandomCells(count: Int) {
        // 获取所有未挖开的格子索引
        let unminedIndices = slotMachine.enumerated()
            .filter { !$0.element.isMined }
            .map { $0.offset }
        
        // 确定实际要挖的数量（不超过剩余格子数）
        let actualCount = min(count, unminedIndices.count)
        let wastedCount = count - actualCount
        
        // 随机选择要挖的格子
        let selectedIndices = Array(unminedIndices.shuffled().prefix(actualCount))
        
        print("⛏️ [挖矿规则] 只在未开采矿石上挖矿")
        print("⛏️ [挖矿] 骰子点数: \(count), 未挖格子数: \(unminedIndices.count), 实际挖开: \(actualCount)个")
        
        if wastedCount > 0 {
            print("⚠️ [挖矿] 浪费了 \(wastedCount) 个挖矿机会（没有足够的未开采矿石）")
        }
        
        // 标记为已挖开
        for index in selectedIndices {
            slotMachine[index].isMined = true
            currentRoundMinedCells.append(index)
        }
        
        // 打印挖到的内容
        for index in selectedIndices {
            if let symbol = slotMachine[index].symbol {
                print("⛏️ [挖矿] 格子\(index): 挖到符号 \(symbol.icon) (\(symbol.name), \(symbol.baseValue)分)")
            } else {
                print("⛏️ [挖矿] 格子\(index): 挖到空格子 (+1分)")
            }
        }
        
        if actualCount == 0 {
            print("❌ [挖矿] 所有格子都已挖开，本次挖矿完全浪费！")
        }
    }
    
    /// 生成老虎机结果（为本阶段生成符号）
    private func generateSlotResults() {
        print("🎰 [生成结果] 为新阶段生成符号")
        
        // 清空所有格子符号
        for index in 0..<slotCount {
            slotMachine[index].symbol = nil
        }
        
        if symbolPool.isEmpty {
            print("🎰 [生成结果] 符号池为空，全部空格子")
            return
        }
        
        // 计算应该显示的符号数量（基于符号池大小）
        let targetSymbolCount = getTargetSymbolCount()
        let uniqueSymbolCount = Set(symbolPool.map { $0.name }).count
        print("🎰 [生成结果] 符号池总数量: \(symbolPool.count), 不同种类: \(uniqueSymbolCount), 目标显示: \(targetSymbolCount)/\(slotCount)")
        
        // 随机选择要显示的符号
        var symbolsToShow: [Symbol] = []
        for _ in 0..<targetSymbolCount {
            let randomSymbol = getWeightedRandomSymbol()
            symbolsToShow.append(randomSymbol)
        }
        
        // 随机分配到格子中
        let availablePositions = Array(0..<slotCount).shuffled()
        for (index, symbol) in symbolsToShow.enumerated() {
            if index < availablePositions.count {
                slotMachine[availablePositions[index]].symbol = symbol
            }
        }
        
        print("🎰 [生成结果] 实际生成符号: \(slotMachine.compactMap { $0.symbol }.count)/\(slotCount) 个符号")
    }
    
    /// 获取目标符号数量（基于符号池中不同符号的种类数量）
    private func getTargetSymbolCount() -> Int {
        // 计算符号池中不同符号的种类数量
        let uniqueSymbolCount = Set(symbolPool.map { $0.name }).count
        return configManager.getSymbolDisplayCount(for: uniqueSymbolCount)
    }
    
    
    /// 根据符号在池中的数量获取权重随机符号
    private func getWeightedRandomSymbol() -> Symbol {
        // 计算每个符号的权重（在池中出现的次数）
        var symbolWeights: [Symbol: Int] = [:]
        
        for symbol in symbolPool {
            symbolWeights[symbol, default: 0] += 1
        }
        
        // 根据权重随机选择
        let totalWeight = symbolWeights.values.reduce(0, +)
        let randomValue = Int.random(in: 1...totalWeight)
        
        var currentWeight = 0
        for (symbol, weight) in symbolWeights {
            currentWeight += weight
            if randomValue <= currentWeight {
                return symbol
            }
        }
        
        // 如果出错，返回第一个符号
        return symbolPool.first!
    }
    
    /// 计算收益（只计算本次挖到的格子）
    private func calculateEarnings() {
        totalEarnings = 0
        var emptyCount = 0
        var symbolEarnings = 0
        var eliminatedSymbolCount = 0 // 记录消除的符号数量（用于勇者哥布林buff）
        
        // 只计算本次挖到的格子
        for index in currentRoundMinedCells {
            guard index < slotMachine.count else { continue }
            
            let cell = slotMachine[index]
            
            if let symbol = cell.symbol {
                eliminatedSymbolCount += 1 // 符号被挖到就算消除
                
                // 获取相邻已挖开的符号
                var adjacentSymbols: [Symbol] = []
                
                // 左侧（如果是5x5棋盘）
                let row = index / 5
                let col = index % 5
                
                // 左
                if col > 0 {
                    let leftIndex = index - 1
                    if slotMachine[leftIndex].isMined, let leftSymbol = slotMachine[leftIndex].symbol {
                        adjacentSymbols.append(leftSymbol)
                    }
                }
                
                // 右
                if col < 4 {
                    let rightIndex = index + 1
                    if slotMachine[rightIndex].isMined, let rightSymbol = slotMachine[rightIndex].symbol {
                        adjacentSymbols.append(rightSymbol)
                    }
                }
                
                // 上
                if row > 0 {
                    let topIndex = index - 5
                    if slotMachine[topIndex].isMined, let topSymbol = slotMachine[topIndex].symbol {
                        adjacentSymbols.append(topSymbol)
                    }
                }
                
                // 下
                if row < 4 {
                    let bottomIndex = index + 5
                    if slotMachine[bottomIndex].isMined, let bottomSymbol = slotMachine[bottomIndex].symbol {
                        adjacentSymbols.append(bottomSymbol)
                    }
                }
                
                let value = symbol.calculateValue(adjacentSymbols: adjacentSymbols)
                symbolEarnings += value
                print("💰 [计算收益] 格子\(index): \(symbol.icon) = \(value)分 (基础:\(symbol.baseValue), 相邻:\(adjacentSymbols.count))")
            } else {
                // 空格子 +1分
                emptyCount += 1
                totalEarnings += 1
                print("💰 [计算收益] 格子\(index): 空格子 = 1分")
            }
        }
        
        totalEarnings += symbolEarnings
        
        // 应用道具倍率
        for item in items {
            totalEarnings = Int(Double(totalEarnings) * item.multiplier)
        }
        
        // 应用哥布林buff效果
        applyGoblinBuff(eliminatedSymbolCount: eliminatedSymbolCount)
        
        print("💰 [计算收益] 本次挖矿: 空格\(emptyCount)个(+\(emptyCount)分), 符号(+\(symbolEarnings)分), 总收益: \(totalEarnings) 金币")
    }
    
    /// 应用哥布林buff效果（基于配置文件）
    private func applyGoblinBuff(eliminatedSymbolCount: Int) {
        guard let goblin = selectedGoblin else { return }
        
        // 检查是否启用buff效果
        guard GoblinConfigManager.shared.isBuffEffectsEnabled() else {
            print("⚠️ [哥布林Buff] buff效果已在配置中禁用")
            return
        }
        
        // 根据buffType处理不同的buff
        switch goblin.buffType {
        case "on_symbol_eliminate": // 勇者哥布林：每有一个符号被消除，则+N金币
            let bonusCoins = Int(goblin.buffValue) * eliminatedSymbolCount
            totalEarnings += bonusCoins
            if bonusCoins > 0 {
                print("\(goblin.icon) [\(goblin.name)] 消除\(eliminatedSymbolCount)个符号，额外获得\(bonusCoins)金币 (单次+\(Int(goblin.buffValue)))")
            }
            
        case "extra_symbol_choice": // 工匠哥布林：每回合增加N次获得符号3选1的机会
            print("\(goblin.icon) [\(goblin.name)] buff将在回合结束时生效（额外\(Int(goblin.buffValue))次选择）")
            
        case "dice_probability_boost": // 赌徒哥布林：挖到骰子概率翻N倍
            print("\(goblin.icon) [\(goblin.name)] 骰子概率提升\(goblin.buffValue)倍效果已激活")
            
        case "soldier_bonus": // 国王哥布林：每有一个士兵，额外获得N金币
            // TODO: 当游戏中有士兵符号时实现
            print("\(goblin.icon) [\(goblin.name)] 士兵buff待实现（每个士兵+\(Int(goblin.buffValue))金币）")
            
        case "magic_bag_fill": // 巫师哥布林：每回合挖矿之前随机填充N个魔法袋
            print("\(goblin.icon) [\(goblin.name)] 魔法袋buff将在挖矿前生效（填充\(Int(goblin.buffValue))个）")
            
        default:
            print("⚠️ [哥布林Buff] 未知的buff类型: \(goblin.buffType)")
        }
    }
    
    /// 重置矿石状态（新阶段开始时调用）
    private func resetMineState() {
        for index in 0..<slotMachine.count {
            slotMachine[index].isMined = false
        }
        currentRoundMinedCells = []
        diceResult = 0
        print("🔄 [重置] 所有格子重新被矿石覆盖")
    }
    
    /// 检查房租支付
    private func checkRentPayment() {
        if spinsRemaining <= 0 {
            print("🏠 [房租] 需要支付房租: \(rentAmount) 金币, 当前拥有: \(currentCoins) 金币")
            gamePhase = .payingRent
            
            if currentCoins >= rentAmount {
                // 支付成功
                currentCoins -= rentAmount
                currentRound += 1
                spinsRemaining = configManager.getGameSettings().spinsPerRound
                rentAmount = configManager.getRentAmount(for: currentRound)
                
                print("✅ [房租] 支付成功！进入回合 \(currentRound)")
                
                // 显示符号选择
                showSymbolSelectionPhase()
            } else {
                // 游戏失败
                print("❌ [游戏结束] 金币不足，无法支付房租")
                gameOver(message: "金币不足！无法支付 \(rentAmount) 金币的房租")
            }
        } else {
            // 等待玩家手动点击"挖矿x1"按钮
            print("⏸️ [等待操作] 等待玩家点击挖矿按钮")
            gamePhase = .result
        }
    }
    
    /// 显示初始符号选择（游戏开始时的第一次选择）
    private func showInitialSymbolSelection() {
        print("🎯 [初始选择] 游戏开始，请选择第一个符号")
        gamePhase = .selectingSymbol
        availableSymbols = SymbolLibrary.getSymbolChoiceOptions()
        print("🎯 [初始选择] 生成3个可选符号: \(availableSymbols.map { $0.name })")
        showSymbolSelection = true
    }
    
    /// 显示符号选择阶段（回合结束后的选择）
    private func showSymbolSelectionPhase() {
        print("🎯 [回合选择] 回合结束，请选择新符号")
        gamePhase = .selectingSymbol
        availableSymbols = SymbolLibrary.getSymbolChoiceOptions()
        print("🎯 [回合选择] 生成3个可选符号: \(availableSymbols.map { $0.name })")
        showSymbolSelection = true
        
        // 工匠哥布林buff：额外获得一次符号选择机会
        if let goblin = selectedGoblin, goblin.id == 2 {
            print("🔨 [工匠哥布林] 每回合额外获得一次符号选择机会")
            // 这里的实现：玩家在本回合可以选择两次符号
            // 为了简化，我们在第一次选择完成后再显示一次选择
        }
    }
    
    // 记录本回合工匠哥布林是否已使用buff
    private var craftsmanBuffUsed = false
    
    /// 选择符号
    func selectSymbol(_ symbol: Symbol) {
        print("✅ [选择符号] 玩家选择了: \(symbol.name)")
        symbolPool.append(symbol)
        showSymbolSelection = false
        
        // 检查工匠哥布林buff：如果本回合还没用过，再给一次机会
        if let goblin = selectedGoblin, goblin.id == 2, !craftsmanBuffUsed, currentRound > 1 {
            // 工匠哥布林buff：额外获得一次选择机会
            craftsmanBuffUsed = true
            print("🔨 [工匠哥布林] 触发buff，额外获得一次符号选择机会")
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.gamePhase = .selectingSymbol
                self.availableSymbols = SymbolLibrary.getSymbolChoiceOptions()
                self.showSymbolSelection = true
            }
            return
        }
        
        // 重置工匠哥布林buff标记
        craftsmanBuffUsed = false
        
        // 重新生成棋盘符号
        generateSlotResults()
        
        // 重置矿石状态
        resetMineState()
        
        // 符号选择完成后，等待玩家手动点击掷骰子按钮
        print("🎮 [选择完成] 符号已添加，新阶段开始，等待玩家掷骰子")
        gamePhase = .result
    }
    
    /// 手动掷骰子挖矿
    func manualSpin() {
        print("🎲 [手动掷骰子] 玩家点击掷骰子按钮")
        if spinsRemaining > 0 && !isSpinning && gamePhase == .result {
            rollDice()
        }
    }
    
    /// 游戏结束
    private func gameOver(message: String) {
        print("🎮 [游戏结束] \(message)")
        gamePhase = .gameOver
        gameOverMessage = message
        showGameOver = true
    }
    
    /// 重新开始游戏
    func restartGame() {
        print("🔄 [重新开始] 重置游戏")
        // 重新选择哥布林
        goblinSelectionCompleted = false
        selectedGoblin = nil
        showGoblinSelection = false
        craftsmanBuffUsed = false
    }
    
    /// 显示收益气泡提示
    private func showEarningsTip(text: String) {
        earningsTipText = text
        showEarningsTip = true
        
        // 2秒后自动隐藏
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.showEarningsTip = false
        }
    }
    
    /// 显示哥布林buff气泡
    func showGoblinBuffInfo() {
        guard selectedGoblin != nil else { return }
        print("🎭 [哥布林] 显示buff信息气泡")
        
        // 取消之前的定时器
        goblinTipTimer?.cancel()
        
        // 立即显示新气泡
        showGoblinBuffTip = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            self.showGoblinBuffTip = true
        }
        
        // 创建新的定时器，2秒后自动隐藏
        let workItem = DispatchWorkItem { [weak self] in
            self?.showGoblinBuffTip = false
        }
        goblinTipTimer = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0, execute: workItem)
    }
    
    /// 显示符号buff气泡
    func showSymbolBuffInfo(for symbol: Symbol) {
        print("📝 [符号] 显示符号信息气泡: \(symbol.name)")
        
        // 取消之前的定时器
        symbolTipTimer?.cancel()
        
        // 立即隐藏旧气泡，然后显示新气泡
        showSymbolBuffTip = false
        selectedSymbolForTip = nil
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            self.selectedSymbolForTip = symbol
            self.showSymbolBuffTip = true
        }
        
        // 创建新的定时器，2秒后自动隐藏
        let workItem = DispatchWorkItem { [weak self] in
            self?.showSymbolBuffTip = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                self?.selectedSymbolForTip = nil
            }
        }
        symbolTipTimer = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0, execute: workItem)
    }
}
