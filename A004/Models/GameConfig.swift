//
//  GameConfig.swift
//  A004
//
//  游戏配置管理器
//

import Foundation

// MARK: - 配置数据结构
struct GameConfig: Codable {
    let rentSettings: RentSettings
    let gameSettings: GameSettings
    let symbolSettings: SymbolSettings
    let uiSettings: UISettings
}

struct RentSettings: Codable {
    let mode: String // "custom" 或 "preset"
    let initialRent: Int
    let incrementMultiplier: Double
    let customRentSequence: [Int]
    let difficultyPresets: [String: DifficultyPreset]
}

struct DifficultyPreset: Codable {
    let initialRent: Int
    let incrementMultiplier: Double
    let customRentSequence: [Int]
}

struct GameSettings: Codable {
    let initialCoins: Int
    let spinsPerRound: Int
    let slotCount: Int
    let symbolChoiceCount: Int
    let startingSymbolCount: Int
}

struct SymbolSettings: Codable {
    let displayMultiplier: [String: Int]
    let rarityWeights: [String: Double]
}

struct UISettings: Codable {
    let animationDuration: Double
    let spinDelay: Double
    let resultDisplayTime: Double
}

// MARK: - 配置管理器
class GameConfigManager: ObservableObject {
    static let shared = GameConfigManager()
    
    @Published var currentConfig: GameConfig
    @Published var currentDifficulty: String = "easy"
    
    private init() {
        // 加载默认配置
        self.currentConfig = GameConfigManager.loadDefaultConfig()
    }
    
    // MARK: - 配置加载
    static func loadDefaultConfig() -> GameConfig {
        guard let url = Bundle.main.url(forResource: "GameConfig", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let config = try? JSONDecoder().decode(GameConfig.self, from: data) else {
            print("❌ [配置] 无法加载配置文件，使用默认配置")
            return GameConfigManager.createDefaultConfig()
        }
        
        print("✅ [配置] 成功加载配置文件")
        return config
    }
    
    static func createDefaultConfig() -> GameConfig {
        return GameConfig(
            rentSettings: RentSettings(
                mode: "custom",
                initialRent: 50,
                incrementMultiplier: 1.5,
                customRentSequence: [50, 75, 112, 168, 252, 378, 567, 850, 1275, 1912],
                difficultyPresets: [:]
            ),
            gameSettings: GameSettings(
                initialCoins: 10,
                spinsPerRound: 10,
                slotCount: 20,
                symbolChoiceCount: 3,
                startingSymbolCount: 3
            ),
            symbolSettings: SymbolSettings(
                displayMultiplier: ["3": 3, "6": 6, "10": 10, "15": 15, "20": 20],
                rarityWeights: ["common": 0.5, "rare": 0.3, "epic": 0.15, "legendary": 0.05]
            ),
            uiSettings: UISettings(
                animationDuration: 1.0,
                spinDelay: 0.1,
                resultDisplayTime: 1.5
            )
        )
    }
    
    // MARK: - 难度切换
    func setDifficulty(_ difficulty: String) {
        guard let preset = currentConfig.rentSettings.difficultyPresets[difficulty] else {
            print("❌ [配置] 未找到难度预设: \(difficulty)")
            return
        }
        
        currentDifficulty = difficulty
        print("✅ [配置] 切换到难度: \(difficulty)")
    }
    
    // MARK: - 获取当前房租设置
    func getCurrentRentSettings() -> (initialRent: Int, incrementMultiplier: Double, customSequence: [Int]) {
        if currentDifficulty != "custom" {
            guard let preset = currentConfig.rentSettings.difficultyPresets[currentDifficulty] else {
                return (currentConfig.rentSettings.initialRent, 
                       currentConfig.rentSettings.incrementMultiplier, 
                       currentConfig.rentSettings.customRentSequence)
            }
            return (preset.initialRent, preset.incrementMultiplier, preset.customRentSequence)
        }
        
        return (currentConfig.rentSettings.initialRent, 
               currentConfig.rentSettings.incrementMultiplier, 
               currentConfig.rentSettings.customRentSequence)
    }
    
    // MARK: - 获取房租金额
    func getRentAmount(for round: Int) -> Int {
        let settings = getCurrentRentSettings()
        
        if round < settings.customSequence.count {
            return settings.customSequence[round]
        } else {
            // 超出预设序列后，按倍率递增
            let lastRent = settings.customSequence.last ?? settings.initialRent
            let roundsBeyond = round - settings.customSequence.count + 1
            return Int(Double(lastRent) * pow(settings.incrementMultiplier, Double(roundsBeyond)))
        }
    }
    
    // MARK: - 获取符号显示数量
    func getSymbolDisplayCount(for poolSize: Int) -> Int {
        let multiplier = currentConfig.symbolSettings.displayMultiplier
        
        if poolSize <= 3 {
            return multiplier["3"] ?? 3
        } else if poolSize == 4 {
            return multiplier["4"] ?? 4
        } else if poolSize == 5 {
            return multiplier["5"] ?? 5
        } else if poolSize <= 6 {
            return multiplier["6"] ?? 6
        } else if poolSize <= 10 {
            return multiplier["10"] ?? 10
        } else if poolSize <= 15 {
            return multiplier["15"] ?? 15
        } else if poolSize <= 20 {
            return multiplier["20"] ?? 20
        } else if poolSize <= 25 {
            return multiplier["25"] ?? 25
        } else {
            return multiplier["25"] ?? 25 // 超过25个时，最多显示25个
        }
    }
    
    // MARK: - 获取游戏设置
    func getGameSettings() -> GameSettings {
        return currentConfig.gameSettings
    }
    
    // MARK: - 获取UI设置
    func getUISettings() -> UISettings {
        return currentConfig.uiSettings
    }
    
    // MARK: - 获取稀有度权重
    func getRarityWeights() -> [SymbolRarity: Double] {
        let weights = currentConfig.symbolSettings.rarityWeights
        return [
            .common: weights["common"] ?? 0.5,
            .rare: weights["rare"] ?? 0.3,
            .epic: weights["epic"] ?? 0.15,
            .legendary: weights["legendary"] ?? 0.05
        ]
    }
}
