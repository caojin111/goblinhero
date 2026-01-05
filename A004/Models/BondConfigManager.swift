//
//  BondConfigManager.swift
//  A004
//
//  羁绊配置管理器
//

import Foundation
import SwiftUI

// MARK: - 羁绊配置结构
struct BondConfigFile: Codable {
    let bonds: [BondConfig]
}

struct BondConfig: Codable {
    let id: String // 羁绊唯一ID
    let nameKey: String // 多语言键名（用于名称）
    let descriptionKey: String // 多语言键名（用于描述）
    let requiredSymbolIds: [Int] // 所需符号ID列表
    let backgroundColor: String // 背景颜色（十六进制，如 "#FF5733"）
}

// MARK: - 羁绊模型
struct Bond: Identifiable, Equatable {
    let id: String
    let nameKey: String
    let descriptionKey: String
    let requiredSymbolIds: [Int]
    let backgroundColor: Color
    
    // 本地化名称
    var name: String {
        return LocalizationManager.shared.localized("bonds.\(nameKey).name")
    }
    
    // 本地化描述
    var description: String {
        return LocalizationManager.shared.localized("bonds.\(nameKey).description")
    }
    
    // 检查羁绊是否激活（基于符号池）
    // 注意：这里使用符号的配置ID（从SymbolConfig.json中的id字段）来匹配
    func isActive(symbolPool: [Symbol]) -> Bool {
        // 获取所有符号的配置ID（通过SymbolConfigManager）
        let symbolConfigIds = symbolPool.compactMap { symbol -> Int? in
            // 通过nameKey查找配置ID
            return SymbolConfigManager.shared.getSymbolConfigId(byNameKey: symbol.nameKey)
        }
        let symbolIdsSet = Set(symbolConfigIds)
        let requiredIdsSet = Set(requiredSymbolIds)
        let isActive = requiredIdsSet.isSubset(of: symbolIdsSet)
        
        return isActive
    }
}

// MARK: - 羁绊配置管理器
class BondConfigManager {
    static let shared = BondConfigManager()
    
    private var configFile: BondConfigFile?
    private let configFileName = "BondConfig"
    
    private init() {
        loadConfig()
    }
    
    /// 加载配置文件
    private func loadConfig() {
        guard let url = Bundle.main.url(forResource: configFileName, withExtension: "json") else {
            print("❌ [羁绊配置] 找不到配置文件: \(configFileName).json")
            return
        }
        
        do {
            let data = try Data(contentsOf: url)
            configFile = try JSONDecoder().decode(BondConfigFile.self, from: data)
            print("✅ [羁绊配置] 成功加载配置文件，共 \(configFile?.bonds.count ?? 0) 个羁绊")
        } catch {
            print("❌ [羁绊配置] 解析配置文件失败: \(error)")
        }
    }
    
    /// 获取所有羁绊
    func getAllBonds() -> [Bond] {
        guard let configFile = configFile else {
            return []
        }
        
        return configFile.bonds.map { config in
            Bond(
                id: config.id,
                nameKey: config.nameKey,
                descriptionKey: config.descriptionKey,
                requiredSymbolIds: config.requiredSymbolIds,
                backgroundColor: Color(hex: config.backgroundColor)
            )
        }
    }
    
    /// 根据ID获取羁绊
    func getBond(by id: String) -> Bond? {
        return getAllBonds().first { $0.id == id }
    }
    
    /// 获取当前激活的羁绊（基于符号池）
    func getActiveBonds(symbolPool: [Symbol]) -> [Bond] {
        let allBonds = getAllBonds()
        let activeBonds = allBonds.filter { $0.isActive(symbolPool: symbolPool) }
        return activeBonds
    }
    
    /// 重新加载配置（用于热更新）
    func reloadConfig() {
        print("🔄 [羁绊配置] 重新加载配置文件")
        loadConfig()
    }
}
