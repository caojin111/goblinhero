//
//  CloudSyncManager.swift
//  A004
//
//  云同步管理器 - 使用 iCloud Key-Value Storage 同步玩家数据
//

import Foundation
import Combine

class CloudSyncManager: ObservableObject {
    static let shared = CloudSyncManager()
    
    private let iCloudStore = NSUbiquitousKeyValueStore.default
    private var cancellables = Set<AnyCancellable>()
    
    // 数据键名
    private enum Keys {
        static let bestRound = "cloud_bestRound"
        static let bestSpinInRound = "cloud_bestSpinInRound"
        static let bestDifficulty = "cloud_bestDifficulty"
        static let bestCoins = "cloud_bestCoins"
        static let bestSingleGameCoins = "cloud_bestSingleGameCoins"
        static let playerName = "cloud_playerName"
        static let lastSyncTime = "cloud_lastSyncTime"
    }
    
    private init() {
        // 监听 iCloud 数据变化
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(iCloudStoreDidChange),
            name: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
            object: iCloudStore
        )
        
        // 同步到 iCloud
        iCloudStore.synchronize()
        
        // 检查 iCloud 是否可用
        if isICloudAvailable() {
            print("☁️ [云同步] 初始化完成，iCloud 可用")
        } else {
            print("⚠️ [云同步] 初始化完成，但 iCloud 不可用（用户可能未登录 iCloud）")
        }
    }
    
    // MARK: - 检查 iCloud 是否可用
    /// 检查用户是否登录了 iCloud（系统级别）
    /// 注意：这只能检查 iCloud 容器是否可用，不能直接检查用户是否登录
    /// 如果用户未登录 iCloud，数据只会保存在本地，不会同步
    func isICloudAvailable() -> Bool {
        // 尝试访问 iCloud 容器
        // 如果返回 nil，说明 iCloud 不可用
        if FileManager.default.ubiquityIdentityToken != nil {
            return true
        }
        return false
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - iCloud 数据变化通知
    @objc private func iCloudStoreDidChange(_ notification: Notification) {
        print("☁️ [云同步] 检测到 iCloud 数据变化")
        
        // 通知外部数据已更新
        NotificationCenter.default.post(name: .cloudDataDidChange, object: nil)
    }
    
    // MARK: - 保存最佳记录到 iCloud
    func saveBestRecords(bestRound: Int, bestSpinInRound: Int, bestDifficulty: String, bestCoins: Int, bestSingleGameCoins: Int) {
        // 即使 iCloud 不可用，也尝试保存（数据会缓存在本地，等 iCloud 可用时自动同步）
        iCloudStore.set(bestRound, forKey: Keys.bestRound)
        iCloudStore.set(bestSpinInRound, forKey: Keys.bestSpinInRound)
        iCloudStore.set(bestDifficulty, forKey: Keys.bestDifficulty)
        iCloudStore.set(bestCoins, forKey: Keys.bestCoins)
        iCloudStore.set(bestSingleGameCoins, forKey: Keys.bestSingleGameCoins)
        iCloudStore.set(Date(), forKey: Keys.lastSyncTime)
        
        let success = iCloudStore.synchronize()
        if success {
            if isICloudAvailable() {
                print("☁️ [云同步] 最佳记录已保存到 iCloud: \(bestRound)-\(bestSpinInRound) [\(bestDifficulty)], 金币: \(bestCoins), 单局: \(bestSingleGameCoins)")
            } else {
                print("☁️ [云同步] 最佳记录已缓存（等待 iCloud 可用时同步）: \(bestRound)-\(bestSpinInRound) [\(bestDifficulty)], 金币: \(bestCoins), 单局: \(bestSingleGameCoins)")
            }
        } else {
            print("⚠️ [云同步] 最佳记录保存失败（iCloud 可能不可用）")
        }
    }
    
    // MARK: - 从 iCloud 加载最佳记录
    func loadBestRecords() -> (bestRound: Int, bestSpinInRound: Int, bestDifficulty: String, bestCoins: Int, bestSingleGameCoins: Int)? {
        iCloudStore.synchronize()
        
        guard iCloudStore.object(forKey: Keys.bestRound) != nil else {
            print("☁️ [云同步] iCloud 中没有最佳记录")
            return nil
        }
        
        let bestRound = iCloudStore.longLong(forKey: Keys.bestRound)
        let bestSpinInRound = iCloudStore.longLong(forKey: Keys.bestSpinInRound)
        let bestDifficulty = iCloudStore.string(forKey: Keys.bestDifficulty) ?? ""
        let bestCoins = iCloudStore.longLong(forKey: Keys.bestCoins)
        let bestSingleGameCoins = iCloudStore.longLong(forKey: Keys.bestSingleGameCoins)
        
        print("☁️ [云同步] 从 iCloud 加载最佳记录: \(bestRound)-\(bestSpinInRound) [\(bestDifficulty)], 金币: \(bestCoins), 单局: \(bestSingleGameCoins)")
        
        return (
            bestRound: Int(bestRound),
            bestSpinInRound: Int(bestSpinInRound),
            bestDifficulty: bestDifficulty,
            bestCoins: Int(bestCoins),
            bestSingleGameCoins: Int(bestSingleGameCoins)
        )
    }
    
    // MARK: - 保存玩家名字到 iCloud
    func savePlayerName(_ name: String) {
        // 即使 iCloud 不可用，也尝试保存（数据会缓存在本地，等 iCloud 可用时自动同步）
        iCloudStore.set(name, forKey: Keys.playerName)
        iCloudStore.set(Date(), forKey: Keys.lastSyncTime)
        
        let success = iCloudStore.synchronize()
        if success {
            if isICloudAvailable() {
                print("☁️ [云同步] 玩家名字已保存到 iCloud: \(name)")
            } else {
                print("☁️ [云同步] 玩家名字已缓存（等待 iCloud 可用时同步）: \(name)")
            }
        } else {
            print("⚠️ [云同步] 玩家名字保存失败（iCloud 可能不可用）")
        }
    }
    
    // MARK: - 从 iCloud 加载玩家名字
    func loadPlayerName() -> String? {
        iCloudStore.synchronize()
        
        guard let name = iCloudStore.string(forKey: Keys.playerName), !name.isEmpty else {
            print("☁️ [云同步] iCloud 中没有玩家名字")
            return nil
        }
        
        print("☁️ [云同步] 从 iCloud 加载玩家名字: \(name)")
        return name
    }
    
    // MARK: - 合并本地和云端数据（取更好的记录）
    func mergeBestRecords(local: (bestRound: Int, bestSpinInRound: Int, bestDifficulty: String, bestCoins: Int, bestSingleGameCoins: Int),
                         cloud: (bestRound: Int, bestSpinInRound: Int, bestDifficulty: String, bestCoins: Int, bestSingleGameCoins: Int)) 
    -> (bestRound: Int, bestSpinInRound: Int, bestDifficulty: String, bestCoins: Int, bestSingleGameCoins: Int) {
        // 比较回合数
        var merged = local
        if cloud.bestRound > local.bestRound {
            merged = cloud
            print("☁️ [云同步] 使用云端的最佳回合: \(cloud.bestRound)-\(cloud.bestSpinInRound)")
        } else if cloud.bestRound == local.bestRound && cloud.bestSpinInRound > local.bestSpinInRound {
            merged = cloud
            print("☁️ [云同步] 使用云端的最佳转动次数: \(cloud.bestRound)-\(cloud.bestSpinInRound)")
        }
        
        // 比较金币
        if cloud.bestCoins > local.bestCoins {
            merged.bestCoins = cloud.bestCoins
            print("☁️ [云同步] 使用云端的历史最多金币: \(cloud.bestCoins)")
        }
        
        if cloud.bestSingleGameCoins > local.bestSingleGameCoins {
            merged.bestSingleGameCoins = cloud.bestSingleGameCoins
            print("☁️ [云同步] 使用云端的最佳单局金币: \(cloud.bestSingleGameCoins)")
        }
        
        return merged
    }
}

// MARK: - 通知名称
extension Notification.Name {
    static let cloudDataDidChange = Notification.Name("cloudDataDidChange")
}

