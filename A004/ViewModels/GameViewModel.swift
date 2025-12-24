//
//  GameViewModel.swift
//  A004
//
//  游戏核心逻辑控制器
//

import Foundation
import SwiftUI
import GameKit

class GameViewModel: ObservableObject {
    // MARK: - 配置管理器
    private let configManager = GameConfigManager.shared
    private let effectProcessor = SymbolEffectProcessor()
    private let bondEffectProcessor = BondEffectProcessor()
    private let localizationManager = LocalizationManager.shared
    
    // MARK: - 游戏状态
    @Published var currentCoins: Int = 10 // 初始金币
    @Published var totalEarnings: Int = 0 // 本轮总收益
    @Published var currentRound: Int = 1 // 当前回合
    @Published var spinsRemaining: Int = 10 // 剩余旋转次数
    @Published var rentAmount: Int = 50 // 当前房租
    @Published var gamePhase: GamePhase = .selectingSymbol
    @Published var currentDiceCount: Int = 1 // 当前骰子数量
    @Published var displayedSpinInRound: Int = 1 // 显示的转动次数（只在骰子可转动时更新）
    
    // MARK: - 累计统计
    private var totalRentPaid: Int = 0 // 累计支付的房租总额
    var accumulatedCoins: Int { // 累计金币 = 当前金币 + 已支付的房租
        return currentCoins + totalRentPaid
    }

    // MARK: - 个人记录
    @Published var bestRound: Int = 0 // 最佳存活回合数
    @Published var bestSpinInRound: Int = 0 // 最佳转动次数（在最佳回合中的转动次数）
    @Published var bestDifficulty: String = "" // 最佳记录的难度
    @Published var bestCoins: Int = 0 // 历史最多金币

    // MARK: - 体力系统
    @Published var stamina: Int = 300 // 当前体力值
    @Published var nextStaminaRecoveryTime: Date? = nil // 下次体力恢复时间
    private var staminaTimer: Timer? = nil // 体力恢复定时器
    
    let maxStamina = 300 // 最大体力
    private let staminaPerGame = 1 // 每次游戏消耗体力
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
    @Published var showLetterView: Bool = false // 显示信页面
    @Published var goblinSelectionCompleted: Bool = false // 哥布林选择是否完成
    
    // MARK: - 符号池
    @Published var symbolPool: [Symbol] = [] { // 玩家拥有的符号池
        didSet {
            guard !suppressSymbolPoolReorder, !isReorderingSymbolPool else { return }
            let oldIDs = Set(oldValue.map { $0.id })
            let newSymbols = symbolPool.filter { !oldIDs.contains($0.id) }
            guard !newSymbols.isEmpty else { return }
            
            let newIDs = Set(newSymbols.map { $0.id })
            let remaining = symbolPool.filter { oldIDs.contains($0.id) }
            
            // 将新符号放到最前
            isReorderingSymbolPool = true
            symbolPool = newSymbols + remaining
            isReorderingSymbolPool = false
            
            // 记录闪光提示
            flashingSymbolIDs.formUnion(newIDs)
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { [weak self] in
                self?.flashingSymbolIDs.subtract(newIDs)
            }
        }
    }
    @Published var flashingSymbolIDs: Set<UUID> = [] // 新增符号闪光提示
    @Published var flashingBondIDs: Set<String> = [] // 新增羁绊闪光提示
    // 符号池重排控制
    private var suppressSymbolPoolReorder = false
    private var isReorderingSymbolPool = false
    
    // MARK: - 羁绊系统
    /// 获取当前激活的羁绊（优先使用BondBuffConfigManager，如果为空则使用BondConfigManager）
    var activeBonds: [BondBuff] {
        let bondBuffs = BondBuffConfigManager.shared.getActiveBondBuffs(symbolPool: symbolPool)
        let result: [BondBuff]
        if !bondBuffs.isEmpty {
            result = bondBuffs
        } else {
            // 向后兼容：如果没有BondBuff，使用旧的BondConfig
            result = BondConfigManager.shared.getActiveBonds(symbolPool: symbolPool).map { bond in
                BondBuff(
                    id: bond.id,
                    nameKey: bond.nameKey,
                    descriptionKey: bond.descriptionKey,
                    requiredSymbolIds: bond.requiredSymbolIds,
                    requiredType: nil,
                    requiredCount: nil,
                    cardColor: bond.backgroundColor
                )
            }
        }
        
        // 检测新出现的羁绊并添加闪光效果
        let currentBondIDs = Set(result.map { $0.id })
        let newBondIDs = currentBondIDs.subtracting(Set(previousActiveBondIDs))
        if !newBondIDs.isEmpty {
            print("✨ [羁绊闪光] 检测到新羁绊: \(newBondIDs)")
            flashingBondIDs.formUnion(newBondIDs)
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { [weak self] in
                self?.flashingBondIDs.subtract(newBondIDs)
            }
        }
        previousActiveBondIDs = currentBondIDs
        
        return result
    }
    private var previousActiveBondIDs: Set<String> = [] // 上一次激活的羁绊ID集合
    @Published var slotMachine: [SlotCell] = [] // 老虎机格子（20个）
    @Published var availableSymbols: [Symbol] = [] // 可选择的符号
    
    // MARK: - 道具
    @Published var items: [Item] = []
    
    // MARK: - UI状态
    @Published var isSpinning: Bool = false
    @Published var showSymbolSelection: Bool = false
    @Published var showGameTutorial: Bool = false // 显示游戏内新手引导
    private var hasCompletedFirstSymbolSelection: Bool = false // 是否完成了第一次符号选择
    @Published var showGameOver: Bool = false
    @Published var gameOverMessage: String = ""
    @Published private var extraSymbolChoicesPending: Int = 0
    // 额外掷骰/挖矿辅助标记
    private var autoMineAllUnopened: Bool = false
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
    
    // MARK: - 羁绊详情弹窗
    @Published var showBondDescription: Bool = false // 显示羁绊详情弹窗
    @Published var selectedBondForDescription: BondBuff? = nil // 当前选中查看的羁绊
    
    // MARK: - 测试模式
    @Published var showDebugPanel: Bool = false // 显示调试面板
    @Published var transparentMode: Bool = false // 棋盘透明模式
    @Published var settlementLogs: [String] = [] // 结算日志
    
    // MARK: - 掷骰子挖矿状态
    @Published var diceResult: Int = 0 // 骰子结果（总和）
    @Published var individualDiceResults: [Int] = [] // 每个骰子的单独结果
    @Published var currentRoundMinedCells: [Int] = [] // 本次挖到的格子索引
    @Published var showDiceAnimation: Bool = false // 是否显示骰子动画
    
    // MARK: - 结算动画状态
    @Published var isPlayingSettlement: Bool = false // 是否正在播放结算动画
    @Published var currentSettlingCellIndex: Int? = nil // 当前正在结算的格子索引
    @Published var currentSettlingCellEarnings: Int = 0 // 当前格子的收益金额
    @Published var settlementAnimationSpeed: Double = 1.0 // 结算动画速度倍数（1.0正常，2.0倍速）
    @Published var settlementSequence: [(cellIndex: Int, symbol: Symbol?, earnings: Int)] = [] // 结算序列
    private var settlementTimer: DispatchWorkItem? = nil // 结算动画定时器
    
    // MARK: - 气泡定时器（统一管理）
    private var tipTimer: DispatchWorkItem? = nil
    
    // MARK: - 常量
    private var slotCount: Int { // 老虎机格子数量（从配置文件读取）
        configManager.getGameSettings().slotCount
    }
    private let symbolChoiceCount = 3 // 每次可选符号数量
    
    // MARK: - 计算属性
    /// 当前回合内的转动次数（从1开始）
    /// 使用存储的属性，只在骰子可转动状态时更新
    var currentSpinInRound: Int {
        return displayedSpinInRound
    }
    
    /// 更新显示的转动次数（只在骰子可转动时调用）
    func updateDisplayedSpinInRoundIfCanRoll() {
        // 只有当骰子可转动时，才更新显示的转动次数
        if gamePhase == .result && !isSpinning && spinsRemaining > 0 {
            let spinsPerRound = configManager.getGameSettings().spinsPerRound
            displayedSpinInRound = spinsPerRound - spinsRemaining + 1
            print("🔄 [关卡计数] 更新显示转动次数: \(displayedSpinInRound)")
        }
    }
    
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
        displayedSpinInRound = 1 // 初始化显示为第1次转动
        
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
        
        // 不立即进入游戏，先显示信页面
        showGoblinSelection = false
        // 延迟一点设置，确保转场能正确触发
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.showLetterView = true
        }
    }
    
    /// 信页面关闭，正式进入游戏
    func onLetterDismissed() {
        print("📜 [游戏流程] 信页面关闭，正式进入游戏")
        showLetterView = false
        goblinSelectionCompleted = true
        
        // 开始新游戏
        startNewGame()
    }
    
    /// 开始新游戏
    func startNewGame() {
        print("🎮 [新游戏] 初始化游戏状态")
        
        // 重置第一次符号选择标记
        hasCompletedFirstSymbolSelection = false
        
        // 清空羁绊状态（特别是 classic tale）
        BondBuffRuntime.shared.activeTypeBonds.removeAll()
        print("🔄 [新游戏] 已清空羁绊状态")
        
        // 诊断：检查配置加载状态
        let configManager = SymbolConfigManager.shared
        let allSymbols = SymbolLibrary.allSymbols
        print("🔍 [诊断] 符号库总数: \(allSymbols.count)")
        
        // 检查关键符号
        if let deathSymbol = SymbolLibrary.getSymbol(byName: "死神") {
            print("🔍 [诊断] 死神符号: effectType=\(deathSymbol.effectType), effectParams=\(deathSymbol.effectParams)")
        } else {
            print("⚠️ [诊断] 找不到死神符号！")
        }
        
        if let merchantSymbol = SymbolLibrary.getSymbol(byName: "商人") {
            print("🔍 [诊断] 商人符号: effectType=\(merchantSymbol.effectType), effectParams=\(merchantSymbol.effectParams)")
        }
        
        if let childSymbol = SymbolLibrary.getSymbol(byName: "儿童") {
            print("🔍 [诊断] 儿童符号: effectType=\(childSymbol.effectType), effectParams=\(childSymbol.effectParams)")
        }
        
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
        
        // 重置羁绊闪光状态
        previousActiveBondIDs.removeAll()
        flashingBondIDs.removeAll()
        
        // 重置骰子数量为1
        effectProcessor.resetDiceCount()
        print("🎲 [新游戏] 重置骰子数量为1")
        
        // 初始化符号池（随机选择3个符号）
        suppressSymbolPoolReorder = true
        symbolPool = SymbolLibrary.startingSymbols
        suppressSymbolPoolReorder = false
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
        
        // 在生成阶段记录激活的羁绊（供后续流程使用）
        _ = bondEffectProcessor.processBondBuffs(symbolPool: &symbolPool, currentRound: currentRound)
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
        var results: [Int] = []
        for i in 1...diceCount {
            let point = Int.random(in: 1...6)
            totalPoints += point
            results.append(point)
            print("🎲 [骰子\(i)] 点数: \(point)")
        }

        diceResult = totalPoints
        individualDiceResults = results // 保存每个骰子的结果
        currentDiceCount = diceCount // 更新UI显示
        print("🎲 [掷骰子] 总点数: \(diceResult) (骰子数量: \(diceCount), 各骰子点数: \(individualDiceResults))")
        
        // 检查成就：第一次投掷到 6 点
        if results.contains(6) {
            let hasCompletedAchievement1 = UserDefaults.standard.bool(forKey: "achievement_achivement_1")
            if !hasCompletedAchievement1 {
                GameCenterManager.shared.unlockAchievement("achivement_1")
                print("🏆 [成就] 检测到第一次投掷到 6 点，解锁成就 achivement_1")
            }
        }
        
        // 激活的羁绊（用于掷骰/挖矿相关效果）
        let activeBondKeys = BondBuffConfigManager.shared.getActiveBondBuffs(symbolPool: symbolPool).map { $0.nameKey }
        
        // 人类10羁绊：每有人类，每次转动额外+50金币
        if activeBondKeys.contains("human_10_bond") {
            let humanCount = symbolPool.filter { $0.types.contains("human") }.count
            let bonus = humanCount * 50
            if bonus > 0 {
                currentCoins += bonus
                print("👥 [人类10羁绊] 人类\(humanCount)个，本次掷骰额外+\(bonus)金币")
            }
        }
        
        // tools_2：掷出1再转一次（给额外一次旋转机会）
        if activeBondKeys.contains("tools_2_bond"), results.contains(1) {
            spinsRemaining += 1
            print("🔧 [tools_2] 掷出1，额外+1次掷骰机会，剩余旋转：\(spinsRemaining)")
        }
        
        // tools_4：掷出6挖开未翻矿石
        if activeBondKeys.contains("tools_4_bond"), results.contains(6) {
            autoMineAllUnopened = true
            print("🔧 [tools_4] 掷出6，本次挖矿将自动挖开所有未翻矿石")
        }
        
        // **新功能：检查是否有速之神效果（本次挖出的符号数量翻倍）**
        // 注意：速之神效果应该在挖出时通过SymbolEffectProcessor处理，设置shouldDoubleDigCount标记
        // 这里检查标记，而不是直接检查符号池
        // 速之神效果应该在本次掷骰子之前就已经设置好标记（从上一次挖出速之神时）
        if effectProcessor.isDoubleDigCountEnabled() {
            let originalResult = diceResult
            diceResult *= 2
            print("⚡ [速之神] 挖矿数量翻倍: \(originalResult) → \(diceResult)")
            // **重要：立即清除标记，确保只生效一次**
            effectProcessor.clearDoubleDigCountFlag()
            print("✅ [速之神] 标记已清除，确保只生效一次")
        } else {
            // 调试：确认标记状态
            print("🔍 [速之神] 标记状态: false (未激活)")
        }
        
        // 验证：确保每个骰子的点数都在1-6范围内
        for (index, point) in individualDiceResults.enumerated() {
            if point < 1 || point > 6 {
                print("❌ [错误] 骰子\(index + 1)的点数异常: \(point) (应该在1-6范围内)")
            }
        }
        
        // 验证：如果只有一个骰子，结果不应该超过6（除非有速之神效果）
        if diceCount == 1 && totalPoints > 6 {
            print("⚠️ [警告] 单个骰子但点数超过6: \(totalPoints) (可能是速之神效果翻倍导致)")
        }
        
        // 显示骰子动画
        showDiceAnimation = true
        
        // 模拟骰子滚动动画（0.8秒旋转 + 0.8秒显示结果 + 0.3秒淡出）
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.9) {
            // 隐藏骰子动画
            self.showDiceAnimation = false
        }
        
        // 2.1秒后执行挖矿（在骰子动画完全消失后）
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.1) {
            // **新功能：挖矿前处理羁绊效果（如浣熊市）**
            self.processBondBuffsBeforeMining()
            
            // 挖矿（翻开所有格子）
            // 注意：速之神效果已经在rollDice中处理（检查符号池中的速之神）
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
    
    /// 随机挖开格子（如果不够则自动刷新棋盘，直到挖够数量）
    private func mineRandomCells(count: Int) {
        var remainingCount = count
        var totalMined = 0
        
        // tools_4 羁绊：掷出6时挖开所有未翻矿石
        if autoMineAllUnopened {
            let unminedCount = slotMachine.filter { !$0.isMined }.count
            remainingCount = unminedCount
            autoMineAllUnopened = false
            print("🔧 [tools_4] 本次挖矿自动挖开所有未翻矿石，共 \(remainingCount) 个")
        }
        
        print("⛏️ [挖矿开始] 需要挖 \(remainingCount) 个格子")
        
        // 循环挖矿，如果不够就刷新棋盘
        while remainingCount > 0 {
        // 获取所有未挖开的格子索引
        let unminedIndices = slotMachine.enumerated()
            .filter { !$0.element.isMined }
            .map { $0.offset }

            if unminedIndices.isEmpty {
                // 当前棋盘已挖完，刷新新棋盘
                print("🔄 [刷新棋盘] 当前棋盘已挖完，生成新棋盘继续挖矿")
                generateSlotResults()
                // 重置所有格子的挖矿状态
                for index in slotMachine.indices {
                    slotMachine[index].isMined = false
                }
                continue
            }
            
            // 确定本次要挖的数量（不超过剩余格子数和需要挖的数量）
            let actualCount = min(remainingCount, unminedIndices.count)

        // 随机选择要挖的格子
        let selectedIndices = Array(unminedIndices.shuffled().prefix(actualCount))

        for index in selectedIndices {
            slotMachine[index].isMined = true
            currentRoundMinedCells.append(index)
        }
            
            // classic tale 4/6 奖励：记录角落/中心奖励
            let activeTypeBonds = BondBuffRuntime.shared.activeTypeBonds
            if activeTypeBonds.contains("classictale_4_bond") {
                let corners: Set<Int> = [0, 4, 20, 24]
                let hitCorners = Set(selectedIndices).intersection(corners)
                if !hitCorners.isEmpty {
                    let bonus = 200
                    currentCoins += bonus
                    print("📜 [classic tale 4] 挖到角落 \(hitCorners)，金币+\(bonus)")
                }
            }
            if activeTypeBonds.contains("classictale_6_bond") {
                if selectedIndices.contains(12) {
                    let bonus = 400
                    currentCoins += bonus
                    print("📜 [classic tale 6] 挖到中心格，金币+\(bonus)")
                }
        }

        // 打印挖到的内容
        for index in selectedIndices {
            if let symbol = slotMachine[index].symbol {
                print("⛏️ [挖矿] 格子\(index): 挖到符号 \(symbol.icon) (\(symbol.name), \(symbol.baseValue)分)")
            } else {
                print("⛏️ [挖矿] 格子\(index): 挖到空格子 (+1分)")
            }
        }

            totalMined += actualCount
            remainingCount -= actualCount
            
            print("⛏️ [挖矿进度] 已挖 \(totalMined) 个，还需挖 \(remainingCount) 个")
        }
        
        print("✅ [挖矿完成] 总共挖了 \(totalMined) 个格子，满足骰子点数要求")
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
        
        // classic tale 2 羁绊：在生成棋盘时标记特殊格子（掷骰子之前就显示）
        let activeTypeBonds = BondBuffRuntime.shared.activeTypeBonds
        if activeTypeBonds.contains("classictale_2_bond") {
            // 清除旧的特殊标记
            slotMachine.indices.forEach { slotMachine[$0].isSpecial = false }
            // 随机标记一个格子为特殊
            let candidates = Array(0..<slotCount)
            if let specialIndex = candidates.randomElement() {
                slotMachine[specialIndex].isSpecial = true
                print("📜 [classic tale 2] 在生成棋盘时标记特殊格子 \(specialIndex) 收益翻倍（掷骰子之前显示）")
            }
        } else {
            // 如果没有激活羁绊，清除所有特殊标记
            slotMachine.indices.forEach { slotMachine[$0].isSpecial = false }
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
        // 在结算前更新羁绊状态，确保使用最新的激活羁绊信息
        let bondEffectProcessor = BondEffectProcessor()
        _ = bondEffectProcessor.processBondBuffs(symbolPool: &symbolPool, currentRound: currentRound)
        let activeTypeBonds = BondBuffRuntime.shared.activeTypeBonds
        print("🔍 [结算] 当前激活的类型计数羁绊: \(activeTypeBonds)")
        
        // 人类5：在符号计算前叠加基础值buff（全局入口，避免逐符号叠加）
        let humanBonusBuffType = "human_5_base_bonus"
        effectProcessor.removeGlobalBuff(buffType: humanBonusBuffType)
        if activeTypeBonds.contains("human_5_bond") {
            let humanTargets = symbolPool
                .filter { $0.types.contains("human") }
                .map { $0.nameKey }
            effectProcessor.applyGlobalBuff(buffType: humanBonusBuffType, targetSymbols: humanTargets, baseValueBonus: 10)
            let humanCount = humanTargets.count
            if humanCount > 0 {
                settlementLogs.append("👥 [人类5羁绊] 为\(humanCount)个人类符号应用基础值+10buff")
            }
        }
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
                
                var value = symbol.calculateValue(adjacentSymbols: adjacentSymbols, effectProcessor: effectProcessor, symbolPool: symbolPool)
                
                // classic tale 2 特殊格收益翻倍
                if slotMachine[index].isSpecial && activeTypeBonds.contains("classictale_2_bond") {
                    let originalValue = value
                    value *= 2
                    print("📜 [classic tale 2] 特殊格\(index)收益翻倍: \(originalValue) × 2 = \(value)")
                    settlementLogs.append("📜 [classic tale 2] 特殊格\(index)收益翻倍: \(originalValue) × 2 = \(value)金币")
                }
                
                // 添加到结算序列
                settlementSequence.append((cellIndex: index, symbol: symbol, earnings: value))
                
                let logMsg = "格子\(index): \(symbol.icon)\(symbol.name) = \(value)金币 (基础:\(symbol.baseValue), 相邻:\(adjacentSymbols.count))"
                print("💰 [基础收益] \(logMsg)")
                settlementLogs.append("💰 \(logMsg)")
            } else {
                // 空格子 +1分，cozy life 羁绊加成
                var emptyValue = 1
                let hasCozylife3 = activeTypeBonds.contains("cozylife_3_bond")
                let hasCozylife6 = activeTypeBonds.contains("cozylife_6_bond")
                print("🔍 [空格子结算] 格子\(index): 基础值=1, cozylife_3_bond=\(hasCozylife3), cozylife_6_bond=\(hasCozylife6), activeTypeBonds=\(activeTypeBonds)")
                if hasCozylife3 { 
                    emptyValue += 5
                    print("   ✓ cozylife_3_bond 生效: +5")
                }
                if hasCozylife6 { 
                    emptyValue += 25
                    print("   ✓ cozylife_6_bond 生效: +25")
                }
                
                // classic tale 2 特殊格收益翻倍（空格子也适用）
                if slotMachine[index].isSpecial && activeTypeBonds.contains("classictale_2_bond") {
                    let originalValue = emptyValue
                    emptyValue *= 2
                    print("📜 [classic tale 2] 特殊格\(index)空格子收益翻倍: \(originalValue) × 2 = \(emptyValue)")
                    settlementLogs.append("📜 [classic tale 2] 特殊格\(index)空格子收益翻倍: \(originalValue) × 2 = \(emptyValue)金币")
                }
                
                settlementSequence.append((cellIndex: index, symbol: nil, earnings: emptyValue))
                
                let logMsg = "格子\(index): 空格子 = \(emptyValue)金币"
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
        settlementAnimationSpeed = 1.0 // 重置动画速度为正常速度
        
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
        
        // 累加金币（根据速度倍数调整动画时长）
        withAnimation(.easeOut(duration: 0.3 / settlementAnimationSpeed)) {
            totalEarnings += item.earnings
        }
        
        // 每个格子动画持续时间根据速度倍数调整（正常0.5秒，倍速时0.25秒）
        let animationDuration = 0.5 / settlementAnimationSpeed
        let nextWork = DispatchWorkItem { [weak self] in
            self?.playNextSettlementStep(currentStep: currentStep + 1, minedSymbols: minedSymbols)
        }
        
        settlementTimer?.cancel()
        settlementTimer = nextWork
        DispatchQueue.main.asyncAfter(deadline: .now() + animationDuration, execute: nextWork)
    }
    
    /// 完成基础结算，开始处理符号效果和哥布林buff
    private func finishBasicSettlement(minedSymbols: [Symbol]) {
        print("✅ [结算动画] 基础结算完成，总收益: \(totalEarnings)金币")
        
        // 清除当前结算格子标记
        currentSettlingCellIndex = nil
        
        // 记录基础收益
        let basicEarnings = totalEarnings
        
        // 添加一个短暂延迟，让玩家看清最后一个格子的动画（根据速度倍数调整）
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3 / settlementAnimationSpeed) { [weak self] in
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
        let effectsEnabled = SymbolConfigManager.shared.isEffectsEnabled()
        print("🔍 [效果检查] 符号效果是否启用: \(effectsEnabled)")
        print("🔍 [效果检查] 本次挖出的符号: \(minedSymbols.map { "\($0.name)(\($0.effectType))" }.joined(separator: ", "))")
        
        // 记录处理效果前的骰子数量
        let diceCountBefore = effectProcessor.getDiceCount()
        print("🎲 [结算前] 当前骰子数量: \(diceCountBefore)")
        
        let effectBonus = effectProcessor.processMinedSymbols(
            minedSymbols: minedSymbols,
            symbolPool: &symbolPool,
            enableEffects: effectsEnabled,
            logCallback: { [weak self] log in
                self?.settlementLogs.append(log)
            }
        )
        totalEarnings += effectBonus
        
        // 记录处理效果后的骰子数量
        let diceCountAfter = effectProcessor.getDiceCount()
        print("🎲 [结算后] 当前骰子数量: \(diceCountAfter)")
        if diceCountAfter != diceCountBefore {
            print("🎲 [骰子变化] 骰子数量已更新: \(diceCountBefore) → \(diceCountAfter)")
        }
        
        if effectBonus != 0 {
            print("💰 [效果处理] 符号效果总奖励: \(effectBonus) 金币")
        } else if !minedSymbols.isEmpty {
            print("⚠️ [效果处理] 符号效果处理完成，但奖励为0（可能效果未触发或效果类型为none）")
        }
        
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
        // 应用羁绊收益加成（如浣熊市的丧尸数量奖励）
        let bondEarningsBonus = calculateBondEarningsBonus()
        totalEarnings += bondEarningsBonus
        if bondEarningsBonus > 0 {
            settlementLogs.append("🔗 [羁绊收益] +\(bondEarningsBonus) 金币\n")
            print("🔗 [羁绊收益] 总加成: +\(bondEarningsBonus) 金币")
        }
        
        // 应用哥布林buff
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
                // 骰子可转动时，更新显示的转动次数
                self.updateDisplayedSpinInRoundIfCanRoll()
                // 骰子可转动时，更新显示的转动次数
                self.updateDisplayedSpinInRoundIfCanRoll()
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
                // 检查是否已经完成所有关卡（第30关）
                let maxRound = 30
                if currentRound >= maxRound {
                    // 已完成所有关卡，游戏胜利
                    print("🎉 [游戏胜利] 恭喜完成所有30关！")
                    let victoryMessage = localizationManager.localized("game_over.victory_message")
                    gameOver(message: victoryMessage)
                    return
                }
                
                // 支付成功
                currentCoins -= rentAmount
                totalRentPaid += rentAmount // 累计已支付的房租
                
                // 检查成就：第一次通过 15-3（在进入第16关之前检查）
                if currentRound == 15 && displayedSpinInRound == 3 {
                    let hasCompletedAchievement2 = UserDefaults.standard.bool(forKey: "achievement_achivement_2")
                    if !hasCompletedAchievement2 {
                        GameCenterManager.shared.unlockAchievement("achivement_2")
                        print("🏆 [成就] 检测到第一次通过 15-3，解锁成就 achivement_2")
                    }
                }
                
                currentRound += 1
                spinsRemaining = configManager.getGameSettings().spinsPerRound
                rentAmount = configManager.getRentAmount(for: currentRound)
                displayedSpinInRound = 1 // 新回合开始，重置为第1次转动

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
                
                let roundStartBonus = effectProcessor.processRoundStart(symbolPool: &symbolPool, currentRound: currentRound)
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
                print("❌ [游戏结束] 金币不足，无法达成目标")
                gameOver(message: "金币不足！无法达成 \(rentAmount) 金币的目标")
            }
        } else {
            // 等待玩家手动点击"挖矿x1"按钮
            print("⏸️ [等待操作] 等待玩家点击挖矿按钮")
            gamePhase = .result
            // 骰子可转动时，更新显示的转动次数
            updateDisplayedSpinInRoundIfCanRoll()
        }
    }

    /// **新功能：回合开始处理**
    private func processRoundStart() {
        print("🌅 [回合开始] 处理回合\(currentRound)开始效果")
        
        // **新功能：应用羁绊全局buff（如奸商、正义必胜）**
        applyBondGlobalBuffs()

        // 处理回合开始效果（花精合成、元素收集、回合开始惩罚/buff等）
        let roundStartBonus = effectProcessor.processRoundStart(symbolPool: &symbolPool, currentRound: currentRound)
        currentCoins += roundStartBonus
        
        // **新功能：检查是否需要游戏结束（死神的眷顾）**
        if effectProcessor.shouldEndGame() {
            gameOver(message: "死神的眷顾已结束，游戏强制结束")
            return
        }

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
        availableSymbols = SymbolLibrary.getSymbolChoiceOptions(symbolPool: symbolPool)
        print("🎯 [初始选择] 生成3个可选符号: \(availableSymbols.map { $0.name })")
        showSymbolSelection = true
    }
    
    /// 显示符号选择阶段（回合结束后的选择）
    private func showSymbolSelectionPhase() {
        print("🎯 [回合选择] 回合结束，请选择新符号")
        
        gamePhase = .selectingSymbol
        availableSymbols = SymbolLibrary.getSymbolChoiceOptions(symbolPool: symbolPool)
        print("🎯 [回合选择] 生成3个可选符号: \(availableSymbols.map { $0.name })")
        showSymbolSelection = true
        
        // 额外符号选择（包括速之神、工匠哥布林等）
        extraSymbolChoicesPending += effectProcessor.consumeExtraSymbolChoices()
        if let goblin = selectedGoblin, goblin.id == 2 {
            extraSymbolChoicesPending += 1
            print("🔨 [工匠哥布林] 本回合额外+1次符号选择，累计：\(extraSymbolChoicesPending)")
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
        
        // 检测是否是第一次符号选择完成
        // 起始符号池有3个符号，第一次选择后应该有4个
        let startingSymbolCount = SymbolLibrary.startingSymbols.count
        if !hasCompletedFirstSymbolSelection && currentRound == 1 && symbolPool.count == startingSymbolCount + 1 {
            hasCompletedFirstSymbolSelection = true
            // 检查是否已经完成过游戏内新手引导
            let hasCompletedGameTutorial = UserDefaults.standard.bool(forKey: "hasCompletedGameTutorial")
            if !hasCompletedGameTutorial {
                // 延迟一点显示引导，确保UI已经更新
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self.showGameTutorial = true
                    print("📚 [游戏内引导] 第一次符号选择完成（符号池: \(self.symbolPool.count)），显示游戏内新手引导")
                }
            } else {
                print("📚 [游戏内引导] 第一次符号选择完成，但用户已完成过引导，跳过")
            }
        }
        
        // 若有额外符号选择次数，继续显示下一次选择
        if extraSymbolChoicesPending > 0 {
            extraSymbolChoicesPending -= 1
            print("🎯 [额外选择] 剩余额外选择次数：\(extraSymbolChoicesPending)")
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.gamePhase = .selectingSymbol
                self.availableSymbols = SymbolLibrary.getSymbolChoiceOptions(symbolPool: self.symbolPool)
                self.showSymbolSelection = true
            }
            return
        }
        
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
        // 骰子可转动时，更新显示的转动次数
        updateDisplayedSpinInRoundIfCanRoll()
        print("🎮 [调试] 设置后状态 - spinsRemaining: \(spinsRemaining), isSpinning: \(isSpinning), gamePhase: \(gamePhase)")
    }
    
    /// 完成游戏内新手引导
    func completeGameTutorial() {
        print("📚 [游戏内引导] 用户完成游戏内新手引导")
        UserDefaults.standard.set(true, forKey: "hasCompletedGameTutorial")
        showGameTutorial = false
    }
    
    /// 测试功能：一键添加所有触发羁绊的符号
    func addAllBondTestSymbols() {
        print("🔍 [DEBUG] addAllBondTestSymbols entry - gamePhase: \(gamePhase), symbolPoolCount: \(symbolPool.count), goblinSelectionCompleted: \(goblinSelectionCompleted)")
        
        print("🧪 [测试] 开始添加所有羁绊测试符号")
        
        // 检查游戏状态，确保只在游戏进行中才能添加
        guard goblinSelectionCompleted else {
            print("⚠️ [测试] 游戏未开始，无法添加测试符号")
            return
        }
        
        // 确保不在符号选择阶段
        guard gamePhase != .selectingSymbol else {
            print("⚠️ [测试] 当前在符号选择阶段，无法添加测试符号")
            return
        }
        
        // 从bond_buff.csv中获取所有需要的符号ID
        let bondSymbolIds: Set<Int> = [
            // 奸商：2 (商人)
            2,
            // 吸血鬼的诅咒：16 (吸血鬼), 44 (领结)
            16, 44,
            // 死神的眷顾：24 (死神)
            24,
            // 捕狼队：67 (狼人), 59 (锄头)
            67, 59,
            // 元素掌握者：25,26,27,28,29 (五个元素)
            25, 26, 27, 28, 29,
            // 正义必胜：12 (修女), 31 (十字架)
            12, 31,
            // 世界末日：16 (吸血鬼), 67 (狼人), 68 (丧尸), 70 (哥莫拉)
            16, 67, 68, 70,
            // 人类灭绝：71,72,73,74 (光线枪、外星头盔、宇宙飞船、精神控制器)
            71, 72, 73, 74,
            // 浣熊市：68 (丧尸)
            68
        ]
        
        var addedCount = 0
        for symbolId in bondSymbolIds {
            if let symbol = SymbolConfigManager.shared.getSymbol(byConfigId: symbolId) {
                // 检查是否已经存在
                let exists = symbolPool.contains { symbol in
                    SymbolConfigManager.shared.getSymbolConfigId(byNameKey: symbol.nameKey) == symbolId
                }
                
                if !exists {
                    symbolPool.append(symbol)
                    addedCount += 1
                    print("✅ [测试] 添加符号: \(symbol.name) (ID: \(symbolId))")
                } else {
                    print("⚠️ [测试] 符号已存在: ID \(symbolId)")
                }
            } else {
                print("❌ [测试] 找不到符号 ID: \(symbolId)")
            }
        }
        
        print("🔍 [DEBUG] addAllBondTestSymbols exit - addedCount: \(addedCount), finalSymbolPoolCount: \(symbolPool.count)")
        
        print("🧪 [测试] 完成！共添加 \(addedCount) 个新符号，当前符号池总数: \(symbolPool.count)")
        
        // 显示提示
        showEarningsTip(text: "已添加 \(addedCount) 个测试符号")
    }

    /// 测试功能：按羁绊键添加所需符号
    func addSymbolsForBond(nameKey: String) {
        guard goblinSelectionCompleted, gamePhase != .selectingSymbol else {
            print("⚠️ [测试] 游戏未开始或正在选择符号，无法添加羁绊符号")
            return
        }
        
        let bondSymbolIds: [String: [Int]] = [
            "merchant_trading_bond": [2],
            "vampire_curse_bond": [16, 44],
            "death_blessing_bond": [24],
            "wolf_hunter_bond": [67, 59],
            "element_master_bond": [25, 26, 27, 28, 29],
            "justice_bond": [12, 31],
            "apocalypse_bond": [16, 67, 68, 70],
            "human_extinction_bond": [71, 72, 73, 74],
            "raccoon_city_bond": [68],
            // 类型计数羁绊：填充满足数量的人类/材料/工具等
            "human_3_bond": [5, 15, 6], // 士兵、公主、村长
            "human_5_bond": [5, 15, 6, 14, 18],
            "human_10_bond": [5, 15, 6, 14, 18, 19, 10, 11, 12, 17],
            "material_2_bond": [30, 48], // 石头、硬币
            "material_4_bond": [30, 48, 45, 58], // 再加勾玉、公文包
            "cozylife_3_bond": [42, 43, 49], // 手机、眼镜、枕头
            "cozylife_6_bond": [42, 43, 49, 50, 57, 58],
            "tools_2_bond": [37, 38], // 圣瓶、契约卷轴（tool）
            "tools_4_bond": [37, 38, 63, 64], // +铁钥匙、银钥匙
            "classictale_2_bond": [4, 5], // 农民、士兵
            "classictale_4_bond": [4, 5, 14, 15], // +盗贼、公主
            "classictale_6_bond": [4, 5, 14, 15, 33, 35] // +催眠摆、符文护甲
        ]
        
        guard let ids = bondSymbolIds[nameKey] else {
            print("⚠️ [测试] 未知羁绊 \(nameKey)")
            return
        }
        
        var addedCount = 0
        for symbolId in ids {
            if let symbol = SymbolConfigManager.shared.getSymbol(byConfigId: symbolId) {
                let exists = symbolPool.contains { existing in
                    SymbolConfigManager.shared.getSymbolConfigId(byNameKey: existing.nameKey) == symbolId
                }
                if !exists {
                    symbolPool.append(symbol)
                    addedCount += 1
                    print("✅ [测试] 添加符号: \(symbol.name) (ID: \(symbolId))")
                } else {
                    print("⚠️ [测试] 符号已存在: ID \(symbolId)")
                }
            } else {
                print("❌ [测试] 找不到符号 ID: \(symbolId)")
            }
        }
        
        showEarningsTip(text: "羁绊\(nameKey) 已添加\(addedCount)个符号")
    }
    
    /// 应用羁绊全局buff（如奸商、正义必胜）
    private func applyBondGlobalBuffs() {
        let bondBuffs = BondBuffConfigManager.shared.getActiveBondBuffs(symbolPool: symbolPool)
        
        for bondBuff in bondBuffs {
            // 奸商：勾玉和硬币基础价值+20
            if bondBuff.nameKey.contains("merchant_trading_bond") {
                effectProcessor.applyGlobalBuff(
                    buffType: "merchant_trading_bond",
                    targetSymbols: ["勾玉", "硬币"],
                    baseValueBonus: 20
                )
                print("💰 [羁绊Buff] 奸商全局buff已激活：勾玉和硬币+20")
            }
            
            // 正义必胜：猎人权重翻倍（这个需要在生成符号时应用，这里只标记）
            if bondBuff.nameKey.contains("justice_bond") {
                // 权重翻倍需要在SymbolConfigManager中实现
                print("⚖️ [羁绊Buff] 正义必胜全局buff已激活：猎人权重翻倍")
            }
        }
    }
    
    /// 挖矿前处理羁绊效果（如浣熊市）
    private func processBondBuffsBeforeMining() {
        let bondBuffs = BondBuffConfigManager.shared.getActiveBondBuffs(symbolPool: symbolPool)
        
        print("🔍 [羁绊Buff] 挖矿前检查羁绊，当前激活的羁绊数量: \(bondBuffs.count)")
        for bondBuff in bondBuffs {
            print("🔍 [羁绊Buff] 检查羁绊: \(bondBuff.nameKey)")
            // 处理浣熊市：每次挖矿前感染一个人类变成丧尸
            if bondBuff.nameKey.contains("raccoon_city_bond") {
                print("🧟 [羁绊Buff] 浣熊市羁绊已激活，开始感染人类")
                // 感染一个人类
                if let humanIndex = symbolPool.firstIndex(where: { $0.types.contains("human") }) {
                    if let zombie = SymbolLibrary.getSymbol(byName: "丧尸") {
                        let humanName = symbolPool[humanIndex].name
                        symbolPool[humanIndex] = zombie
                        print("🧟 [羁绊Buff] 浣熊市：挖矿前感染1个人类(\(humanName))变成丧尸")
                        settlementLogs.append("🧟 [羁绊Buff] 浣熊市：挖矿前感染1个人类(\(humanName))变成丧尸")
                    } else {
                        print("❌ [羁绊Buff] 浣熊市：无法找到丧尸符号")
                    }
                } else {
                    print("⚠️ [羁绊Buff] 浣熊市：符号池中没有人类可以感染")
                }
            }
        }
    }
    
    /// 计算羁绊收益加成（如浣熊市的丧尸数量奖励）
    private func calculateBondEarningsBonus() -> Int {
        var bonus = 0
        let bondBuffs = BondBuffConfigManager.shared.getActiveBondBuffs(symbolPool: symbolPool)
        
        for bondBuff in bondBuffs {
            // 浣熊市：每有一个丧尸，额外金币增加20
            if bondBuff.nameKey.contains("raccoon_city_bond") {
                // 使用 nameKey 来匹配，因为 name 可能是本地化的
                let zombieCount = symbolPool.filter { $0.nameKey == "zombie" }.count
                if zombieCount > 0 {
                    bonus += zombieCount * 20
                    print("🧟 [羁绊Buff] 浣熊市：符号池有\(zombieCount)个丧尸，额外+\(zombieCount * 20)金币")
                    settlementLogs.append("🧟 [羁绊Buff] 浣熊市：符号池有\(zombieCount)个丧尸，额外+\(zombieCount * 20)金币")
                }
            }
        }
        
        return bonus
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
        let currentDifficulty = configManager.currentDifficulty
        if currentRound > bestRound {
            bestRound = currentRound
            bestSpinInRound = displayedSpinInRound
            bestDifficulty = currentDifficulty
            print("🏆 [新记录] 最佳回合数更新: \(bestRound)-\(bestSpinInRound) [\(currentDifficulty)]")
        } else if currentRound == bestRound && displayedSpinInRound > bestSpinInRound {
            bestSpinInRound = displayedSpinInRound
            bestDifficulty = currentDifficulty
            print("🏆 [新记录] 最佳转动次数更新: \(bestRound)-\(bestSpinInRound) [\(currentDifficulty)]")
        }

        let totalCoins = accumulatedCoins
        if totalCoins > bestCoins {
            bestCoins = totalCoins
            print("💰 [新记录] 历史最多金币更新: \(bestCoins)")
        }
        
        // 提交单局最高金币数到Game Center排行榜
        // 注意：这里使用accumulatedCoins（累计金币 = 当前金币 + 已支付的房租）
        // 这代表玩家在这局游戏中获得的总金币数
        let singleGameCoins = totalCoins
        print("🎮 [Game Center] 准备提交单局最高金币数: \(singleGameCoins)")
        GameCenterManager.shared.submitScore(Int64(singleGameCoins))

        gamePhase = .gameOver
        gameOverMessage = message
        showGameOver = true
    }
    
    /// 测试功能：跳过所有关卡（直接到最后一关）
    func skipToLastRound() {
        print("🧪 [测试] 跳过所有关卡，直接到第30关")
        // 设置到最后一关（第30关）
        currentRound = 30
        // 给足够的金币来支付当前关卡的房租
        let lastRoundRent = configManager.getRentAmount(for: 30)
        currentCoins = max(currentCoins, lastRoundRent + 1000) // 确保有足够金币
        rentAmount = lastRoundRent
        spinsRemaining = configManager.getGameSettings().spinsPerRound
        displayedSpinInRound = 1
        
        // 重置游戏状态
        isSpinning = false
        wizardBuffUsedThisRound = false
        totalEarnings = 0
        showGameOver = false
        
        // 重新初始化老虎机
        slotMachine = (0..<slotCount).map { _ in SlotCell(symbol: nil, isMined: false) }
        generateSlotResults()
        
        // 触发符号选择界面
        gamePhase = .selectingSymbol
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.showSymbolSelectionPhase()
        }
        
        print("🧪 [测试] 已设置到第30关，当前金币: \(currentCoins)，房租: \(rentAmount)")
    }
    
    /// 重新开始游戏（更换难度时调用，保留哥布林选择）
    func restartGame() {
        print("🔄 [重新开始] 重置游戏（保留哥布林）")
        // 不重置哥布林选择，但需要重新进行符号选择
        craftsmanBuffUsed = false
        
        // 重置效果处理器
        effectProcessor.resetRoundState()
        effectProcessor.resetDiceCount()
        
        // 清空羁绊状态（特别是 classic tale）
        BondBuffRuntime.shared.activeTypeBonds.removeAll()
        print("🔄 [重新开始] 已清空羁绊状态")
        
        // 重置羁绊闪光状态
        previousActiveBondIDs.removeAll()
        flashingBondIDs.removeAll()
        
        // 重置游戏状态（顺序很重要！）
        totalEarnings = 0
        totalRentPaid = 0 // 重置累计房租
        currentRound = 1  // 先设置回合数
        isSpinning = false  // 确保没有在掷骰子
        showGameOver = false  // 隐藏失败界面
        
        // 重新加载游戏设置（会使用currentRound来计算房租）
        loadGameSettings()
        
        // 重置符号池，使用起始符号
        suppressSymbolPoolReorder = true
        symbolPool = SymbolLibrary.startingSymbols
        suppressSymbolPoolReorder = false
        print("🎮 [重新开始] 重置符号池: \(symbolPool.map { $0.name })")
        
        // 重新初始化老虎机（清空特殊格子标记）
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
        
        // 清空羁绊状态（特别是 classic tale）
        BondBuffRuntime.shared.activeTypeBonds.removeAll()
        print("🔄 [完全重新开始] 已清空羁绊状态")
        
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
        let currentDifficulty = configManager.currentDifficulty
        let previousBestRound = bestRound
        let previousBestSpin = bestSpinInRound
        if currentRound > bestRound {
            bestRound = currentRound
            bestSpinInRound = displayedSpinInRound
            bestDifficulty = currentDifficulty
            print("🏆 [退出时更新] 最佳回合数: \(previousBestRound) → \(bestRound)-\(bestSpinInRound) [\(currentDifficulty)]")
        } else if currentRound == bestRound && displayedSpinInRound > bestSpinInRound {
            bestSpinInRound = displayedSpinInRound
            bestDifficulty = currentDifficulty
            print("🏆 [退出时更新] 最佳转动次数: \(previousBestRound)-\(previousBestSpin) → \(bestRound)-\(bestSpinInRound) [\(currentDifficulty)]")
        } else {
            print("🏆 [退出时检查] 当前回合\(currentRound)-\(displayedSpinInRound)未超过最佳\(bestRound)-\(bestSpinInRound)")
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
        selectedGoblin = nil // 重置哥布林选择，确保下次选择时能触发onChange
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
        
        // 注意：不重置最佳记录，这些应该保留
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
                
                // 创建新的定时器，2秒后自动隐藏（符号buff类型除外，需要用户手动关闭）
                if case .symbolBuff = tipType {
                    // 符号buff弹窗不自动消失，需要用户点击其他区域关闭
                    print("📝 [气泡] 符号buff弹窗已显示，等待用户手动关闭")
                } else {
                    // 其他类型的气泡仍然自动消失
                let workItem = DispatchWorkItem { [weak self] in
                    self?.dismissTip()
                }
                self.tipTimer = workItem
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0, execute: workItem)
                }
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
    
    /// 关闭符号buff提示（用户手动关闭）
    func dismissSymbolBuffTip() {
        // 如果当前显示的是符号buff提示，则关闭它
        if case .symbolBuff = currentTipType {
            dismissTip()
        }
    }
    
    /// 显示羁绊详情弹窗
    func showBondDescriptionView(bondBuff: BondBuff) {
        selectedBondForDescription = bondBuff
        showBondDescription = true
    }
    
    /// 关闭羁绊详情弹窗
    func dismissBondDescriptionView() {
        showBondDescription = false
        selectedBondForDescription = nil
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
        // 从配置文件加载奖励
        if let reward = DailySignInConfigManager.shared.getReward(for: day) {
            return reward
        }
        
        // 如果配置加载失败，返回默认奖励
        print("⚠️ [签到] 无法从配置获取第\(day)天奖励，使用默认值")
        return SignInReward(day: day, type: .diamonds, amount: 10, description: "10 💎")
    }
    
    /// 获取所有7天的奖励（用于显示）
    func getAllSignInRewards() -> [SignInReward] {
        return DailySignInConfigManager.shared.getAllRewards()
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

