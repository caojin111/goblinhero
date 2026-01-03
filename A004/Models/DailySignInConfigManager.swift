//
//  DailySignInConfigManager.swift
//  A004
//
//  七日登录奖励配置管理器
//

import Foundation

class DailySignInConfigManager {
    static let shared = DailySignInConfigManager()
    
    private var rewards: [SignInReward] = []
    private var rawRewardsData: [[String: String]] = [] // 保存原始CSV数据，用于语言切换时重新生成描述
    
    private init() {
        loadConfig()
    }
    
    /// 加载配置文件（从CSV）
    private func loadConfig() {
        guard let url = Bundle.main.url(forResource: "DailySignInConfig", withExtension: "csv", subdirectory: "Config"),
              let csvContent = try? String(contentsOf: url, encoding: .utf8) else {
            print("⚠️ [签到配置] 无法加载CSV配置文件，使用默认配置")
            loadDefaultRewards()
            return
        }
        
        // 解析CSV
        let lines = csvContent.components(separatedBy: .newlines).filter { !$0.isEmpty }
        guard lines.count > 1 else {
            print("⚠️ [签到配置] CSV文件格式错误，使用默认配置")
            loadDefaultRewards()
            return
        }
        
        // 跳过表头
        let dataLines = Array(lines.dropFirst())
        
        // 解析每一行
        var parsedData: [[String: String]] = []
        for (index, line) in dataLines.enumerated() {
            let columns = parseCSVLine(line)
            guard columns.count >= 3 else {
                print("⚠️ [签到配置] 第\(index + 2)行数据格式错误，跳过")
                continue
            }
            
            let rowData: [String: String] = [
                "day": columns[0].trimmingCharacters(in: .whitespaces),
                "type": columns[1].trimmingCharacters(in: .whitespaces),
                "amount": columns[2].trimmingCharacters(in: .whitespaces)
            ]
            parsedData.append(rowData)
        }
        
        // 保存原始数据
        rawRewardsData = parsedData
        
        // 生成奖励列表
        updateRewardsFromRawData()
        
        print("✅ [签到配置] 成功从CSV加载 \(rewards.count) 个奖励配置")
    }
    
    /// 解析CSV行（处理逗号在引号内的情况）
    private func parseCSVLine(_ line: String) -> [String] {
        var result: [String] = []
        var currentField = ""
        var insideQuotes = false
        
        for char in line {
            if char == "\"" {
                insideQuotes.toggle()
            } else if char == "," && !insideQuotes {
                result.append(currentField)
                currentField = ""
            } else {
                currentField.append(char)
            }
        }
        result.append(currentField)
        
        return result
    }
    
    /// 从原始数据更新奖励列表（用于语言切换时重新生成描述）
    private func updateRewardsFromRawData() {
        let localizationManager = LocalizationManager.shared
        
        rewards = rawRewardsData.compactMap { rewardDict in
            guard let dayString = rewardDict["day"],
                  let day = Int(dayString),
                  let typeString = rewardDict["type"],
                  let amountString = rewardDict["amount"],
                  let amount = Int(amountString) else {
                return nil
            }
            
            // 解析奖励类型
            let type: SignInReward.RewardType
            switch typeString.lowercased() {
            case "diamonds":
                type = .diamonds
            case "stamina":
                type = .stamina
            default:
                print("⚠️ [签到配置] 未知的奖励类型: \(typeString)，仅支持 diamonds 和 stamina")
                return nil
            }
            
            // 从多语言表获取类型名称
            let typeKey: String
            switch type {
            case .diamonds:
                typeKey = "sign_in.reward_type.diamonds"
            case .stamina:
                typeKey = "sign_in.reward_type.stamina"
            case .coins:
                typeKey = "sign_in.reward_type.coins" // 保留以兼容旧代码
            }
            
            let typeName = localizationManager.localized(typeKey)
            
            // 生成描述：{amount} {type_localized}（去掉emoji）
            let description = "\(amount) \(typeName)"
            
            return SignInReward(day: day, type: type, amount: amount, description: description)
        }
        
        // 按天数排序
        rewards.sort { $0.day < $1.day }
    }
    
    /// 加载默认奖励（当配置文件加载失败时使用）
    private func loadDefaultRewards() {
        let localizationManager = LocalizationManager.shared
        let diamondsName = localizationManager.localized("sign_in.reward_type.diamonds")
        let staminaName = localizationManager.localized("sign_in.reward_type.stamina")
        
        rewards = [
            SignInReward(day: 1, type: .diamonds, amount: 30, description: "30 \(diamondsName)"),
            SignInReward(day: 2, type: .diamonds, amount: 40, description: "40 \(diamondsName)"),
            SignInReward(day: 3, type: .stamina, amount: 60, description: "60 \(staminaName)"),
            SignInReward(day: 4, type: .stamina, amount: 60, description: "60 \(staminaName)"),
            SignInReward(day: 5, type: .diamonds, amount: 30, description: "30 \(diamondsName)"),
            SignInReward(day: 6, type: .stamina, amount: 60, description: "60 \(staminaName)"),
            SignInReward(day: 7, type: .diamonds, amount: 100, description: "100 \(diamondsName)")
        ]
    }
    
    /// 获取指定天的奖励
    func getReward(for day: Int) -> SignInReward? {
        guard !rewards.isEmpty else {
            print("⚠️ [签到配置] 奖励列表为空，返回默认奖励")
            let localizationManager = LocalizationManager.shared
            let typeName = localizationManager.localized("sign_in.reward_type.diamonds")
            return SignInReward(day: day, type: .diamonds, amount: 10, description: "10 \(typeName)")
        }
        
        // 循环获取（7日循环）
        let index = (day - 1) % rewards.count
        return rewards[index]
    }
    
    /// 获取所有奖励（用于显示）
    func getAllRewards() -> [SignInReward] {
        guard !rewards.isEmpty else {
            let localizationManager = LocalizationManager.shared
            let typeName = localizationManager.localized("sign_in.reward_type.diamonds")
            return (1...7).map { day in
                SignInReward(day: day, type: .diamonds, amount: 10, description: "10 \(typeName)")
            }
        }
        
        return (1...7).compactMap { day in
            getReward(for: day)
        }
    }
    
    /// 重新加载配置（用于热更新）
    func reloadConfig() {
        loadConfig()
    }
    
    /// 更新语言（当语言切换时调用，重新生成描述）
    func updateLanguage() {
        guard !rawRewardsData.isEmpty else {
            return
        }
        updateRewardsFromRawData()
        print("✅ [签到配置] 已更新语言，重新生成奖励描述")
    }
}
