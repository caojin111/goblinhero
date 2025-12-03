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
    private let effectProcessor = SymbolEffectProcessor()
    private let localizationManager = LocalizationManager.shared
    
    // MARK: - 游戏状态
    @Published var currentCoins: Int = 10 // 初始金币
    @Published var totalEarnings: Int = 0 // 本轮总收益
    @Published var currentRound: Int = 1 // 当前回合
    @Published var spinsRemaining: Int = 10 // 剩余旋转次数
    @Published var rentAmount: Int = 50 // 当前房租
    @Published var gamePhase: GamePhase = .selectingSymbol
    @Published var currentDiceCount: Int = 1 // 当前骰子数量
    
    // MARK: - 累计统计
    private var totalRentPaid: Int = 0 // 累计支付的房租总额
    var accumulatedCoins: Int { // 累计金币 = 当前金币 + 已支付的房租
        return currentCoins + totalRentPaid
    }

    // MARK: - 个人记录
    @Published var bestRound: Int = 0 // 最佳存活回合数
    @Published var bestCoins: Int = 0 // 历史最多金币

    // MARK: - 体力系统
    @Published var stamina: Int = 300 // 当前体力值
    @Published var nextStaminaRecoveryTime: Date? = nil // 下次体力恢复时间
    private var staminaTimer: Timer? = nil // 体力恢复定时器
    
    let maxStamina = 300 // 最大体力
    private let staminaPerGame = 30 // 每次游戏消耗体力
    private let staminaRecoveryInterval: TimeInterval = 5 * 60 // 5分钟恢复1点体力
    
    // MARK: - 钻石系统
    @Published var diamonds: Int = 0 // 当前钻石数量
    
    // MARK: - 签到系统
    @Published var signInDay: Int = 1 // 当前签到天数（1-7循环）
    @Published var lastSignInDate: Date? = nil // 上次签到日期
    @Published var canSignInToday: Bool = true // 今日是否可签到
    private var signInTimer: Timer? = nil // 签到状态检查定时器
    
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
    // MARK: - 气泡系统（统一管理）
    enum TipType {
        case earnings(String)
        case goblinBuff
        case symbolBuff(Symbol)
    }
    
    @Published var currentTipType: TipType? = nil // 当前显示的气泡类型
    @Published var showEarningsTip: Bool = false
    @Published var earningsTipText: String = ""
    @Published var showGoblinBuffTip: Bool = false // 显示哥布林buff气泡
    @Published var showSymbolBuffTip: Bool = false // 显示符号buff气泡
    @Published var selectedSymbolForTip: Symbol? = nil // 当前选中查看的符号
    @Published var isTipDismissing: Bool = false // 气泡是否正在消失动画中
    
    // MARK: - 测试模式
    @Published var showDebugPanel: Bool = false // 显示调试面板
    @Published var transparentMode: Bool = false // 棋盘透明模式
    @Published var settlementLogs: [String] = [] // 结算日志
    
    // MARK: - 掷骰子挖矿状态
    @Published var diceResult: Int = 0 // 骰子结果
    @Published var currentRoundMinedCells: [Int] = [] // 本次挖到的格子索引
    @Published var showDiceAnimation: Bool = false // 是否显示骰子动画
    
    // MARK: - 结算动画状态
    @Published var isPlayingSettlement: Bool = false // 是否正在播放结算动画
    @Published var currentSettlingCellIndex: Int? = nil // 当前正在结算的格子索引
    @Published var currentSettlingCellEarnings: Int = 0 // 当前格子的收益金额
    @Published var settlementSequence: [(cellIndex: Int, symbol: Symbol?, earnings: Int)] = [] // 结算序列
    private var settlementTimer: DispatchWorkItem? = nil // 结算动画定时器
    
    // MARK: - 气泡定时器（统一管理）
    private var tipTimer: DispatchWorkItem? = nil
    
    // MARK: - 常量
    private var slotCount: Int { // 老虎机格子数量（从配置文件读取）
        configManager.getGameSettings().slotCount
    }
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
        
        // 初始化体力系统
        loadStamina()
        startStaminaRecoveryTimer()
        
        // 初始化钻石系统
        loadDiamonds()
        
        // 初始化签到系统
        loadSignInStatus()
        startSignInStatusTimer()
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
        
        // 检查体力是否足够
        if stamina < staminaPerGame {
            print("⚠️ [体力不足] 当前体力: \(stamina), 需要: \(staminaPerGame)")
            // 这里可以显示提示，暂时先返回
            showGoblinSelection = false
            return
        }
        
        print("🎭 [游戏流程] 哥布林选择完成: \(goblin.name)")
        
        // 扣除体力
        stamina -= staminaPerGame
        saveStamina()
        print("⚡ [体力消耗] 消耗\(staminaPerGame)体力，剩余: \(stamina)")
        
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
        
        // 重置累计统计
        totalRentPaid = 0
        
        // 重置buff标记
        wizardBuffUsedThisRound = false
        craftsmanBuffUsed = false
        
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
        
        let diceCount = effectProcessor.getDiceCount()
        print("🎲 [掷骰子] 开始掷骰子 - 回合 \(currentRound), 剩余次数 \(spinsRemaining), 拥有\(diceCount)个骰子")
        
        isSpinning = true
        gamePhase = .spinning
        totalEarnings = 0
        currentRoundMinedCells = []
        
        // 掷多个骰子并求和
        var totalPoints = 0
        for i in 1...diceCount {
            let point = Int.random(in: 1...6)
            totalPoints += point
            print("🎲 [骰子\(i)] 点数: \(point)")
        }
        diceResult = totalPoints
        currentDiceCount = diceCount // 更新UI显示
        print("🎲 [掷骰子] 总点数: \(diceResult)")
        
        // 显示骰子动画
        showDiceAnimation = true
        
        // 模拟骰子滚动动画（0.8秒旋转 + 0.5秒显示结果）
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.3) {
            // 隐藏骰子动画
            self.showDiceAnimation = false
        }
        
        // 1.5秒后执行挖矿
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            // 挖矿（翻开所有格子）
            self.mineRandomCells(count: self.diceResult)
            
            // 显示浪费提示（如果有）
            let minedCount = self.currentRoundMinedCells.count
            let wastedCount = self.diceResult - minedCount
            if wastedCount > 0 {
                print("⚠️ [挖矿] 浪费了\(wastedCount)次挖矿机会")
            }
            
            print("⏸️ [挖矿完成] 所有格子已翻开，等待1秒后开始结算动画")
            
            // 等待1秒，让玩家看清所有翻开的格子
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                // 开始结算流程（包含动画）
                // 注意：金币更新、旋转次数减少、游戏流程控制都已移到 finishSettlement 中
                print("🎬 [开始结算] 1秒等待完成，开始逐个结算")
                self.calculateEarnings()
            }
        }
    }
    
    /// 随机挖开格子（只在未开采的矿石上挖，不够则浪费）
    private func mineRandomCells(count: Int) {
        // **新功能：检查是否需要翻倍挖矿数量**
        var finalCount = count
        var doubleDigTriggered = false

        // 这里简化处理：如果当前有双倍挖矿效果，数量翻倍
        // 实际应该在效果处理中标记，这里暂时使用一个简单的检查
        // TODO: 更精确的实现应该在SymbolEffectProcessor中处理

        // 获取所有未挖开的格子索引
        let unminedIndices = slotMachine.enumerated()
            .filter { !$0.element.isMined }
            .map { $0.offset }

        // 确定实际要挖的数量（不超过剩余格子数）
        let actualCount = min(finalCount, unminedIndices.count)
        let wastedCount = finalCount - actualCount

        // 随机选择要挖的格子
        let selectedIndices = Array(unminedIndices.shuffled().prefix(actualCount))

        print("⛏️ [挖矿规则] 只在未开采矿石上挖矿")
        print("⛏️ [挖矿] 骰子点数: \(finalCount), 未挖格子数: \(unminedIndices.count), 实际挖开: \(actualCount)个")

        if doubleDigTriggered {
            print("⚡ [挖矿翻倍] 速之神效果触发，挖矿数量翻倍！")
        }

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
        print("🎰 [调试] 符号池内容: \(symbolPool.map { $0.icon + $0.name })")
        
        // 清空所有格子符号
        for index in 0..<slotCount {
            slotMachine[index].symbol = nil
        }
        
        if symbolPool.isEmpty {
            print("🎰 [生成结果] 符号池为空，全部空格子")
            return
        }
        
        // 过滤掉不应该出现在矿洞里的符号（女忍者和男忍者）
        let mineableSymbols = symbolPool.filter { symbol in
            symbol.name != "女忍者" && symbol.name != "男忍者"
        }
        
        if mineableSymbols.isEmpty {
            print("🎰 [生成结果] 符号池中只有忍者，全部空格子")
            return
        }
        
        // 特殊规则：魔法袋在矿洞里最多只出现一个
        // 先分离魔法袋和其他符号
        let magicBags = mineableSymbols.filter { $0.name == "魔法袋" }
        let otherSymbols = mineableSymbols.filter { $0.name != "魔法袋" }
        
        // 构建可选择的符号列表：最多1个魔法袋 + 其他符号
        var availableForSelection: [Symbol] = []
        if !magicBags.isEmpty {
            // 随机选择一个魔法袋（如果符号池中有多个）
            availableForSelection.append(magicBags.randomElement()!)
        }
        availableForSelection.append(contentsOf: otherSymbols)
        
        // 从可选择的符号中随机选择填满棋盘
        let targetSymbolCount = min(availableForSelection.count, slotCount)
        let symbolsToShow = Array(availableForSelection.shuffled().prefix(targetSymbolCount))
        
        if magicBags.count > 1 {
            print("🎰 [特殊规则] 符号池中有\(magicBags.count)个魔法袋，矿洞中最多只出现1个")
        }
        
        let ninjaCount = symbolPool.count - mineableSymbols.count
        if ninjaCount > 0 {
            print("🎰 [过滤] 已排除\(ninjaCount)个忍者符号（不会出现在矿洞里）")
        }
        print("🎰 [生成结果] 符号池总数量: \(symbolPool.count), 可挖符号: \(mineableSymbols.count), 棋盘格子数: \(slotCount)")
        print("🎰 [生成结果] 随机选择\(symbolsToShow.count)个符号: \(symbolsToShow.map { $0.icon + $0.name })")
        print("🎰 [生成策略] 从符号池随机选择符号填满棋盘，每个符号出现概率相等")
        
        // 随机分配到格子中
        let availablePositions = Array(0..<slotCount).shuffled()
        print("🎰 [调试] 随机位置: \(availablePositions.prefix(symbolsToShow.count))")
        
        for (index, symbol) in symbolsToShow.enumerated() {
            let position = availablePositions[index]
            slotMachine[position].symbol = symbol
            print("🎰 [调试] 放置符号: 位置\(position) <- \(symbol.icon)\(symbol.name)")
        }
        
        // 打印符号分布统计
        print("🎰 [生成结果] 棋盘符号分布:")
        for (index, symbol) in symbolsToShow.enumerated() {
            print("   \(index + 1). \(symbol.icon) \(symbol.name) (基础:\(symbol.baseValue)金币)")
        }
        print("🎰 [生成结果] 总计: \(symbolsToShow.count)个符号 + \(slotCount - symbolsToShow.count)个空格子 = \(slotCount)个格子")
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
        print("💰 [结算] 开始构建结算序列")
        
        // 清空结算日志
        settlementLogs.removeAll()
        settlementLogs.append("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        settlementLogs.append("🎯 开始结算 - 回合\(currentRound)")
        settlementLogs.append("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
        
        totalEarnings = 0
        settlementSequence.removeAll()
        
        // 收集本次挖出的所有符号（按队列顺序）
        var minedSymbols: [Symbol] = []
        
        // 构建结算序列：计算每个格子的收益
        for index in currentRoundMinedCells {
            guard index < slotMachine.count else { continue }
            
            let cell = slotMachine[index]
            
            if let symbol = cell.symbol {
                minedSymbols.append(symbol) // 添加到队列
                
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
                
                let value = symbol.calculateValue(adjacentSymbols: adjacentSymbols, effectProcessor: effectProcessor)
                
                // 添加到结算序列
                settlementSequence.append((cellIndex: index, symbol: symbol, earnings: value))
                
                let logMsg = "格子\(index): \(symbol.icon)\(symbol.name) = \(value)金币 (基础:\(symbol.baseValue), 相邻:\(adjacentSymbols.count))"
                print("💰 [基础收益] \(logMsg)")
                settlementLogs.append("💰 \(logMsg)")
            } else {
                // 空格子 +1分
                settlementSequence.append((cellIndex: index, symbol: nil, earnings: 1))
                
                let logMsg = "格子\(index): 空格子 = 1金币"
                print("💰 [基础收益] \(logMsg)")
                settlementLogs.append("💰 \(logMsg)")
            }
        }
        
        print("💰 [结算] 结算序列构建完成，共\(settlementSequence.count)个格子")
        
        // 开始播放结算动画序列
        playSettlementAnimation(minedSymbols: minedSymbols)
    }
    
    /// 播放结算动画序列
    private func playSettlementAnimation(minedSymbols: [Symbol]) {
        guard !settlementSequence.isEmpty else {
            // 没有格子需要结算，直接完成
            finishSettlement(minedSymbols: minedSymbols, basicEarnings: 0)
            return
        }
        
        print("🎬 [结算动画] 开始播放结算动画，共\(settlementSequence.count)个格子")
        isPlayingSettlement = true
        currentSettlingCellIndex = nil
        
        // 播放序列中的每一个格子动画
        playNextSettlementStep(currentStep: 0, minedSymbols: minedSymbols)
    }
    
    /// 播放下一个结算步骤
    private func playNextSettlementStep(currentStep: Int, minedSymbols: [Symbol]) {
        guard currentStep < settlementSequence.count else {
            // 所有格子结算完成
            print("🎬 [结算动画] 所有格子结算完成")
            finishBasicSettlement(minedSymbols: minedSymbols)
            return
        }
        
        let item = settlementSequence[currentStep]
        
        print("🎬 [结算动画] 步骤\(currentStep + 1)/\(settlementSequence.count): 格子\(item.cellIndex), 收益\(item.earnings)金币")
        
        // 设置当前正在结算的格子
        currentSettlingCellIndex = item.cellIndex
        currentSettlingCellEarnings = item.earnings
        
        // 累加金币
        withAnimation(.easeOut(duration: 0.3)) {
            totalEarnings += item.earnings
        }
        
        // 每个格子动画持续0.5秒，然后播放下一个
        let nextWork = DispatchWorkItem { [weak self] in
            self?.playNextSettlementStep(currentStep: currentStep + 1, minedSymbols: minedSymbols)
        }
        
        settlementTimer?.cancel()
        settlementTimer = nextWork
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: nextWork)
    }
    
    /// 完成基础结算，开始处理符号效果和哥布林buff
    private func finishBasicSettlement(minedSymbols: [Symbol]) {
        print("✅ [结算动画] 基础结算完成，总收益: \(totalEarnings)金币")
        
        // 清除当前结算格子标记
        currentSettlingCellIndex = nil
        
        // 记录基础收益
        let basicEarnings = totalEarnings
        
        // 添加一个短暂延迟，让玩家看清最后一个格子的动画
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            guard let self = self else { return }
            self.finishSettlement(minedSymbols: minedSymbols, basicEarnings: basicEarnings)
        }
    }
    
    /// 完成所有结算（符号效果 + 哥布林buff）
    private func finishSettlement(minedSymbols: [Symbol], basicEarnings: Int) {
        print("💰 [结算] 开始处理符号效果和哥布林buff")

        // **新功能：处理倍率效果**
        var multiplierEffects: [(symbol: Symbol, multiplier: Int)] = []
        var groupMultiplierEffects: [(symbol: Symbol, targetType: String, multiplier: Int)] = []

        // 预处理倍率效果（需要在计算基础收益后应用）
        for symbol in minedSymbols {
            if symbol.effectType == "conditional_multiplier" {
                if let triggerSymbol = symbol.effectParams["triggerSymbol"] as? String,
                   let multiplier = symbol.effectParams["multiplier"] as? Int,
                   minedSymbols.contains(where: { $0.name == triggerSymbol }) {

                    multiplierEffects.append((symbol: symbol, multiplier: multiplier))
                    print("✨ [倍率预处理] \(symbol.name)触发倍率: ×\(multiplier)")
                }
            } else if symbol.effectType == "group_multiplier" {
                if let targetType = symbol.effectParams["targetType"] as? String,
                   let multiplier = symbol.effectParams["multiplier"] as? Int {

                    groupMultiplierEffects.append((symbol: symbol, targetType: targetType, multiplier: multiplier))
                    print("👥 [群体倍率预处理] \(symbol.name)对\(targetType)类型应用倍率: ×\(multiplier)")
                }
            }
        }

        // 处理符号效果（会修改符号池）
        let effectBonus = effectProcessor.processMinedSymbols(
            minedSymbols: minedSymbols,
            symbolPool: &symbolPool,
            enableEffects: SymbolConfigManager.shared.isEffectsEnabled(),
            logCallback: { [weak self] log in
                self?.settlementLogs.append(log)
            }
        )
        totalEarnings += effectBonus
        
        // 更新骰子数量显示（如果挖到了骰子）
        currentDiceCount = effectProcessor.getDiceCount()

        // **新功能：应用倍率效果**
        var multiplierBonus = 0
        if !multiplierEffects.isEmpty || !groupMultiplierEffects.isEmpty {
            settlementLogs.append("\n✨ 开始应用倍率效果...")

            // 重新计算有倍率影响的收益
            for item in settlementSequence {
                if let symbol = item.symbol {
                    var newValue = item.earnings

                    // 应用条件倍率
                    for (multiplierSymbol, multiplier) in multiplierEffects {
                        if symbol.name == multiplierSymbol.name {
                            newValue = item.earnings * multiplier
                            multiplierBonus += (newValue - item.earnings)
                            settlementLogs.append("✨ \(symbol.name)倍率生效: \(item.earnings) × \(multiplier) = \(newValue)金币")
                        }
                    }

                    // 应用群体倍率
                    for (multiplierSymbol, targetType, multiplier) in groupMultiplierEffects {
                        if symbol.types.contains(targetType) {
                            newValue = item.earnings * multiplier
                            multiplierBonus += (newValue - item.earnings)
                            settlementLogs.append("👥 \(symbol.name)群体倍率生效: \(item.earnings) × \(multiplier) = \(newValue)金币")
                        }
                    }

                    // 更新结算序列
                    if let index = settlementSequence.firstIndex(where: { $0.cellIndex == item.cellIndex }) {
                        settlementSequence[index].earnings = newValue
                    }
                }
            }

            totalEarnings += multiplierBonus
            settlementLogs.append("✨ 倍率效果总奖励: +\(multiplierBonus) 金币\n")
        }

        // 应用哥布林buff效果（使用效果处理器的消除计数）
        if let goblin = selectedGoblin {
            settlementLogs.append("🎭 开始处理哥布林buff...")
        }
        let actualEliminatedCount = effectProcessor.getEliminatedSymbolCount()
        let goblinBonus = applyGoblinBuff(eliminatedSymbolCount: actualEliminatedCount)
        totalEarnings += goblinBonus
        if goblinBonus > 0 {
            settlementLogs.append("⚔️ 哥布林buff奖励: +\(goblinBonus) 金币 (消除了\(actualEliminatedCount)个符号)\n")
        }

        // 检查是否有丰收之神的翻倍效果
        var doubleRewardBonus = 0
        if effectProcessor.shouldDoubleReward() {
            let originalEarnings = totalEarnings
            doubleRewardBonus = originalEarnings // 翻倍部分 = 原收益
            totalEarnings *= 2 // 总收益翻倍
            effectProcessor.clearDoubleRewardFlag() // 清除标记
            settlementLogs.append("🌾 丰收之神效果：收益翻倍！+\(doubleRewardBonus) 金币\n")
            print("🌾 [丰收之神] 收益翻倍生效：原收益\(originalEarnings) × 2 = \(totalEarnings)金币")
        }
        
        let finalSummary = "💰 最终收益: \(totalEarnings) 金币 (基础\(basicEarnings) + 效果\(effectBonus) + 倍率\(multiplierBonus) + 哥布林\(goblinBonus)\(doubleRewardBonus > 0 ? " + 翻倍\(doubleRewardBonus)" : ""))"
        print(finalSummary)
        settlementLogs.append("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        settlementLogs.append(finalSummary)
        settlementLogs.append("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")

        // 结算动画完全结束
        isPlayingSettlement = false

        // 显示收益气泡
        showEarningsTip(text: "+\(totalEarnings)\(localizationManager.localized("earnings.coins"))")

        // 更新金币
        currentCoins += totalEarnings
        spinsRemaining -= 1

        print("💰 [结算完成] 当前金币: \(currentCoins), 剩余旋转: \(spinsRemaining)")

        // 等待收益气泡消失后再显示下一流程弹窗（2秒后）
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.3) { [weak self] in
            guard let self = self else { return }
            
            // 检查是否还有旋转次数
            if self.spinsRemaining > 0 {
                // 继续游戏，重置状态
                self.isSpinning = false
                self.gamePhase = .result
            } else {
                // 本轮结束，检查是否能支付房租
                self.checkRentPayment()
            }
        }
    }
    
    /// 应用哥布林buff效果（基于配置文件）
    private func applyGoblinBuff(eliminatedSymbolCount: Int) -> Int {
        guard let goblin = selectedGoblin else { return 0 }
        
        // 检查是否启用buff效果
        guard GoblinConfigManager.shared.isBuffEffectsEnabled() else {
            print("⚠️ [哥布林Buff] buff效果已在配置中禁用")
            return 0
        }
        
        var bonusCoins = 0
        
        // 根据buffType处理不同的buff
        switch goblin.buffType {
        case "on_symbol_eliminate": // 勇者哥布林：每有一个符号被消除，则+N金币
            bonusCoins = Int(goblin.buffValue) * eliminatedSymbolCount
            if bonusCoins > 0 {
                print("\(goblin.icon) [\(goblin.name)] 消除\(eliminatedSymbolCount)个符号，额外获得\(bonusCoins)金币")
            }
            
        case "extra_symbol_choice": // 工匠哥布林：每回合增加N次获得符号3选1的机会
            print("\(goblin.icon) [\(goblin.name)] buff将在回合结束时生效")
            
        case "dice_probability_boost": // 赌徒哥布林：挖到骰子概率翻N倍
            print("\(goblin.icon) [\(goblin.name)] 骰子概率提升\(goblin.buffValue)倍效果已激活")
            
        case "soldier_bonus": // 国王哥布林：每有一个士兵，额外获得N金币
            let soldierCount = symbolPool.filter { $0.name == "士兵" }.count
            bonusCoins = soldierCount * Int(goblin.buffValue)
            if soldierCount > 0 {
                print("\(goblin.icon) [\(goblin.name)] 符号池有\(soldierCount)个士兵，额外获得\(bonusCoins)金币")
            }
            
        case "magic_bag_fill": // 巫师哥布林：每回合挖矿之前随机填充N个魔法袋
            // 这个buff会在每回合开始时添加到符号池，不在这里处理
            print("\(goblin.icon) [\(goblin.name)] 魔法袋buff将在挖矿前生效")
            
        default:
            print("⚠️ [哥布林Buff] 未知的buff类型: \(goblin.buffType)")
        }
        
        return bonusCoins
    }
    
    /// 应用巫师哥布林buff：每回合挖矿之前随机填充魔法袋
    private func applyWizardGoblinBuff() {
        guard let goblin = selectedGoblin,
              goblin.buffType == "magic_bag_fill",
              GoblinConfigManager.shared.isBuffEffectsEnabled() else {
            return
        }
        
        // 检查本回合是否已添加过魔法袋（防止重复添加）
        if wizardBuffUsedThisRound {
            return
        }
        
        let magicBagCount = Int(goblin.buffValue)
        guard magicBagCount > 0 else { return }
        
        // 获取魔法袋符号
        guard let magicBag = SymbolLibrary.getSymbol(byName: "魔法袋") else {
            print("⚠️ [巫师哥布林] 找不到魔法袋符号")
            return
        }
        
        // 添加魔法袋到符号池
        for _ in 0..<magicBagCount {
            symbolPool.append(magicBag)
        }
        
        // 标记本回合已使用
        wizardBuffUsedThisRound = true
        
        print("🧙 [巫师哥布林] 每回合挖矿之前添加\(magicBagCount)个魔法袋到符号池")
        print("🧙 [巫师哥布林] 当前符号池: \(symbolPool.map { $0.icon + $0.name })")
    }
    
    /// 重置矿石状态（新阶段开始时调用）
    private func resetMineState() {
        for index in 0..<slotMachine.count {
            slotMachine[index].isMined = false
        }
        currentRoundMinedCells = []
        diceResult = 0
        
        // 重置效果处理器的回合状态
        effectProcessor.resetRoundState()
        
        print("🔄 [重置] 所有格子重新被矿石覆盖，效果状态已重置")
    }
    
    /// 检查房租支付
    private func checkRentPayment() {
        if spinsRemaining <= 0 {
            print("🏠 [房租] 需要支付房租: \(rentAmount) 金币, 当前拥有: \(currentCoins) 金币")
            gamePhase = .payingRent

            if currentCoins >= rentAmount {
                // 支付成功
                currentCoins -= rentAmount
                totalRentPaid += rentAmount // 累计已支付的房租
                currentRound += 1
                spinsRemaining = configManager.getGameSettings().spinsPerRound
                rentAmount = configManager.getRentAmount(for: currentRound)

                // 重置旋转状态，确保可以继续游戏
                isSpinning = false

                // 重置巫师哥布林buff标记（新回合开始）
                wizardBuffUsedThisRound = false

                print("✅ [房租] 支付成功！进入回合 \(currentRound)")

                // **新功能：回合开始处理**
                // 添加回合开始日志到调试面板
                settlementLogs.append("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
                settlementLogs.append("🌅 回合开始 - 回合\(currentRound)")
                settlementLogs.append("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
                settlementLogs.append("🏠 支付房租: -\(rentAmount) 金币")
                
                let roundStartBonus = effectProcessor.processRoundStart(symbolPool: &symbolPool)
                currentCoins += roundStartBonus
                
                // 检查是否有回合开始奖励和下回合奖励
                let nextRoundBonus = effectProcessor.processNextRoundBonuses(symbolPool: &symbolPool)
                currentCoins += nextRoundBonus
                
                // 记录回合开始奖励到日志
                if roundStartBonus != 0 {
                    settlementLogs.append("🌅 回合开始效果: \(roundStartBonus > 0 ? "+" : "")\(roundStartBonus) 金币")
                } else {
                    settlementLogs.append("🌅 回合开始效果: 无")
                }
                
                // 记录下回合奖励到日志
                if nextRoundBonus != 0 {
                    settlementLogs.append("🔥 下回合奖励: \(nextRoundBonus > 0 ? "+" : "")\(nextRoundBonus) 金币")
                }
                
                // 计算总变化
                let totalChange = roundStartBonus + nextRoundBonus - rentAmount
                settlementLogs.append("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
                settlementLogs.append("💰 回合开始总变化: \(totalChange > 0 ? "+" : "")\(totalChange) 金币 (房租-\(rentAmount) + 回合开始\(roundStartBonus > 0 ? "+" : "")\(roundStartBonus) + 下回合奖励\(nextRoundBonus > 0 ? "+" : "")\(nextRoundBonus))")
                settlementLogs.append("💰 当前金币: \(currentCoins) 金币")
                settlementLogs.append("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
                
                var hasTip = false
                if roundStartBonus != 0 {
                    showEarningsTip(text: "\(localizationManager.localized("earnings.round_start")): \(roundStartBonus > 0 ? "+" : "")\(roundStartBonus)\(localizationManager.localized("earnings.coins"))")
                    hasTip = true
                    print("🌅 [回合开始] 回合开始效果奖励: \(roundStartBonus > 0 ? "+" : "")\(roundStartBonus)金币")
                }
                
                if nextRoundBonus != 0 {
                    // 如果有回合开始奖励，等待它消失后再显示下回合奖励
                    let delay = hasTip ? 2.3 : 0.0
                    DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
                        guard let self = self else { return }
                        self.showEarningsTip(text: "\(self.localizationManager.localized("earnings.next_round_bonus")): \(nextRoundBonus > 0 ? "+" : "")\(nextRoundBonus)\(self.localizationManager.localized("earnings.coins"))")
                    }
                    hasTip = true
                    print("🔥 [下回合奖励] 生效奖励: \(nextRoundBonus > 0 ? "+" : "")\(nextRoundBonus)金币")
                }
                
                // 如果有奖励气泡，等待消失后再显示符号选择；否则直接显示
                if hasTip {
                    // 等待最后一个气泡消失（2.3秒）
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.3) { [weak self] in
                        self?.showSymbolSelectionPhase()
                    }
                } else {
                    // 没有奖励气泡，直接显示符号选择
                    showSymbolSelectionPhase()
                }
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

    /// **新功能：回合开始处理**
    private func processRoundStart() {
        print("🌅 [回合开始] 处理回合\(currentRound)开始效果")

        // 处理回合开始效果（花精合成、元素收集、回合开始惩罚/buff等）
        let roundStartBonus = effectProcessor.processRoundStart(symbolPool: &symbolPool)
        currentCoins += roundStartBonus

        if roundStartBonus != 0 {
            showEarningsTip(text: "\(localizationManager.localized("earnings.round_start")): \(roundStartBonus > 0 ? "+" : "")\(roundStartBonus)\(localizationManager.localized("earnings.coins"))")
            print("🌅 [回合开始] 回合开始效果奖励: \(roundStartBonus > 0 ? "+" : "")\(roundStartBonus)金币")
        }

        // 处理下回合奖励
        let nextRoundBonus = effectProcessor.processNextRoundBonuses(symbolPool: &symbolPool)
        currentCoins += nextRoundBonus

        if nextRoundBonus != 0 {
            showEarningsTip(text: "\(localizationManager.localized("earnings.next_round_bonus")): \(nextRoundBonus > 0 ? "+" : "")\(nextRoundBonus)\(localizationManager.localized("earnings.coins"))")
            print("🔥 [下回合奖励] 生效奖励: \(nextRoundBonus > 0 ? "+" : "")\(nextRoundBonus)金币")
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
    
    // 记录本回合是否已添加魔法袋（防止重复添加）
    private var wizardBuffUsedThisRound = false
    
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
        
        // 应用巫师哥布林buff：每回合挖矿之前随机填充魔法袋（在符号选择完成后、挖矿之前）
        applyWizardGoblinBuff()
        
        // 重新生成棋盘符号
        generateSlotResults()
        
        // 重置矿石状态
        resetMineState()
        
        // 符号选择完成后，等待玩家手动点击掷骰子按钮
        print("🎮 [选择完成] 符号已添加，新阶段开始，等待玩家掷骰子")
        print("🎮 [调试] 当前状态 - spinsRemaining: \(spinsRemaining), isSpinning: \(isSpinning), gamePhase: \(gamePhase)")
        gamePhase = .result
        print("🎮 [调试] 设置后状态 - spinsRemaining: \(spinsRemaining), isSpinning: \(isSpinning), gamePhase: \(gamePhase)")
    }
    
    /// 手动掷骰子挖矿
    func manualSpin() {
        print("🎲 [手动掷骰子] 玩家点击掷骰子按钮")
        print("🎲 [调试] 按钮状态检查 - spinsRemaining: \(spinsRemaining), isSpinning: \(isSpinning), gamePhase: \(gamePhase)")
        if spinsRemaining > 0 && !isSpinning && gamePhase == .result {
            rollDice()
        } else {
            print("🎲 [调试] 按钮被禁用 - spinsRemaining > 0: \(spinsRemaining > 0), !isSpinning: \(!isSpinning), gamePhase == .result: \(gamePhase == .result)")
        }
    }
    
    /// 游戏结束
    private func gameOver(message: String) {
        print("🎮 [游戏结束] \(message)")

        // 更新个人最佳记录
        if currentRound > bestRound {
            bestRound = currentRound
            print("🏆 [新记录] 最佳回合数更新: \(bestRound)")
        }

        let totalCoins = accumulatedCoins
        if totalCoins > bestCoins {
            bestCoins = totalCoins
            print("💰 [新记录] 历史最多金币更新: \(bestCoins)")
        }

        gamePhase = .gameOver
        gameOverMessage = message
        showGameOver = true
    }
    
    /// 重新开始游戏（更换难度时调用，保留哥布林选择）
    func restartGame() {
        print("🔄 [重新开始] 重置游戏（保留哥布林）")
        // 不重置哥布林选择，但需要重新进行符号选择
        craftsmanBuffUsed = false
        
        // 重置效果处理器
        effectProcessor.resetRoundState()
        effectProcessor.resetDiceCount()
        
        // 重置游戏状态（顺序很重要！）
        totalEarnings = 0
        totalRentPaid = 0 // 重置累计房租
        currentRound = 1  // 先设置回合数
        isSpinning = false  // 确保没有在掷骰子
        showGameOver = false  // 隐藏失败界面
        
        // 重新加载游戏设置（会使用currentRound来计算房租）
        loadGameSettings()
        
        // 重置符号池，使用起始符号
        symbolPool = SymbolLibrary.startingSymbols
        print("🎮 [重新开始] 重置符号池: \(symbolPool.map { $0.name })")
        
        // 重新初始化老虎机
        slotMachine = (0..<slotCount).map { _ in SlotCell(symbol: nil, isMined: false) }
        generateSlotResults()
        
        // 进入符号选择阶段，让玩家重新选择符号
        gamePhase = .selectingSymbol
        print("🎮 [重新开始] 游戏已重置，开始符号选择流程")
        
        // 显示初始符号选择
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.showInitialSymbolSelection()
        }
    }
    
    /// 完全重置游戏（包括哥布林选择）
    func completelyRestartGame() {
        print("🔄 [完全重新开始] 重置游戏和哥布林")
        // 重新选择哥布林
        goblinSelectionCompleted = false
        selectedGoblin = nil
        showGoblinSelection = false
        craftsmanBuffUsed = false
        
        // 重置累计统计
        totalRentPaid = 0
        
        // 重置效果处理器
        effectProcessor.resetRoundState()
        effectProcessor.resetDiceCount()
    }
    
    /// 退出游戏，返回首页
    func exitToHome() {
        print("🚪 [退出游戏] 返回首页")
        print("📊 [退出统计] 当前回合: \(currentRound), 当前金币: \(currentCoins), 已支付房租: \(totalRentPaid)")
        
        // 在退出前更新最佳记录（如果当前游戏有更好的成绩）
        let previousBestRound = bestRound
        if currentRound > bestRound {
            bestRound = currentRound
            print("🏆 [退出时更新] 最佳回合数: \(previousBestRound) → \(bestRound)")
        } else {
            print("🏆 [退出时检查] 当前回合\(currentRound)未超过最佳\(bestRound)")
        }
        
        let totalCoins = accumulatedCoins
        let previousBestCoins = bestCoins
        print("💰 [退出统计] 累计金币: \(totalCoins) (当前\(currentCoins) + 已支付房租\(totalRentPaid))")
        if totalCoins > bestCoins {
            bestCoins = totalCoins
            print("💰 [退出时更新] 历史最多金币: \(previousBestCoins) → \(bestCoins)")
        } else {
            print("💰 [退出时检查] 累计金币\(totalCoins)未超过最佳\(bestCoins)")
        }
        
        // 重置游戏状态
        goblinSelectionCompleted = false
        showGoblinSelection = false
        showGameOver = false
        showSymbolSelection = false
        isSpinning = false
        gamePhase = .selectingSymbol
        
        // 重置效果处理器
        effectProcessor.resetRoundState()
        effectProcessor.resetDiceCount()
        
        // 重置buff标记
        wizardBuffUsedThisRound = false
        craftsmanBuffUsed = false
        
        // 重新启动体力恢复定时器（返回首页后需要继续恢复体力）
        startStaminaRecoveryTimer()
        
        // 注意：不重置哥布林选择，这样返回首页后可以继续使用
        // 也不重置最佳记录，这些应该保留
        print("✅ [退出完成] 已返回首页")
    }
    
    /// 统一的气泡显示方法（支持流畅切换）
    private func showTip(_ tipType: TipType) {
        // 取消之前的定时器
        tipTimer?.cancel()
        
        // 如果当前有气泡正在显示，先触发消失动画
        if currentTipType != nil {
            // 立即触发消失动画
            isTipDismissing = true
            
            // 在主线程更新UI状态
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                
                withAnimation(.easeOut(duration: 0.3)) {
                    self.showEarningsTip = false
                    self.showGoblinBuffTip = false
                    self.showSymbolBuffTip = false
                }
                
                // 等待消失动画完成（0.3秒），然后显示新气泡
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    self.isTipDismissing = false
                    self._displayTip(tipType)
                }
            }
        } else {
            // 没有当前气泡，直接显示
            _displayTip(tipType)
        }
    }
    
    /// 内部方法：实际显示气泡
    private func _displayTip(_ tipType: TipType) {
        // 确保在主线程更新UI
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            // 先隐藏所有气泡（确保状态干净）
            self.showEarningsTip = false
            self.showGoblinBuffTip = false
            self.showSymbolBuffTip = false
            self.selectedSymbolForTip = nil
            
            // 短暂延迟后显示新气泡，确保动画流畅
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                // 根据类型显示对应的气泡
                switch tipType {
                case .earnings(let text):
                    self.earningsTipText = text
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                        self.showEarningsTip = true
                    }
                    print("💰 [气泡] 显示收益气泡: \(text)")
                    
                case .goblinBuff:
                    guard self.selectedGoblin != nil else { return }
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                        self.showGoblinBuffTip = true
                    }
                    print("🎭 [气泡] 显示哥布林buff气泡")
                    
                case .symbolBuff(let symbol):
                    self.selectedSymbolForTip = symbol
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                        self.showSymbolBuffTip = true
                    }
                    print("📝 [气泡] 显示符号buff气泡: \(symbol.name)")
                }
                
                self.currentTipType = tipType
                
                // 创建新的定时器，2秒后自动隐藏
                let workItem = DispatchWorkItem { [weak self] in
                    self?.dismissTip()
                }
                self.tipTimer = workItem
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0, execute: workItem)
            }
        }
    }
    
    /// 隐藏气泡（触发消失动画）
    private func dismissTip() {
        guard currentTipType != nil else { return }
        
        // 触发消失动画
        isTipDismissing = true
        
        // 使用主线程确保UI更新
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            withAnimation(.easeOut(duration: 0.3)) {
                self.showEarningsTip = false
                self.showGoblinBuffTip = false
                self.showSymbolBuffTip = false
            }
            
            // 动画完成后清理
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                self.isTipDismissing = false
                self.currentTipType = nil
                self.selectedSymbolForTip = nil
            }
        }
    }
    
    /// 显示收益气泡提示
    private func showEarningsTip(text: String) {
        showTip(.earnings(text))
    }
    
    /// 显示哥布林buff气泡
    func showGoblinBuffInfo() {
        guard selectedGoblin != nil else { return }
        showTip(.goblinBuff)
    }
    
    /// 显示符号buff气泡
    func showSymbolBuffInfo(for symbol: Symbol) {
        showTip(.symbolBuff(symbol))
    }
    
    // MARK: - 测试功能
    
    /// 切换棋盘透明模式
    func toggleTransparentMode() {
        transparentMode.toggle()
        print("🔍 [测试模式] 棋盘透明模式: \(transparentMode ? "开启" : "关闭")")
    }
    
    /// 显示调试面板
    func toggleDebugPanel() {
        showDebugPanel.toggle()
        print("🔍 [测试模式] 调试面板: \(showDebugPanel ? "显示" : "隐藏")")
    }
    
    /// 获取当前棋盘状态（用于调试）
    func getBoardDebugInfo() -> String {
        var info = "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n"
        info += "🎲 当前棋盘状态 (5x5)\n"
        info += "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n\n"
        
        for row in 0..<5 {
            for col in 0..<5 {
                let index = row * 5 + col
                let cell = slotMachine[index]
                
                if let symbol = cell.symbol {
                    info += "\(symbol.icon)"
                } else {
                    info += "⚪"
                }
                info += " "
            }
            info += "\n"
        }
        
        info += "\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n"
        info += "📊 符号统计\n"
        info += "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n"
        
        let symbols = slotMachine.compactMap { $0.symbol }
        let groupedSymbols = Dictionary(grouping: symbols) { $0.name }
        
        for (name, symbols) in groupedSymbols.sorted(by: { $0.key < $1.key }) {
            info += "\(symbols.first!.icon) \(name): \(symbols.count)个\n"
        }
        
        let emptyCount = slotMachine.filter { $0.symbol == nil }.count
        info += "⚪ 空格子: \(emptyCount)个\n"
        
        return info
    }
    
    // MARK: - 体力系统
    
    /// 加载体力数据（从UserDefaults）
    private func loadStamina() {
        stamina = UserDefaults.standard.integer(forKey: "stamina")
        if stamina == 0 {
            stamina = maxStamina // 首次启动，设置为满体力
        }
        
        // 加载上次保存的时间
        if let savedTime = UserDefaults.standard.object(forKey: "lastStaminaUpdateTime") as? Date {
            // 计算应该恢复的体力
            let timePassed = Date().timeIntervalSince(savedTime)
            let staminaToRecover = Int(timePassed / staminaRecoveryInterval)
            
            if staminaToRecover > 0 {
                stamina = min(maxStamina, stamina + staminaToRecover)
                print("⚡ [体力恢复] 离线恢复\(staminaToRecover)点体力，当前: \(stamina)")
            }
        }
        
        saveStamina()
        print("⚡ [体力加载] 当前体力: \(stamina)/\(maxStamina)")
    }
    
    /// 保存体力数据（到UserDefaults）
    private func saveStamina() {
        UserDefaults.standard.set(stamina, forKey: "stamina")
        UserDefaults.standard.set(Date(), forKey: "lastStaminaUpdateTime")
    }
    
    /// 启动体力恢复定时器
    func startStaminaRecoveryTimer() {
        // 停止之前的定时器
        staminaTimer?.invalidate()
        
        // 如果体力已满，不需要定时器
        if stamina >= maxStamina {
            nextStaminaRecoveryTime = nil
            return
        }
        
        // 计算下次恢复时间
        let timeSinceLastUpdate = Date().timeIntervalSince(
            UserDefaults.standard.object(forKey: "lastStaminaUpdateTime") as? Date ?? Date()
        )
        let timeUntilNextRecovery = staminaRecoveryInterval - timeSinceLastUpdate.truncatingRemainder(dividingBy: staminaRecoveryInterval)
        nextStaminaRecoveryTime = Date().addingTimeInterval(timeUntilNextRecovery)
        
        // 创建定时器，每5分钟检查一次
        staminaTimer = Timer.scheduledTimer(withTimeInterval: staminaRecoveryInterval, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            self.recoverStamina()
        }
        
        print("⚡ [体力定时器] 已启动，下次恢复时间: \(nextStaminaRecoveryTime?.description ?? "未知")")
    }
    
    /// 恢复体力
    private func recoverStamina() {
        guard stamina < maxStamina else {
            staminaTimer?.invalidate()
            nextStaminaRecoveryTime = nil
            return
        }
        
        stamina = min(maxStamina, stamina + 1)
        saveStamina()
        print("⚡ [体力恢复] 恢复1点体力，当前: \(stamina)/\(maxStamina)")
        
        // 更新下次恢复时间
        nextStaminaRecoveryTime = Date().addingTimeInterval(staminaRecoveryInterval)
        
        // 如果体力已满，停止定时器
        if stamina >= maxStamina {
            staminaTimer?.invalidate()
            nextStaminaRecoveryTime = nil
        }
    }
    
    /// 获取下次体力恢复的剩余时间（秒）
    func getStaminaRecoveryTimeRemaining() -> Int {
        // 如果体力已满，返回0
        if stamina >= maxStamina {
            return 0
        }
        
        // 如果有设置下次恢复时间，使用它
        if let nextTime = nextStaminaRecoveryTime {
            let remaining = nextTime.timeIntervalSinceNow
            return max(0, Int(remaining))
        }
        
        // 否则根据上次更新时间计算
        if let lastUpdateTime = UserDefaults.standard.object(forKey: "lastStaminaUpdateTime") as? Date {
            let timeSinceLastUpdate = Date().timeIntervalSince(lastUpdateTime)
            let timeUntilNextRecovery = staminaRecoveryInterval - timeSinceLastUpdate.truncatingRemainder(dividingBy: staminaRecoveryInterval)
            return max(0, Int(timeUntilNextRecovery))
        }
        
        // 默认返回5分钟
        return Int(staminaRecoveryInterval)
    }
    
    // MARK: - 钻石系统
    
    /// 加载钻石数据（从UserDefaults）
    private func loadDiamonds() {
        diamonds = UserDefaults.standard.integer(forKey: "diamonds")
        print("💎 [钻石加载] 当前钻石: \(diamonds)")
    }
    
    /// 保存钻石数据（到UserDefaults）
    private func saveDiamonds() {
        UserDefaults.standard.set(diamonds, forKey: "diamonds")
    }
    
    /// 添加钻石
    func addDiamonds(_ amount: Int) {
        diamonds += amount
        saveDiamonds()
        print("💎 [钻石] 添加\(amount)钻石，当前: \(diamonds)")
    }
    
    /// 消费钻石
    func spendDiamonds(_ amount: Int) -> Bool {
        guard diamonds >= amount else {
            print("💎 [钻石] 钻石不足，需要\(amount)，当前: \(diamonds)")
            return false
        }
        diamonds -= amount
        saveDiamonds()
        print("💎 [钻石] 消费\(amount)钻石，剩余: \(diamonds)")
        return true
    }
    
    /// 购买体力
    func purchaseStamina(amount: Int, cost: Int) -> Bool {
        guard spendDiamonds(cost) else {
            return false
        }
        stamina = min(maxStamina, stamina + amount)
        saveStamina()
        print("⚡ [购买体力] 购买\(amount)体力，消耗\(cost)钻石，当前体力: \(stamina)/\(maxStamina)")
        return true
    }
    
    /// 解锁哥布林（使用钻石）
    func unlockGoblin(goblinId: Int, cost: Int) -> Bool {
        guard spendDiamonds(cost) else {
            return false
        }
        unlockedGoblinIds.insert(goblinId)
        print("🎭 [解锁哥布林] 解锁ID: \(goblinId)，消耗\(cost)钻石")
        return true
    }
    
    // MARK: - 签到系统
    
    /// 加载签到状态（从UserDefaults）
    private func loadSignInStatus() {
        signInDay = UserDefaults.standard.integer(forKey: "signInDay")
        if signInDay == 0 {
            signInDay = 1 // 默认第一天
        }
        
        if let savedDate = UserDefaults.standard.object(forKey: "lastSignInDate") as? Date {
            lastSignInDate = savedDate
            checkSignInStatus()
        } else {
            canSignInToday = true
        }
        
        print("📅 [签到系统] 当前签到天数: \(signInDay), 可签到: \(canSignInToday)")
    }
    
    /// 保存签到状态（到UserDefaults）
    private func saveSignInStatus() {
        UserDefaults.standard.set(signInDay, forKey: "signInDay")
        if let date = lastSignInDate {
            UserDefaults.standard.set(date, forKey: "lastSignInDate")
        }
    }
    
    /// 检查签到状态（判断是否跨天）
    private func checkSignInStatus() {
        let calendar = Calendar.current
        let now = Date()
        
        if let lastDate = lastSignInDate {
            // 如果今天已经签到过，则不可签到
            if calendar.isDateInToday(lastDate) {
                canSignInToday = false
            } else {
                // 跨天了，可以签到
                canSignInToday = true
                
                // 如果距离上次签到超过1天，重置到第1天
                let daysSinceLastSignIn = calendar.dateComponents([.day], from: lastDate, to: now).day ?? 0
                if daysSinceLastSignIn > 1 {
                    signInDay = 1
                    saveSignInStatus()
                    print("📅 [签到系统] 超过1天未签到，重置到第1天")
                }
            }
        } else {
            canSignInToday = true
        }
    }
    
    /// 启动签到状态检查定时器（每分钟检查一次，检测跨天）
    private func startSignInStatusTimer() {
        signInTimer?.invalidate()
        
        // 每分钟检查一次
        signInTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            self?.checkSignInStatus()
        }
    }
    
    /// 执行签到
    func performSignIn() -> Bool {
        guard canSignInToday else {
            print("📅 [签到] 今日已签到")
            return false
        }
        
        // 记录签到
        lastSignInDate = Date()
        canSignInToday = false
        
        // 获取当前天的奖励
        let reward = getSignInReward(for: signInDay)
        
        // 发放奖励
        switch reward.type {
        case .diamonds:
            addDiamonds(reward.amount)
        case .coins:
            currentCoins += reward.amount
        case .stamina:
            stamina = min(maxStamina, stamina + reward.amount)
            saveStamina()
        }
        
        // 更新签到天数（循环）
        signInDay = (signInDay % 7) + 1
        
        saveSignInStatus()
        
        print("📅 [签到] 第\(signInDay == 1 ? 7 : signInDay - 1)天签到成功，获得奖励: \(reward.description)")
        
        return true
    }
    
    /// 获取指定天的签到奖励
    func getSignInReward(for day: Int) -> SignInReward {
        // 7日循环奖励配置
        let rewards: [SignInReward] = [
            SignInReward(day: 1, type: .diamonds, amount: 10, description: "10 💎"),
            SignInReward(day: 2, type: .coins, amount: 50, description: "50 💰"),
            SignInReward(day: 3, type: .diamonds, amount: 20, description: "20 💎"),
            SignInReward(day: 4, type: .stamina, amount: 30, description: "30 ⚡"),
            SignInReward(day: 5, type: .diamonds, amount: 30, description: "30 💎"),
            SignInReward(day: 6, type: .coins, amount: 100, description: "100 💰"),
            SignInReward(day: 7, type: .diamonds, amount: 50, description: "50 💎")
        ]
        
        let index = (day - 1) % rewards.count
        return rewards[index]
    }
    
    /// 获取所有7天的奖励（用于显示）
    func getAllSignInRewards() -> [SignInReward] {
        return (1...7).map { getSignInReward(for: $0) }
    }
}

// MARK: - 签到奖励模型
struct SignInReward {
    let day: Int
    let type: RewardType
    let amount: Int
    let description: String
    
    enum RewardType {
        case diamonds
        case coins
        case stamina
        
        var icon: String {
            switch self {
            case .diamonds: return "💎"
            case .coins: return "💰"
            case .stamina: return "⚡"
            }
        }
    }
}

