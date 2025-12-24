//
//  GameCenterManager.swift
//  A004
//
//  Game Center 排行榜管理器
//

import Foundation
import GameKit
import UIKit

class GameCenterManager: NSObject, ObservableObject {
    static let shared = GameCenterManager()
    
    // 排行榜ID
    private let leaderboardID = "Coin_rank"
    
    // 是否已认证
    @Published var isAuthenticated: Bool = false
    
    private override init() {
        super.init()
        authenticatePlayer()
    }
    
    /// 认证玩家
    func authenticatePlayer() {
        let localPlayer = GKLocalPlayer.local
        
        localPlayer.authenticateHandler = { [weak self] viewController, error in
            if let viewController = viewController {
                // 需要显示认证界面
                print("🎮 [Game Center] 需要显示认证界面")
                // 获取当前窗口的根视图控制器并显示认证界面
                DispatchQueue.main.async {
                    if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                       let rootViewController = windowScene.windows.first?.rootViewController {
                        rootViewController.present(viewController, animated: true)
                    } else {
                        print("⚠️ [Game Center] 无法获取根视图控制器来显示认证界面")
                    }
                }
                return
            }
            
            if let error = error {
                print("❌ [Game Center] 认证失败: \(error.localizedDescription)")
                self?.isAuthenticated = false
                return
            }
            
            if localPlayer.isAuthenticated {
                print("✅ [Game Center] 玩家已认证: \(localPlayer.displayName ?? "Unknown")")
                self?.isAuthenticated = true
            } else {
                print("⚠️ [Game Center] 玩家未认证")
                self?.isAuthenticated = false
            }
        }
    }
    
    /// 提交分数到排行榜
    /// - Parameter score: 单局最高金币数
    func submitScore(_ score: Int64) {
        guard isAuthenticated else {
            print("⚠️ [Game Center] 玩家未认证，无法提交分数")
            authenticatePlayer()
            return
        }
        
        let scoreReporter = GKScore(leaderboardIdentifier: leaderboardID)
        scoreReporter.value = score
        
        GKScore.report([scoreReporter]) { [weak self] error in
            if let error = error {
                print("❌ [Game Center] 提交分数失败: \(error.localizedDescription)")
            } else {
                print("✅ [Game Center] 成功提交分数: \(score) 到排行榜 \(self?.leaderboardID ?? "unknown")")
            }
        }
    }
    
    /// 显示排行榜界面
    /// 注意：这个方法需要在UIViewController的上下文中调用
    /// 在SwiftUI中，可以通过UIViewControllerRepresentable来包装
    func showLeaderboard(from viewController: UIViewController) {
        guard isAuthenticated else {
            print("⚠️ [Game Center] 玩家未认证，无法显示排行榜")
            authenticatePlayer()
            return
        }
        
        let gameCenterViewController = GKGameCenterViewController(leaderboardID: leaderboardID, playerScope: .global, timeScope: .allTime)
        gameCenterViewController.gameCenterDelegate = self
        viewController.present(gameCenterViewController, animated: true)
    }
    
    /// 显示成就界面
    func showAchievements(from viewController: UIViewController) {
        guard isAuthenticated else {
            print("⚠️ [Game Center] 玩家未认证，无法显示成就")
            authenticatePlayer()
            return
        }
        
        let gameCenterViewController = GKGameCenterViewController(state: .achievements)
        gameCenterViewController.gameCenterDelegate = self
        viewController.present(gameCenterViewController, animated: true)
    }
    
    /// 完成成就
    /// - Parameter achievementID: 成就ID
    func unlockAchievement(_ achievementID: String) {
        guard isAuthenticated else {
            print("⚠️ [Game Center] 玩家未认证，无法解锁成就")
            authenticatePlayer()
            return
        }
        
        // 检查是否已经完成过这个成就
        let hasCompleted = UserDefaults.standard.bool(forKey: "achievement_\(achievementID)")
        if hasCompleted {
            print("✅ [Game Center] 成就 \(achievementID) 已经完成过，跳过")
            return
        }
        
        GKAchievement.loadAchievements { achievements, error in
            if let error = error {
                print("❌ [Game Center] 加载成就失败: \(error.localizedDescription)")
                return
            }
            
            // 检查成就是否已经存在
            let existingAchievement = achievements?.first { $0.identifier == achievementID }
            if let existing = existingAchievement, existing.isCompleted {
                print("✅ [Game Center] 成就 \(achievementID) 已经完成")
                UserDefaults.standard.set(true, forKey: "achievement_\(achievementID)")
                return
            }
            
            // 创建或更新成就
            let achievement = GKAchievement(identifier: achievementID)
            achievement.percentComplete = 100.0
            achievement.showsCompletionBanner = true
            
            GKAchievement.report([achievement]) { error in
                if let error = error {
                    print("❌ [Game Center] 解锁成就失败: \(error.localizedDescription)")
                } else {
                    print("✅ [Game Center] 成功解锁成就: \(achievementID)")
                    UserDefaults.standard.set(true, forKey: "achievement_\(achievementID)")
                }
            }
        }
    }
}

// MARK: - GKGameCenterControllerDelegate
extension GameCenterManager: GKGameCenterControllerDelegate {
    func gameCenterViewControllerDidFinish(_ gameCenterViewController: GKGameCenterViewController) {
        gameCenterViewController.dismiss(animated: true)
        print("🎮 [Game Center] 排行榜界面已关闭")
    }
}
