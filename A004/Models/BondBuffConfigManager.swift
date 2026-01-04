//
//  BondBuffConfigManager.swift
//  A004
//
//  羁绊Buff配置管理器（从CSV读取）
//

import Foundation
import SwiftUI

// MARK: - 羁绊Buff配置结构
struct BondBuffConfig {
    let id: String // 羁绊ID
    let nameKey: String // 名称键（用于多语言）
    let descriptionKey: String // 描述键（用于多语言）
    let requiredSymbolIds: [Int] // 需要的符号ID列表（当使用type计数时为空）
    let requiredType: String? // 需要统计的类型标签（BondMember 形如 type:xxx 时填入）
    let requiredCount: Int? // 需要的数量（用于type计数）
    let cardColor: String // 卡片颜色（十六进制）
}

// MARK: - 羁绊Buff模型
struct BondBuff: Identifiable, Equatable {
    let id: String
    let nameKey: String
    let descriptionKey: String
    let requiredSymbolIds: [Int]
    let requiredType: String?
    let requiredCount: Int?
    let cardColor: Color
    
    // 本地化名称
    var name: String {
        return LocalizationManager.shared.localized("bonds.\(nameKey).name")
    }
    
    // 本地化描述
    var description: String {
        return LocalizationManager.shared.localized("bonds.\(nameKey).description")
    }
    
    // 检查羁绊是否激活（基于符号池）
    func isActive(symbolPool: [Symbol]) -> Bool {
        // 若是类型计数羁绊
        if let typeTag = requiredType, let needCount = requiredCount {
            // 统计有多少个不同的符号（通过 nameKey 去重）
            let uniqueSymbols = Set(symbolPool.filter { $0.types.contains(typeTag) }.map { $0.nameKey })
            let count = uniqueSymbols.count
            let isActive = count >= needCount
            if isActive {
                print("✅ [羁绊Buff] 类型计数激活 '\(nameKey)'，类型: \(typeTag) 不同符号数量: \(count)/\(needCount)")
            } else {
                print("⚠️ [羁绊Buff] 类型计数未激活 '\(nameKey)'，类型: \(typeTag) 不同符号数量: \(count)/\(needCount)")
            }
            return isActive
        }
        // 传统固定ID羁绊
        let symbolConfigIds = symbolPool.compactMap { symbol -> Int? in
            return SymbolConfigManager.shared.getSymbolConfigId(byNameKey: symbol.nameKey)
        }
        let symbolIdsSet = Set(symbolConfigIds)
        let requiredIdsSet = Set(requiredSymbolIds)
        let isActive = requiredIdsSet.isSubset(of: symbolIdsSet)
        if isActive {
            print("✅ [羁绊Buff] 羁绊 '\(nameKey)' 已激活！需要的符号ID: \(requiredSymbolIds)，当前符号池ID: \(symbolConfigIds)")
        }
        return isActive
    }
}

// MARK: - 羁绊Buff配置管理器
class BondBuffConfigManager {
    static let shared = BondBuffConfigManager()
    
    private var bondBuffs: [BondBuffConfig] = []
    private let configFileName = "bond_buff"
    
    private init() {
        loadConfig()
    }
    
    /// 加载配置文件
    private func loadConfig() {
        guard let rows = CSVReader.readCSV(fileName: configFileName) else {
            print("❌ [羁绊Buff配置] 无法读取CSV文件")
            return
        }
        
        bondBuffs = rows.compactMap { row -> BondBuffConfig? in
            guard let id = row["ID"],
                  let nameKeyRaw = row["NameKey"],
                  let descriptionKeyRaw = row["DesKey"],
                  let bondMember = row["BondMember"],
                  let cardColorRaw = row["CardColor"] else {
                print("⚠️ [羁绊Buff配置] 行数据不完整，跳过: \(row)")
                return nil
            }
            
            // 提取nameKey：从 "bonds.merchant_trading_bond.name" 提取 "merchant_trading_bond"
            let nameKey: String
            if nameKeyRaw.contains(".") {
                let parts = nameKeyRaw.split(separator: ".")
                if parts.count >= 2 {
                    nameKey = String(parts[parts.count - 2]) // 取倒数第二部分
                } else {
                    nameKey = nameKeyRaw
                }
            } else {
                nameKey = nameKeyRaw
            }
            
            // 提取descriptionKey：从 "bonds.merchant_trading_bond.description" 提取 "merchant_trading_bond"
            let descriptionKey: String
            if descriptionKeyRaw.contains(".") {
                let parts = descriptionKeyRaw.split(separator: ".")
                if parts.count >= 2 {
                    descriptionKey = String(parts[parts.count - 2]) // 取倒数第二部分
                } else {
                    descriptionKey = descriptionKeyRaw
                }
            } else {
                descriptionKey = descriptionKeyRaw
            }
            
            // 解析BondMember：支持固定ID列表和 type: 标签计数
            var requiredIds: [Int] = []
            var requiredType: String? = nil
            var requiredCount: Int? = nil
            if bondMember.lowercased().hasPrefix("type:") {
                // 形如 "type:human" 或 "type:cozy life"
                let raw = bondMember.dropFirst(5)
                requiredType = raw.trimmingCharacters(in: .whitespaces)
                if let rc = row["requiredCount"], let c = Int(rc) {
                    requiredCount = c
                }
            } else {
                // 固定ID列表：分号或逗号
                if bondMember.contains(";") {
                    requiredIds = bondMember.split(separator: ";")
                        .compactMap { Int($0.trimmingCharacters(in: .whitespaces)) }
                } else if bondMember.contains(",") {
                    // 包含逗号，使用parseIDList
                    requiredIds = CSVReader.parseIDList(bondMember)
                } else {
                    // 单个数字，直接解析
                    if let singleId = Int(bondMember.trimmingCharacters(in: .whitespaces)) {
                        requiredIds = [singleId]
                    } else {
                        requiredIds = []
                    }
                }
            }
            
            // 处理CardColor（添加#前缀如果缺失）
            let cardColor = cardColorRaw.hasPrefix("#") ? cardColorRaw : "#\(cardColorRaw)"
            
            print("🔍 [羁绊Buff配置] ID: \(id), nameKey: \(nameKey), descriptionKey: \(descriptionKey), requiredIds: \(requiredIds), requiredType: \(requiredType ?? "nil"), requiredCount: \(requiredCount ?? 0), cardColor: \(cardColor)")
            
            return BondBuffConfig(
                id: id,
                nameKey: nameKey,
                descriptionKey: descriptionKey,
                requiredSymbolIds: requiredIds,
                requiredType: requiredType,
                requiredCount: requiredCount,
                cardColor: cardColor
            )
        }
        
        print("✅ [羁绊Buff配置] 成功加载配置文件，共 \(bondBuffs.count) 个羁绊Buff")
    }
    
    /// 获取所有羁绊Buff
    func getAllBondBuffs() -> [BondBuff] {
        return bondBuffs.map { config in
            let color = Color(hex: config.cardColor)
            print("🎨 [羁绊Buff颜色] \(config.nameKey): \(config.cardColor) -> Color对象已创建")
            return BondBuff(
                id: config.id,
                nameKey: config.nameKey,
                descriptionKey: config.descriptionKey,
                requiredSymbolIds: config.requiredSymbolIds,
                requiredType: config.requiredType,
                requiredCount: config.requiredCount,
                cardColor: color
            )
        }
    }
    
    /// 根据ID获取羁绊Buff
    func getBondBuff(by id: String) -> BondBuff? {
        return getAllBondBuffs().first { $0.id == id }
    }
    
    /// 根据nameKey获取羁绊Buff
    func getBondBuff(byNameKey nameKey: String) -> BondBuff? {
        return getAllBondBuffs().first { $0.nameKey == nameKey }
    }
    
    /// 获取当前激活的羁绊Buff（基于符号池）
    func getActiveBondBuffs(symbolPool: [Symbol]) -> [BondBuff] {
        let allBondBuffs = getAllBondBuffs()
        let activeBondBuffs = allBondBuffs.filter { $0.isActive(symbolPool: symbolPool) }
        print("🔗 [羁绊Buff系统] 检查 \(allBondBuffs.count) 个羁绊Buff，当前激活 \(activeBondBuffs.count) 个")
        return activeBondBuffs
    }
    
    /// 重新加载配置（用于热更新）
    func reloadConfig() {
        print("🔄 [羁绊Buff配置] 重新加载配置文件")
        loadConfig()
    }
}
