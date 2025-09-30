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
    
    // MARK: - 常量
    private let slotCount = 20 // 老虎机格子数量
    private let symbolChoiceCount = 3 // 每次可选符号数量
    
    init() {
        print("🎮 [游戏初始化] 开始初始化游戏")
        loadGameSettings()
        startNewGame()
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
    
    /// 开始新游戏
    func startNewGame() {
        print("🎮 [新游戏] 初始化游戏状态")
        loadGameSettings()
        totalEarnings = 0
        currentRound = 1
        gamePhase = .spinning
        showGameOver = false
        
        // 初始化符号池
        symbolPool = SymbolLibrary.startingSymbols
        print("🎮 [新游戏] 初始符号池: \(symbolPool.map { $0.name })")
        
        // 初始化老虎机
        initializeSlotMachine()
        
        // 自动执行第一次旋转
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.spin()
        }
    }
    
    /// 初始化老虎机格子
    private func initializeSlotMachine() {
        slotMachine = (0..<slotCount).map { _ in SlotCell(symbol: nil) }
        print("🎰 [老虎机] 初始化 \(slotCount) 个格子")
    }
    
    /// 旋转老虎机
    func spin() {
        guard !isSpinning else { return }
        
        print("🎰 [旋转] 开始旋转 - 回合 \(currentRound), 剩余次数 \(spinsRemaining)")
        
        isSpinning = true
        gamePhase = .spinning
        totalEarnings = 0
        
        // 模拟旋转动画
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.generateSlotResults()
            self.calculateEarnings()
            self.isSpinning = false
            self.gamePhase = .result
            
            print("💰 [收益] 本轮获得: \(self.totalEarnings) 金币")
            
            // 增加金币
            self.currentCoins += self.totalEarnings
            self.spinsRemaining -= 1
            
            // 显示收益气泡提示
            self.showEarningsTip(text: "💵 +\(self.totalEarnings) 金币")
            
            // 检查是否需要支付房租
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                self.checkRentPayment()
            }
        }
    }
    
    /// 生成老虎机结果
    private func generateSlotResults() {
        print("🎰 [生成结果] 基于符号池大小生成符号")
        
        // 清空所有格子
        for index in 0..<slotCount {
            slotMachine[index].symbol = nil
        }
        
        if symbolPool.isEmpty {
            print("🎰 [生成结果] 符号池为空，全部空格子")
            return
        }
        
        // 计算应该显示的符号数量（基于符号池大小）
        let targetSymbolCount = getTargetSymbolCount()
        print("🎰 [生成结果] 目标显示符号数量: \(targetSymbolCount)/\(slotCount)")
        
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
        
        print("🎰 [生成结果] 实际显示符号: \(slotMachine.compactMap { $0.symbol }.count)/\(slotCount)")
    }
    
    /// 获取目标符号数量（基于符号池大小）
    private func getTargetSymbolCount() -> Int {
        return configManager.getSymbolDisplayCount(for: symbolPool.count)
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
    
    /// 计算收益
    private func calculateEarnings() {
        totalEarnings = 0
        
        for (index, cell) in slotMachine.enumerated() {
            if let symbol = cell.symbol {
                // 获取相邻符号（简化版：只看左右）
                var adjacentSymbols: [Symbol] = []
                
                // 左侧
                if index > 0, let leftSymbol = slotMachine[index - 1].symbol {
                    adjacentSymbols.append(leftSymbol)
                }
                
                // 右侧
                if index < slotCount - 1, let rightSymbol = slotMachine[index + 1].symbol {
                    adjacentSymbols.append(rightSymbol)
                }
                
                let value = symbol.calculateValue(adjacentSymbols: adjacentSymbols)
                totalEarnings += value
            }
        }
        
        // 应用道具倍率
        for item in items {
            totalEarnings = Int(Double(totalEarnings) * item.multiplier)
        }
        
        print("💰 [计算收益] 总收益: \(totalEarnings) 金币")
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
            // 继续旋转
            gamePhase = .spinning
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.spin()
            }
        }
    }
    
    /// 显示符号选择阶段
    private func showSymbolSelectionPhase() {
        print("🎯 [选择符号] 生成 \(symbolChoiceCount) 个可选符号")
        gamePhase = .selectingSymbol
        availableSymbols = SymbolLibrary.getRandomSymbols(count: symbolChoiceCount)
        showSymbolSelection = true
    }
    
    /// 选择符号
    func selectSymbol(_ symbol: Symbol) {
        print("✅ [选择符号] 玩家选择了: \(symbol.name)")
        symbolPool.append(symbol)
        showSymbolSelection = false
        
        // 继续下一轮
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.gamePhase = .spinning
            self.spin()
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
        startNewGame()
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
}
