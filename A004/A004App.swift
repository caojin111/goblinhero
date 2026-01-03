//
//  A004App.swift
//  A004
//
//  Created by Allen on 2025/9/30.
//

import SwiftUI
import FirebaseCore

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        FirebaseApp.configure()
        print("🔥 [Firebase] Firebase 已初始化")
        
        // 在应用启动时立即检测设备型号，如果是 iPad 则自动标记所有教程为已完成
        let isPad = UIDevice.current.userInterfaceIdiom == .pad
        if isPad {
            print("📱 [AppDelegate] 检测到 iPad 设备，在应用启动时自动标记所有教程为已完成")
            UserDefaults.standard.set(true, forKey: "hasCompletedTutorial")
            UserDefaults.standard.set(true, forKey: "hasCompletedGameTutorial")
        }
        
        return true
    }
}

@main
struct A004App: App {
    // register app delegate for Firebase setup
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
