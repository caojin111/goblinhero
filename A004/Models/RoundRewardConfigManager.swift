//
//  RoundRewardConfigManager.swift
//  A004
//
//  关卡完成奖励配置管理器
//

import Foundation

class RoundRewardConfigManager {
    static let shared = RoundRewardConfigManager()
    
    private var roundRewards: [Int: Int] = [:] // [关卡: 钻石数量]
    
    private init() {
        loadConfig()
    }
    
    /// 加载配置文件（从CSV）
    private func loadConfig() {
        // 尝试从Config目录加载
        var url = Bundle.main.url(forResource: "RoundRewardConfig", withExtension: "csv", subdirectory: "Config")
        
        // 如果Config目录找不到，尝试从根目录加载
        if url == nil {
            url = Bundle.main.url(forResource: "RoundRewardConfig", withExtension: "csv")
        }
        
        guard let fileUrl = url,
              let csvContent = try? String(contentsOf: fileUrl, encoding: .utf8) else {
            print("⚠️ [关卡奖励配置] 无法加载CSV配置文件，使用默认配置")
            loadDefaultRewards()
            return
        }
        
        // 解析CSV
        let lines = csvContent.components(separatedBy: .newlines).filter { !$0.isEmpty }
        guard lines.count > 1 else {
            print("⚠️ [关卡奖励配置] CSV文件格式错误，使用默认配置")
            loadDefaultRewards()
            return
        }
        
        // 跳过表头
        let dataLines = Array(lines.dropFirst())
        
        // 解析每一行
        for (index, line) in dataLines.enumerated() {
            let columns = parseCSVLine(line)
            guard columns.count >= 2 else {
                print("⚠️ [关卡奖励配置] 第\(index + 2)行数据格式错误，跳过")
                continue
            }
            
            guard let round = Int(columns[0].trimmingCharacters(in: .whitespaces)),
                  let diamonds = Int(columns[1].trimmingCharacters(in: .whitespaces)) else {
                print("⚠️ [关卡奖励配置] 第\(index + 2)行数据格式错误，跳过")
                continue
            }
            
            roundRewards[round] = diamonds
        }
        
        print("✅ [关卡奖励配置] 成功从CSV加载 \(roundRewards.count) 个关卡奖励配置")
        // 打印所有奖励配置用于调试
        for round in 1...20 {
            if let diamonds = roundRewards[round] {
                print("💎 第\(round)关：\(diamonds)钻石")
            }
        }
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
    
    /// 加载默认奖励（当配置文件加载失败时使用）
    private func loadDefaultRewards() {
        // 关卡1-9：0钻石
        for round in 1...9 {
            roundRewards[round] = 0
        }
        // 关卡10-19：5钻石
        for round in 10...19 {
            roundRewards[round] = 5
        }
        // 关卡20：10钻石
        roundRewards[20] = 10
        print("⚠️ [关卡奖励配置] 使用默认奖励配置")
    }
    
    /// 获取指定关卡的钻石奖励
    func getDiamondsForRound(_ round: Int) -> Int {
        // 如果关卡超过20，使用第20关的奖励
        let rewardRound = min(round, 20)
        let diamonds = roundRewards[rewardRound] ?? 0
        print("💎 [关卡奖励] 第\(round)关奖励：\(diamonds)钻石")
        return diamonds
    }
}

