//
//  GoblinConfigManager.swift
//  A004
//
//  哥布林配置管理器
//

import Foundation

// MARK: - 配置文件结构
struct GoblinConfigFile: Codable {
    let goblins: [GoblinConfig]
    let config: GoblinSystemConfig
}

struct GoblinConfig: Codable {
    let id: Int
    let name: String
    let icon: String
    let isFree: Bool
    let buff: String
    let buffType: String
    let buffValue: Double
    let unlockPrice: Int
    let description: String
}

struct GoblinSystemConfig: Codable {
    let defaultUnlockedIds: [Int]
    let maxGoblins: Int
    let enableBuffEffects: Bool
}

// MARK: - 配置管理器
class GoblinConfigManager {
    static let shared = GoblinConfigManager()
    
    private var configFile: GoblinConfigFile?
    private let configFileName = "GoblinConfig"
    
    private init() {
        loadConfig()
    }
    
    /// 加载配置文件
    private func loadConfig() {
        guard let url = Bundle.main.url(forResource: configFileName, withExtension: "json") else {
            print("❌ [哥布林配置] 找不到配置文件: \(configFileName).json")
            return
        }
        
        do {
            let data = try Data(contentsOf: url)
            configFile = try JSONDecoder().decode(GoblinConfigFile.self, from: data)
            print("✅ [哥布林配置] 成功加载配置文件，共 \(configFile?.goblins.count ?? 0) 个哥布林")
        } catch {
            print("❌ [哥布林配置] 解析配置文件失败: \(error)")
        }
    }
    
    /// 获取所有哥布林
    func getAllGoblins() -> [Goblin] {
        guard let configFile = configFile else {
            print("⚠️ [哥布林配置] 配置文件未加载，返回空数组")
            return []
        }
        
        return configFile.goblins.map { config in
            Goblin(
                id: config.id,
                name: config.name,
                icon: config.icon,
                isFree: config.isFree,
                buff: config.buff,
                buffType: config.buffType,
                buffValue: config.buffValue,
                unlockPrice: config.unlockPrice,
                description: config.description
            )
        }
    }
    
    /// 根据ID获取哥布林
    func getGoblin(by id: Int) -> Goblin? {
        return getAllGoblins().first { $0.id == id }
    }
    
    /// 获取默认解锁的哥布林ID列表
    func getDefaultUnlockedIds() -> Set<Int> {
        guard let config = configFile?.config else {
            print("⚠️ [哥布林配置] 配置文件未加载，返回默认解锁列表 [1,2,3]")
            return [1, 2, 3]
        }
        return Set(config.defaultUnlockedIds)
    }
    
    /// 获取最大哥布林数量
    func getMaxGoblins() -> Int {
        return configFile?.config.maxGoblins ?? 5
    }
    
    /// 检查是否启用buff效果
    func isBuffEffectsEnabled() -> Bool {
        return configFile?.config.enableBuffEffects ?? true
    }
    
    /// 重新加载配置（用于热更新）
    func reloadConfig() {
        print("🔄 [哥布林配置] 重新加载配置文件")
        loadConfig()
    }
}

