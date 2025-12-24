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
    private var rawRewardsData: [[String: Any]] = [] // 保存原始数据，用于语言切换时重新生成描述
    
    private init() {
        loadConfig()
    }
    
    /// 加载配置文件
    private func loadConfig() {
        guard let url = Bundle.main.url(forResource: "DailySignInConfig", withExtension: "json", subdirectory: "Config"),
              let data = try? Data(contentsOf: url),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let rewardsArray = json["rewards"] as? [[String: Any]] else {
            print("⚠️ [签到配置] 无法加载配置文件，使用默认配置")
            loadDefaultRewards()
            return
        }
        
        // 保存原始数据
        rawRewardsData = rewardsArray
        
        // 生成奖励列表
        updateRewardsFromRawData()
        
        print("✅ [签到配置] 成功加载 \(rewards.count) 个奖励配置")
    }
    
    /// 从原始数据更新奖励列表（用于语言切换时重新生成描述）
    private func updateRewardsFromRawData() {
        rewards = rawRewardsData.compactMap { rewardDict in
            guard let day = rewardDict["day"] as? Int,
                  let typeString = rewardDict["type"] as? String,
                  let amount = rewardDict["amount"] as? Int,
                  let descriptionDict = rewardDict["description"] as? [String: String] else {
                return nil
            }
            
            // 解析奖励类型
            let type: SignInReward.RewardType
            switch typeString.lowercased() {
            case "diamonds":
                type = .diamonds
            case "coins":
                type = .coins
            case "stamina":
                type = .stamina
            default:
                print("⚠️ [签到配置] 未知的奖励类型: \(typeString)")
                return nil
            }
            
            // 获取当前语言的描述
            let currentLanguage = LocalizationManager.shared.currentLanguage
            let description = descriptionDict[currentLanguage] ?? descriptionDict["en"] ?? descriptionDict["zh"] ?? ""
            
            return SignInReward(day: day, type: type, amount: amount, description: description)
        }
        
        // 按天数排序
        rewards.sort { $0.day < $1.day }
    }
    
    /// 加载默认奖励（当配置文件加载失败时使用）
    private func loadDefaultRewards() {
        rewards = [
            SignInReward(day: 1, type: .diamonds, amount: 10, description: "10 💎"),
            SignInReward(day: 2, type: .coins, amount: 50, description: "50 💰"),
            SignInReward(day: 3, type: .diamonds, amount: 20, description: "20 💎"),
            SignInReward(day: 4, type: .stamina, amount: 30, description: "30 ⚡"),
            SignInReward(day: 5, type: .diamonds, amount: 30, description: "30 💎"),
            SignInReward(day: 6, type: .coins, amount: 100, description: "100 💰"),
            SignInReward(day: 7, type: .diamonds, amount: 50, description: "50 💎")
        ]
    }
    
    /// 获取指定天的奖励
    func getReward(for day: Int) -> SignInReward? {
        guard !rewards.isEmpty else {
            print("⚠️ [签到配置] 奖励列表为空，返回默认奖励")
            return SignInReward(day: day, type: .diamonds, amount: 10, description: "10 💎")
        }
        
        // 循环获取（7日循环）
        let index = (day - 1) % rewards.count
        return rewards[index]
    }
    
    /// 获取所有奖励（用于显示）
    func getAllRewards() -> [SignInReward] {
        guard !rewards.isEmpty else {
            return (1...7).map { day in
                SignInReward(day: day, type: .diamonds, amount: 10, description: "10 💎")
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
